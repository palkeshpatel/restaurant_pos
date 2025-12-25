<?php

namespace App\Http\Controllers\Api\Pos;

use App\Http\Controllers\Controller;
use App\Models\Check;
use App\Models\Order;
use App\Models\Payment;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Stripe\Stripe;
use Stripe\PaymentIntent;
use Stripe\PaymentMethod;
use Stripe\Refund;
use Stripe\Terminal\ConnectionToken;
use Stripe\Exception\ApiErrorException;

class StripePaymentController extends Controller
{
    use ApiResponse;

    public function __construct()
    {
        // Initialize Stripe with secret key from config
        Stripe::setApiKey(config('services.stripe.secret'));
    }

    /**
     * Create Payment Intent for card_present tap payment
     *
     * This endpoint creates a Stripe Payment Intent with card_present
     * for tap/insert/swipe payments at POS terminals.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function createPaymentIntent(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'amount' => 'required|numeric|min:0.50',
            'tip_amount' => 'nullable|numeric|min:0',
            'currency' => 'nullable|string|size:3',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        if ($order->status === 'completed') {
            return $this->errorResponse('Order is already paid', 400);
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        try {
            $totalAmount = $validated['amount'] + ($validated['tip_amount'] ?? 0);
            $currency = strtolower($validated['currency'] ?? 'usd');
            $amountInCents = (int) round($totalAmount * 100);

            Log::info('Creating Payment Intent with card_present', [
                'order_ticket_id' => $validated['order_ticket_id'],
                'amount' => $totalAmount,
                'currency' => $currency,
            ]);

            $paymentIntent = PaymentIntent::create([
                'amount' => $amountInCents,
                'currency' => $currency,
                'payment_method_types' => ['card_present'],
                'capture_method' => 'automatic',
                'metadata' => [
                    'order_ticket_id' => $validated['order_ticket_id'],
                    'order_id' => $order->id,
                    'check_id' => $check->id,
                    'business_id' => $businessId,
                    'employee_id' => $employee->id,
                    'tip_amount' => $validated['tip_amount'] ?? 0,
                ],
                'description' => "Payment for Order #{$validated['order_ticket_id']}",
            ]);

            Log::info('Payment Intent created successfully', [
                'payment_intent_id' => $paymentIntent->id,
            ]);

            return $this->successResponse([
                'client_secret' => $paymentIntent->client_secret,
                'payment_intent_id' => $paymentIntent->id,
                'amount' => $totalAmount,
                'currency' => $currency,
                'payment_method_types' => ['card_present'],
                'order' => $order,
                'check' => $check,
            ], 'Payment intent created successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Payment Intent Error', [
                'message' => $e->getMessage(),
                'code' => $e->getStripeCode(),
                'currency' => $currency,
            ]);

            // Handle currency not supported error
            if ($e->getStripeCode() === 'card_present_currency_not_supported') {
                $errorMessage = "card_present is not supported for currency '{$currency}' with your Stripe account. ";
                $errorMessage .= "For US accounts, only USD is supported. Please use 'usd' as currency.";
                return $this->errorResponse($errorMessage, 400);
            }

            return $this->errorResponse('Failed to create payment intent: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Payment Intent Creation Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while creating payment intent', 500);
        }
    }

    /**
     * Confirm Payment after card tap
     *
     * This endpoint verifies the payment with Stripe and updates the database.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function confirmPayment(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'payment_intent_id' => 'required|string',
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        if ($order->status === 'completed') {
            return $this->errorResponse('Order is already paid', 400);
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        try {
            $paymentIntent = PaymentIntent::retrieve($validated['payment_intent_id']);

            if ($paymentIntent->status !== 'succeeded') {
                return $this->errorResponse(
                    "Payment not completed. Status: {$paymentIntent->status}",
                    400
                );
            }

            if ($paymentIntent->metadata->order_id != $order->id) {
                return $this->errorResponse('Payment intent does not match order', 400);
            }

            $tipAmount = isset($paymentIntent->metadata->tip_amount)
                ? (float) $paymentIntent->metadata->tip_amount
                : 0;

            $baseAmount = ($paymentIntent->amount / 100) - $tipAmount;

            $payment = Payment::create([
                'check_id' => $check->id,
                'employee_id' => $order->created_by_employee_id,
                'method' => 'card',
                'amount' => $baseAmount,
                'tip_amount' => $tipAmount,
                'payment_date' => now(),
            ]);

            $check->update([
                'status' => 'paid',
                'type' => 'online',
            ]);

            $order->update(['status' => 'completed']);

            if ($order->table) {
                $order->table->update(['status' => 'available']);
            }

            return $this->successResponse([
                'payment' => $payment->load(['check', 'employee']),
                'order' => $order->load(['table']),
                'check' => $check,
                'stripe_payment_intent_id' => $paymentIntent->id,
                'stripe_status' => $paymentIntent->status,
            ], 'Payment confirmed and processed successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Payment Confirmation Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('Failed to confirm payment: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Payment Confirmation Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while confirming payment', 500);
        }
    }

    /**
     * Check Payment Status
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function checkPaymentStatus(Request $request)
    {
        $validated = $request->validate([
            'payment_intent_id' => 'required|string',
        ]);

        try {
            $paymentIntent = PaymentIntent::retrieve($validated['payment_intent_id']);

            return $this->successResponse([
                'payment_intent_id' => $paymentIntent->id,
                'status' => $paymentIntent->status,
                'amount' => $paymentIntent->amount / 100,
                'currency' => $paymentIntent->currency,
                'created' => date('Y-m-d H:i:s', $paymentIntent->created),
                'metadata' => $paymentIntent->metadata->toArray(),
            ], 'Payment status retrieved successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Payment Status Check Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('Failed to check payment status: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Payment Status Check Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while checking payment status', 500);
        }
    }

    /**
     * DEMO: Create Payment Intent with card_present (No Authentication Required)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function demoCreatePaymentIntent(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:0.50',
            'currency' => 'nullable|string|size:3',
            'description' => 'nullable|string|max:255',
        ]);

        try {
            $amount = $validated['amount'];
            $currency = strtolower($validated['currency'] ?? 'usd');
            $description = $validated['description'] ?? 'Demo Payment';
            $amountInCents = (int) round($amount * 100);

            Log::info('Creating Demo Payment Intent with card_present', [
                'amount' => $amount,
                'currency' => $currency,
            ]);

            $paymentIntent = PaymentIntent::create([
                'amount' => $amountInCents,
                'currency' => $currency,
                'payment_method_types' => ['card_present'],
                'capture_method' => 'automatic',
                'metadata' => [
                    'demo' => 'true',
                    'description' => $description,
                ],
                'description' => $description,
            ]);

            Log::info('Demo Payment Intent created successfully', [
                'payment_intent_id' => $paymentIntent->id,
            ]);

            return $this->successResponse([
                'client_secret' => $paymentIntent->client_secret,
                'payment_intent_id' => $paymentIntent->id,
                'amount' => $amount,
                'currency' => $currency,
                'status' => $paymentIntent->status,
                'payment_method_types' => ['card_present'],
                'description' => $description,
            ], 'Demo payment intent created successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Demo Payment Intent Error', [
                'message' => $e->getMessage(),
                'code' => $e->getStripeCode(),
                'currency' => $currency,
            ]);

            // Handle currency not supported error
            if ($e->getStripeCode() === 'card_present_currency_not_supported') {
                $errorMessage = "card_present is not supported for currency '{$currency}' with your Stripe account. ";
                $errorMessage .= "For US accounts, only USD is supported. Please use 'usd' as currency.";
                return $this->errorResponse($errorMessage, 400);
            }

            return $this->errorResponse('Failed to create payment intent: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Demo Payment Intent Creation Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while creating payment intent', 500);
        }
    }

    /**
     * DEMO: Check Payment Status (No Authentication Required)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function demoCheckPaymentStatus(Request $request)
    {
        $validated = $request->validate([
            'payment_intent_id' => 'required|string',
        ]);

        try {
            $paymentIntent = PaymentIntent::retrieve($validated['payment_intent_id']);

            return $this->successResponse([
                'payment_intent_id' => $paymentIntent->id,
                'status' => $paymentIntent->status,
                'amount' => $paymentIntent->amount / 100,
                'currency' => $paymentIntent->currency,
                'created' => date('Y-m-d H:i:s', $paymentIntent->created),
                'description' => $paymentIntent->description,
                'metadata' => $paymentIntent->metadata->toArray(),
            ], 'Demo payment status retrieved successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Demo Payment Status Check Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('Failed to check payment status: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Demo Payment Status Check Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while checking payment status', 500);
        }
    }

    /**
     * DEMO: Test Payment with Card Number (No Authentication Required)
     *
     * Simulates tap payment with test card. Complete payment cycle for testing.
     * Uses Stripe test payment method tokens to avoid raw card data restrictions.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function demoTestPayment(Request $request)
    {
        $validated = $request->validate([
            'payment_intent_id' => 'required|string',
            'payment_method_id' => 'nullable|string',
            'card_number' => 'nullable|string',
            'exp_month' => 'nullable|integer|min:1|max:12',
            'exp_year' => 'nullable|integer|min:' . date('Y'),
            'cvc' => 'nullable|string|size:3',
        ]);

        try {
            Log::info('Demo Test Payment - Processing payment', [
                'payment_intent_id' => $validated['payment_intent_id'],
            ]);

            // Retrieve the payment intent
            $paymentIntent = PaymentIntent::retrieve($validated['payment_intent_id']);

            if ($paymentIntent->status === 'succeeded') {
                return $this->errorResponse('Payment already succeeded', 400);
            }

            $paymentMethod = null;

            // Option 1: Use provided payment_method_id (Stripe test token)
            if (isset($validated['payment_method_id']) && !empty($validated['payment_method_id'])) {
                $paymentMethodId = $validated['payment_method_id'];
                Log::info('Demo Test Payment - Using provided payment method ID', [
                    'payment_method_id' => $paymentMethodId,
                ]);

                // Verify the payment method exists
                try {
                    $paymentMethod = PaymentMethod::retrieve($paymentMethodId);
                } catch (\Exception $e) {
                    // If payment method doesn't exist, create a new one using test token
                    Log::info('Demo Test Payment - Payment method not found, creating from test token');
                    $paymentMethod = PaymentMethod::create([
                        'type' => 'card',
                        'card' => [
                            'token' => $paymentMethodId, // Try as token first
                        ],
                    ]);
                }
            }
            // Option 2: Use card details (if raw card data API is enabled)
            elseif (isset($validated['card_number']) && !empty($validated['card_number'])) {
                Log::info('Demo Test Payment - Creating payment method with card details', [
                    'card_last4' => substr(str_replace(' ', '', $validated['card_number']), -4),
                ]);

                try {
                    $paymentMethod = PaymentMethod::create([
                        'type' => 'card',
                        'card' => [
                            'number' => str_replace(' ', '', $validated['card_number']),
                            'exp_month' => $validated['exp_month'],
                            'exp_year' => $validated['exp_year'],
                            'cvc' => $validated['cvc'],
                        ],
                    ]);
                } catch (ApiErrorException $e) {
                    // If raw card data is not enabled, suggest using test tokens
                    return $this->errorResponse(
                        'Raw card data API is not enabled. Please use Stripe test payment method tokens instead. ' .
                            'Use payment_method_id parameter with values like: pm_card_visa, pm_card_mastercard, pm_card_amex, etc. ' .
                            'See: https://stripe.com/docs/testing#cards',
                        400
                    );
                }
            }
            // Option 3: Use default test payment method (pm_card_visa)
            else {
                Log::info('Demo Test Payment - Using default test payment method (pm_card_visa)');
                try {
                    $paymentMethod = PaymentMethod::retrieve('pm_card_visa');
                } catch (\Exception $e) {
                    // Create a new payment method using test token
                    $paymentMethod = PaymentMethod::create([
                        'type' => 'card',
                        'card' => [
                            'token' => 'tok_visa', // Stripe test token
                        ],
                    ]);
                }
            }

            if (!$paymentMethod) {
                return $this->errorResponse('Failed to create or retrieve payment method', 500);
            }

            Log::info('Demo Test Payment - Payment method ready', [
                'payment_method_id' => $paymentMethod->id,
            ]);

            // Check if payment intent has card_present type - we need 'card' type for testing
            $paymentMethodTypes = $paymentIntent->payment_method_types;
            if (in_array('card_present', $paymentMethodTypes) && !in_array('card', $paymentMethodTypes)) {
                // Can't change payment_method_types after creation, so create a new one with 'card' type
                Log::info('Demo Test Payment - Creating new payment intent with card type', [
                    'original_payment_intent_id' => $paymentIntent->id,
                ]);

                $paymentIntent = PaymentIntent::create([
                    'amount' => $paymentIntent->amount,
                    'currency' => $paymentIntent->currency,
                    'payment_method_types' => ['card'],
                    'payment_method' => $paymentMethod->id,
                    'capture_method' => 'automatic',
                    'metadata' => array_merge($paymentIntent->metadata->toArray(), [
                        'original_payment_intent_id' => $paymentIntent->id,
                        'test_mode' => 'true',
                    ]),
                    'description' => $paymentIntent->description ?? 'Demo Test Payment',
                ]);

                // Confirm immediately since we're providing payment_method
                $paymentIntent = $paymentIntent->confirm();
            } else {
                // Update payment intent with payment method
                $paymentIntent = PaymentIntent::update($paymentIntent->id, [
                    'payment_method' => $paymentMethod->id,
                ]);

                // Confirm the payment
                $paymentIntent = $paymentIntent->confirm();
            }

            Log::info('Demo Test Payment - Payment confirmed', [
                'payment_intent_id' => $paymentIntent->id,
                'status' => $paymentIntent->status,
            ]);

            // Reload payment intent to get charges
            $paymentIntent = PaymentIntent::retrieve($paymentIntent->id, [
                'expand' => ['charges'],
            ]);

            // Retrieve charges safely
            $charges = [];
            if (isset($paymentIntent->charges) && $paymentIntent->charges && isset($paymentIntent->charges->data)) {
                $charges = $paymentIntent->charges->data;
            }

            return $this->successResponse([
                'payment_intent_id' => $paymentIntent->id,
                'payment_intent_status' => $paymentIntent->status,
                'payment_method_id' => $paymentMethod->id,
                'amount' => $paymentIntent->amount / 100,
                'currency' => $paymentIntent->currency,
                'description' => $paymentIntent->description ?? null,
                'metadata' => isset($paymentIntent->metadata) ? $paymentIntent->metadata->toArray() : [],
                'charges' => $charges,
                'message' => $paymentIntent->status === 'succeeded'
                    ? 'Payment processed successfully!'
                    : 'Payment status: ' . $paymentIntent->status,
            ], 'Test payment processed successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Demo Test Payment Error', [
                'message' => $e->getMessage(),
                'code' => $e->getStripeCode(),
            ]);

            return $this->errorResponse('Failed to process test payment: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Demo Test Payment Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while processing test payment', 500);
        }
    }

    /**
     * DEMO: Refund Payment (No Authentication Required)
     *
     * Refund a successful payment for testing purposes.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function demoRefundPayment(Request $request)
    {
        $validated = $request->validate([
            'payment_intent_id' => 'required|string',
            'amount' => 'nullable|numeric|min:0.01',
            'reason' => 'nullable|string|in:duplicate,fraudulent,requested_by_customer',
        ]);

        try {
            Log::info('Demo Refund Payment - Processing refund', [
                'payment_intent_id' => $validated['payment_intent_id'],
                'amount' => $validated['amount'] ?? null,
            ]);

            // Retrieve the payment intent with expanded charges
            $paymentIntent = PaymentIntent::retrieve($validated['payment_intent_id'], [
                'expand' => ['charges.data'],
            ]);

            Log::info('Demo Refund Payment - Payment intent retrieved', [
                'payment_intent_id' => $paymentIntent->id,
                'status' => $paymentIntent->status,
                'has_charges' => isset($paymentIntent->charges),
            ]);

            if ($paymentIntent->status !== 'succeeded') {
                Log::warning('Demo Refund Payment - Payment not succeeded', [
                    'status' => $paymentIntent->status,
                ]);
                return $this->errorResponse('Payment must be succeeded to refund. Current status: ' . $paymentIntent->status, 400);
            }

            // Check if already refunded
            if ($paymentIntent->status === 'canceled' || (isset($paymentIntent->charges) && !empty($paymentIntent->charges->data))) {
                $charges = $paymentIntent->charges->data ?? [];
                foreach ($charges as $charge) {
                    if (isset($charge->refunded) && $charge->refunded) {
                        Log::warning('Demo Refund Payment - Payment already refunded', [
                            'payment_intent_id' => $paymentIntent->id,
                            'charge_id' => $charge->id,
                        ]);
                        return $this->errorResponse('This payment has already been refunded', 400);
                    }
                }
            }

            Log::info('Demo Refund Payment - Creating refund with payment_intent', [
                'payment_intent_id' => $paymentIntent->id,
                'amount' => $validated['amount'] ?? null,
                'reason' => $validated['reason'] ?? 'requested_by_customer',
            ]);

            // Create refund using payment_intent (Stripe will handle charge lookup automatically)
            $refundData = [
                'payment_intent' => $paymentIntent->id,
                'reason' => $validated['reason'] ?? 'requested_by_customer',
            ];

            // If partial refund amount is specified
            if (isset($validated['amount']) && $validated['amount'] > 0) {
                $refundData['amount'] = (int) round($validated['amount'] * 100);
                Log::info('Demo Refund Payment - Partial refund', [
                    'amount_cents' => $refundData['amount'],
                    'amount_dollars' => $validated['amount'],
                ]);
            } else {
                Log::info('Demo Refund Payment - Full refund');
            }

            $refund = Refund::create($refundData);

            Log::info('Demo Refund Payment - Refund created successfully', [
                'refund_id' => $refund->id,
                'amount' => $refund->amount / 100,
                'status' => $refund->status,
                'reason' => $refund->reason,
            ]);

            // Get charge ID from refund if available
            $chargeId = null;
            if (isset($refund->charge) && $refund->charge) {
                $chargeId = is_object($refund->charge) ? $refund->charge->id : $refund->charge;
            } elseif (isset($paymentIntent->charges) && !empty($paymentIntent->charges->data)) {
                $chargeId = $paymentIntent->charges->data[0]->id ?? null;
            }

            return $this->successResponse([
                'refund_id' => $refund->id,
                'refund_status' => $refund->status,
                'amount' => $refund->amount / 100,
                'currency' => $refund->currency,
                'payment_intent_id' => $paymentIntent->id,
                'charge_id' => $chargeId,
                'reason' => $refund->reason ?? null,
                'created' => date('Y-m-d H:i:s', $refund->created),
                'message' => $refund->status === 'succeeded'
                    ? 'Refund processed successfully!'
                    : 'Refund status: ' . $refund->status,
            ], 'Refund processed successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Demo Refund Error', [
                'message' => $e->getMessage(),
                'code' => $e->getStripeCode(),
                'payment_intent_id' => $validated['payment_intent_id'] ?? null,
            ]);

            return $this->errorResponse('Failed to process refund: ' . $e->getMessage() . ' (Code: ' . $e->getStripeCode() . ')', 500);
        } catch (\Exception $e) {
            Log::error('Demo Refund Error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'payment_intent_id' => $validated['payment_intent_id'] ?? null,
            ]);
            return $this->errorResponse('An error occurred while processing refund: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Create Connection Token for Stripe Terminal
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function createConnectionToken()
    {
        try {
            Log::info('Creating Stripe Terminal Connection Token');

            $connectionToken = ConnectionToken::create();

            Log::info('Connection Token created successfully');

            return $this->successResponse([
                'secret' => $connectionToken->secret,
            ], 'Connection token created successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Connection Token Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('Failed to create connection token: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Connection Token Creation Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while creating connection token', 500);
        }
    }

    /**
     * TEST: Create Payment Intent with Card Number (For Testing)
     *
     * This endpoint allows testing payments with card numbers like 4242 4242 4242 4242
     * Use this for testing in development/sandbox mode.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function testCreatePaymentIntent(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'amount' => 'required|numeric|min:0.50',
            'tip_amount' => 'nullable|numeric|min:0',
            'currency' => 'nullable|string|size:3',
            'card_number' => 'required|string',
            'exp_month' => 'required|integer|min:1|max:12',
            'exp_year' => 'required|integer|min:' . date('Y'),
            'cvc' => 'required|string|size:3',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        if ($order->status === 'completed') {
            return $this->errorResponse('Order is already paid', 400);
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        try {
            $totalAmount = $validated['amount'] + ($validated['tip_amount'] ?? 0);
            $currency = strtolower($validated['currency'] ?? 'usd');
            $amountInCents = (int) round($totalAmount * 100);

            Log::info('Creating Test Payment Intent with card number', [
                'order_ticket_id' => $validated['order_ticket_id'],
                'amount' => $totalAmount,
                'currency' => $currency,
                'card_last4' => substr($validated['card_number'], -4),
            ]);

            // Step 1: Create Payment Method with card details
            $paymentMethod = PaymentMethod::create([
                'type' => 'card',
                'card' => [
                    'number' => str_replace(' ', '', $validated['card_number']),
                    'exp_month' => $validated['exp_month'],
                    'exp_year' => $validated['exp_year'],
                    'cvc' => $validated['cvc'],
                ],
            ]);

            Log::info('Payment Method created', [
                'payment_method_id' => $paymentMethod->id,
            ]);

            // Step 2: Create Payment Intent with card payment method
            $paymentIntent = PaymentIntent::create([
                'amount' => $amountInCents,
                'currency' => $currency,
                'payment_method' => $paymentMethod->id,
                'payment_method_types' => ['card'],
                'capture_method' => 'automatic',
                'confirm' => true, // Automatically confirm for testing
                'metadata' => [
                    'order_ticket_id' => $validated['order_ticket_id'],
                    'order_id' => $order->id,
                    'check_id' => $check->id,
                    'business_id' => $businessId,
                    'employee_id' => $employee->id,
                    'tip_amount' => $validated['tip_amount'] ?? 0,
                    'test_mode' => 'true',
                ],
                'description' => "Test Payment for Order #{$validated['order_ticket_id']}",
            ]);

            Log::info('Test Payment Intent created and confirmed', [
                'payment_intent_id' => $paymentIntent->id,
                'status' => $paymentIntent->status,
            ]);

            // If payment succeeded, process it immediately
            if ($paymentIntent->status === 'succeeded') {
                $tipAmount = $validated['tip_amount'] ?? 0;
                $baseAmount = $validated['amount'];

                $payment = Payment::create([
                    'check_id' => $check->id,
                    'employee_id' => $order->created_by_employee_id,
                    'method' => 'card',
                    'amount' => $baseAmount,
                    'tip_amount' => $tipAmount,
                    'payment_date' => now(),
                ]);

                $check->update([
                    'status' => 'paid',
                    'type' => 'online',
                ]);

                $order->update(['status' => 'completed']);

                if ($order->table) {
                    $order->table->update(['status' => 'available']);
                }

                return $this->successResponse([
                    'payment_intent_id' => $paymentIntent->id,
                    'payment_intent_status' => $paymentIntent->status,
                    'amount' => $totalAmount,
                    'currency' => $currency,
                    'payment_method_id' => $paymentMethod->id,
                    'payment' => $payment->load(['check', 'employee']),
                    'order' => $order->load(['table']),
                    'check' => $check,
                    'message' => 'Test payment processed successfully',
                ], 'Test payment processed successfully');
            }

            return $this->successResponse([
                'payment_intent_id' => $paymentIntent->id,
                'payment_intent_status' => $paymentIntent->status,
                'client_secret' => $paymentIntent->client_secret,
                'amount' => $totalAmount,
                'currency' => $currency,
                'payment_method_id' => $paymentMethod->id,
                'order' => $order,
                'check' => $check,
                'message' => 'Test payment intent created. Status: ' . $paymentIntent->status,
            ], 'Test payment intent created successfully');
        } catch (ApiErrorException $e) {
            Log::error('Stripe Test Payment Intent Error', [
                'message' => $e->getMessage(),
                'code' => $e->getStripeCode(),
            ]);

            return $this->errorResponse('Failed to process test payment: ' . $e->getMessage(), 500);
        } catch (\Exception $e) {
            Log::error('Test Payment Intent Creation Error', [
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('An error occurred while processing test payment', 500);
        }
    }
}
