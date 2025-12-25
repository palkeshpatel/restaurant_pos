<?php

namespace App\Http\Controllers\Api\Pos;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Employee;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\PaymentHistory;
use App\Models\VoidItem;
use App\Models\GratuitySetting;
use App\Services\ReportService;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

/**
 * @OA\Tag(
 *     name="POS API - Reports",
 *     description="X-Report and Z-Report endpoints for thermal printer format"
 * )
 */
class ReportController extends Controller
{
    use ApiResponse;

    /**
     * @OA\Get(
     *     path="/pos/reports/x-report",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Reports"},
     *     summary="Generate X-Report (Activity Report)",
     *     description="Generate X-Report (Activity Report) in thermal printer format. Shows current shift activity without resetting counters. Includes sales summary, payments, cash summary, and server breakdown.",
     *     @OA\Parameter(
     *         name="date",
     *         in="query",
     *         required=false,
     *         description="Date for the report (YYYY-MM-DD). Defaults to today if not provided.",
     *         @OA\Schema(type="string", format="date", example="2025-11-05")
     *     ),
     *     @OA\Parameter(
     *         name="employee_id",
     *         in="query",
     *         required=false,
     *         description="Filter by specific employee/server. If not provided, shows all employees.",
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="X-Report generated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="report_type", type="string", example="X-REPORT"),
     *                 @OA\Property(property="business_name", type="string", example="OLE CRAFT KITCHEN"),
     *                 @OA\Property(property="report_date", type="string", example="11/05/2025"),
     *                 @OA\Property(property="printed_at", type="string", example="11/05/2025 06:13:06 PM"),
     *                 @OA\Property(property="sales_summary", type="object"),
     *                 @OA\Property(property="payments", type="object"),
     *                 @OA\Property(property="cash_summary", type="object"),
     *                 @OA\Property(property="cash_balance", type="object"),
     *                 @OA\Property(property="server_sales_tips", type="object",
     *                     @OA\Property(property="servers", type="array", @OA\Items(type="object",
     *                         @OA\Property(property="name", type="string"),
     *                         @OA\Property(property="sales", type="string"),
     *                         @OA\Property(property="tips", type="string")
     *                     )),
     *                     @OA\Property(property="totals", type="object",
     *                         @OA\Property(property="sales", type="string"),
     *                         @OA\Property(property="tips", type="string")
     *                     )
     *                 ),
     *                 @OA\Property(property="thermal_format", type="string", description="Formatted text for thermal printer"),
     *                 @OA\Property(property="thermal_format_html", type="string", description="HTML formatted version of the thermal format. This is a complete HTML document that can be viewed in a browser or embedded in an iframe. Copy the HTML content and save it as an .html file to view, or use it directly in web applications.")
     *             )
     *         )
     *     )
     * )
     */
    public function generateXReport(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'date' => 'nullable|date',
            'employee_id' => 'nullable|integer|exists:employees,id',
            'format' => 'nullable|string|in:json,text,pdf',
        ]);

        $reportDate = $validated['date'] ?? now()->format('Y-m-d');
        $employeeId = $validated['employee_id'] ?? null;
        $format = $validated['format'] ?? 'json';

        $business = Business::find($businessId);
        $businessName = $business->name ?? 'RESTAURANT';

        // Get date range for the report
        $startOfDay = Carbon::parse($reportDate)->startOfDay();
        $endOfDay = Carbon::parse($reportDate)->endOfDay();

        // Build base query
        $ordersQuery = Order::where('business_id', $businessId)
            ->whereBetween('created_at', [$startOfDay, $endOfDay]);

        if ($employeeId) {
            $ordersQuery->where('created_by_employee_id', $employeeId);
        }

        $orders = $ordersQuery->with([
            'checks.orderItems' => function ($query) {
                $query->whereNotIn('order_status', [2, 3]); // Exclude TEMP (2) and VOID (3) items
            },
            'checks.orderItems.modifiers',
            'checks.orderItems.menuItem',
            'createdByEmployee',
        ])->get();

        // Separate closed and open orders
        $closedOrders = $orders->where('status', 'completed');
        $openOrders = $orders->where('status', '!=', 'completed');

        // Calculate sales summary
        $salesSummary = $this->calculateSalesSummary($closedOrders, $openOrders);

        // Calculate payments
        $payments = $this->calculatePayments($orders);

        // Calculate cash summary
        $cashSummary = $this->calculateCashSummary($orders);

        // Calculate cash balance
        $cashBalance = $this->calculateCashBalance($cashSummary, $orders);

        // Calculate server sales and tips
        $serverSalesTips = $this->calculateServerSalesTips($orders, $employeeId);

        // Prepare data for Blade templates
        $thermalData = [
            'businessName' => $businessName,
            'reportDate' => Carbon::parse($reportDate)->format('m/d/Y'),
            'printedAt' => now()->format('m/d/Y h:i:s A'),
            'salesSummary' => $salesSummary,
            'payments' => $payments,
            'cashSummary' => $cashSummary,
            'cashBalance' => $cashBalance,
            'serverSalesTips' => $serverSalesTips,
        ];

        // Generate thermal format using Blade template
        $reportService = app(ReportService::class);
        $thermalFormat = $reportService->generateThermalFormat('x-report', $thermalData);

        // Handle different response formats
        if ($format === 'text') {
            // Return only thermal format as plain text
            return response($thermalFormat, 200)
                ->header('Content-Type', 'text/plain; charset=utf-8')
                ->header('Content-Disposition', 'inline; filename="x-report-' . $reportDate . '.txt"');
        } elseif ($format === 'pdf') {
            // Return PDF (we'll implement this)
            return $this->generatePdfResponse($thermalFormat, 'X-REPORT', $reportDate);
        }

        // Generate HTML format using Blade template
        $thermalFormatHtml = $reportService->generateThermalFormatHtml('x-report', $thermalData);

        // Default: return full JSON response
        return $this->successResponse([
            'report_type' => 'X-REPORT',
            'business_name' => $businessName,
            'report_date' => Carbon::parse($reportDate)->format('m/d/Y'),
            'printed_at' => now()->format('m/d/Y h:i:s A'),
            'sales_summary' => $salesSummary,
            'payments' => $payments,
            'cash_summary' => $cashSummary,
            'cash_balance' => $cashBalance,
            'server_sales_tips' => $serverSalesTips,
            'thermal_format' => $thermalFormat,
            'thermal_format_html' => $thermalFormatHtml,
        ], 'X-Report generated successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/reports/z-report",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Reports"},
     *     summary="Generate Z-Report (Daily Report)",
     *     description="Generate Z-Report (Daily Report) in thermal printer format. Shows end-of-day summary for a specific date. Includes sales summary, payments, cash out, total owed to restaurant, total tips, and suggested tip out.",
     *     @OA\Parameter(
     *         name="date",
     *         in="query",
     *         required=false,
     *         description="Date for the report (YYYY-MM-DD). Defaults to today if not provided.",
     *         @OA\Schema(type="string", format="date", example="2025-11-03")
     *     ),
     *     @OA\Parameter(
     *         name="employee_id",
     *         in="query",
     *         required=false,
     *         description="Filter by specific employee/server. If not provided, shows all employees.",
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\Parameter(
     *         name="format",
     *         in="query",
     *         required=false,
     *         description="Response format: 'json' (default) returns full JSON data, 'text' returns only thermal format as plain text, 'pdf' returns PDF document.",
     *         @OA\Schema(type="string", enum={"json", "text", "pdf"}, example="json")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Z-Report generated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="report_type", type="string", example="Z-REPORT"),
     *                 @OA\Property(property="business_name", type="string", example="OLE CRAFT KITCHEN"),
     *                 @OA\Property(property="report_date", type="string", example="11/03/2025"),
     *                 @OA\Property(property="printed_at", type="string", example="11/05/2025 06:12:12 PM"),
     *                 @OA\Property(property="server_name", type="string", example="Tyler Dejong"),
     *                 @OA\Property(property="sales_summary", type="object"),
     *                 @OA\Property(property="payments", type="object"),
     *                 @OA\Property(property="cash_summary", type="object"),
     *                 @OA\Property(property="cash_balance", type="object"),
     *                 @OA\Property(property="cash_out", type="object"),
     *                 @OA\Property(property="total_owed_to_restaurant", type="number", example=165.76),
     *                 @OA\Property(property="total_tips", type="number", example=74.58),
     *                 @OA\Property(property="suggested_tip_out", type="array", @OA\Items(type="object")),
     *                 @OA\Property(property="server_sales_tips", type="object",
     *                     @OA\Property(property="servers", type="array", @OA\Items(type="object",
     *                         @OA\Property(property="name", type="string"),
     *                         @OA\Property(property="sales", type="string"),
     *                         @OA\Property(property="tips", type="string")
     *                     )),
     *                     @OA\Property(property="totals", type="object",
     *                         @OA\Property(property="sales", type="string"),
     *                         @OA\Property(property="tips", type="string")
     *                     )
     *                 ),
     *                 @OA\Property(property="thermal_format", type="string", description="Formatted text for thermal printer"),
     *                 @OA\Property(property="thermal_format_html", type="string", description="HTML formatted version of the thermal format. This is a complete HTML document that can be viewed in a browser or embedded in an iframe. Copy the HTML content and save it as an .html file to view, or use it directly in web applications.")
     *             )
     *         )
     *     )
     * )
     */
    public function generateZReport(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'date' => 'nullable|date',
            'employee_id' => 'nullable|integer|exists:employees,id',
            'format' => 'nullable|string|in:json,text,pdf',
        ]);

        $reportDate = $validated['date'] ?? now()->format('Y-m-d');
        $employeeId = $validated['employee_id'] ?? null;
        $format = $validated['format'] ?? 'json';

        $business = Business::find($businessId);
        $businessName = $business->name ?? 'RESTAURANT';

        // Get date range for the report
        $startOfDay = Carbon::parse($reportDate)->startOfDay();
        $endOfDay = Carbon::parse($reportDate)->endOfDay();

        // Build base query
        $ordersQuery = Order::where('business_id', $businessId)
            ->whereBetween('created_at', [$startOfDay, $endOfDay]);

        if ($employeeId) {
            $ordersQuery->where('created_by_employee_id', $employeeId);
        }

        $orders = $ordersQuery->with([
            'checks.orderItems' => function ($query) {
                $query->whereNotIn('order_status', [2, 3]); // Exclude TEMP (2) and VOID (3) items
            },
            'checks.orderItems.modifiers',
            'checks.orderItems.menuItem',
            'createdByEmployee',
        ])->get();

        // Separate closed and open orders
        $closedOrders = $orders->where('status', 'completed');
        $openOrders = $orders->where('status', '!=', 'completed');

        // Calculate sales summary
        $salesSummary = $this->calculateSalesSummary($closedOrders, $openOrders);

        // Calculate payments
        $payments = $this->calculatePayments($orders);

        // Calculate cash summary
        $cashSummary = $this->calculateCashSummary($orders);

        // Calculate cash balance
        $cashBalance = $this->calculateCashBalance($cashSummary, $orders);

        // Calculate cash out
        $cashOut = $this->calculateCashOut($orders);

        // Calculate total owed to restaurant
        $totalOwedToRestaurant = $this->calculateTotalOwedToRestaurant($cashOut);

        // Calculate total tips
        $totalTips = $this->calculateTotalTips($orders);

        // Calculate suggested tip out
        $suggestedTipOut = $this->calculateSuggestedTipOut($salesSummary, $businessId);

        // Calculate server sales and tips
        $serverSalesTips = $this->calculateServerSalesTips($orders, $employeeId);

        // Get server name
        $serverName = null;
        if ($employeeId) {
            $server = Employee::find($employeeId);
            $serverName = $server ? trim($server->first_name . ' ' . $server->last_name) : null;
        }

        // Format cash_out values for JSON response (convert from float to formatted string)
        $cashOutFormatted = [
            'credit_tips' => number_format($cashOut['credit_tips'], 2, '.', ''),
            'service_charge' => number_format($cashOut['service_charge'], 2, '.', ''),
            'cash_on_hand' => number_format($cashOut['cash_on_hand'], 2, '.', ''),
        ];

        // Generate report number: YEAR-DAYOFYEAR (e.g., 2025-307)
        $carbonDate = Carbon::parse($reportDate);
        $year = $carbonDate->format('Y');
        $dayOfYear = $carbonDate->format('z') + 1;
        $reportNumber = $year . '-' . str_pad($dayOfYear, 3, '0', STR_PAD_LEFT);

        // Prepare data for Blade templates
        $thermalData = [
            'businessName' => $businessName,
            'reportDate' => Carbon::parse($reportDate)->format('m/d/Y'),
            'printedAt' => now()->format('m/d/Y h:i:s A'),
            'reportNumber' => $reportNumber,
            'salesSummary' => $salesSummary,
            'payments' => $payments,
            'cashSummary' => $cashSummary,
            'cashBalance' => $cashBalance,
            'cashOut' => $cashOutFormatted,
            'totalOwedToRestaurant' => $totalOwedToRestaurant,
            'totalTips' => $totalTips,
            'suggestedTipOut' => $suggestedTipOut,
            'serverSalesTips' => $serverSalesTips,
        ];

        // Generate thermal format using Blade template
        $reportService = app(ReportService::class);
        $thermalFormat = $reportService->generateThermalFormat('z-report', $thermalData);

        // Handle different response formats
        if ($format === 'text') {
            // Return only thermal format as plain text
            return response($thermalFormat, 200)
                ->header('Content-Type', 'text/plain; charset=utf-8')
                ->header('Content-Disposition', 'inline; filename="z-report-' . $reportDate . '.txt"');
        } elseif ($format === 'pdf') {
            // Return PDF (we'll implement this)
            return $this->generatePdfResponse($thermalFormat, 'Z-REPORT', $reportDate);
        }

        // Generate HTML format using Blade template
        $thermalFormatHtml = $reportService->generateThermalFormatHtml('z-report', $thermalData);

        // Default: return full JSON response
        return $this->successResponse([
            'report_type' => 'Z-REPORT',
            'business_name' => $businessName,
            'report_date' => Carbon::parse($reportDate)->format('m/d/Y'),
            'printed_at' => now()->format('m/d/Y h:i:s A'),
            'server_name' => $serverName,
            'sales_summary' => $salesSummary,
            'payments' => $payments,
            'cash_summary' => $cashSummary,
            'cash_balance' => $cashBalance,
            'cash_out' => $cashOutFormatted,
            'total_owed_to_restaurant' => number_format($totalOwedToRestaurant, 2, '.', ''),
            'total_tips' => number_format($totalTips, 2, '.', ''),
            'suggested_tip_out' => $suggestedTipOut,
            'server_sales_tips' => $serverSalesTips,
            'thermal_format' => $thermalFormat,
            'thermal_format_html' => $thermalFormatHtml,
        ], 'Z-Report generated successfully');
    }

    /**
     * Calculate sales summary for closed and open orders
     */
    private function calculateSalesSummary($closedOrders, $openOrders)
    {
        $closedData = $this->calculateOrderTotals($closedOrders);
        $openData = $this->calculateOrderTotals($openOrders);
        $totalData = $this->calculateOrderTotals($closedOrders->merge($openOrders));

        return [
            'closed_orders' => [
                'guests' => $closedOrders->sum('customer') ?? 0,
                'ppa' => $closedData['guests'] > 0 ? number_format($closedData['net_sales'] / $closedData['guests'], 2, '.', '') : '0.00',
                'net_sales' => number_format($closedData['net_sales'], 2, '.', ''),
                'taxes' => number_format($closedData['taxes'], 2, '.', ''),
                'service_charge' => number_format($closedData['service_charge'], 2, '.', ''),
                'tips' => number_format($closedData['tips'], 2, '.', ''),
                'fees' => number_format($closedData['fees'], 2, '.', ''),
                'total' => number_format($closedData['total'], 2, '.', ''),
            ],
            'open_orders' => [
                'guests' => $openOrders->sum('customer') ?? 0,
                'ppa' => $openData['guests'] > 0 ? number_format($openData['net_sales'] / $openData['guests'], 2, '.', '') : '0.00',
                'net_sales' => number_format($openData['net_sales'], 2, '.', ''),
                'taxes' => number_format($openData['taxes'], 2, '.', ''),
                'service_charge' => number_format($openData['service_charge'], 2, '.', ''),
                'tips' => number_format($openData['tips'], 2, '.', ''),
                'fees' => number_format($openData['fees'], 2, '.', ''),
                'total' => number_format($openData['total'], 2, '.', ''),
            ],
            'total_sales' => [
                'guests' => $totalData['guests'],
                'ppa' => $totalData['guests'] > 0 ? number_format($totalData['net_sales'] / $totalData['guests'], 2, '.', '') : '0.00',
                'total_amount' => number_format($totalData['total'], 2, '.', ''),
            ],
        ];
    }

    /**
     * Calculate totals for a collection of orders
     */
    private function calculateOrderTotals($orders)
    {
        $netSales = 0;
        $taxes = 0;
        $serviceCharge = 0;
        $tips = 0;
        $fees = 0;
        $guests = 0;

        if (!$orders || $orders->isEmpty()) {
            return [
                'net_sales' => 0,
                'taxes' => 0,
                'service_charge' => 0,
                'tips' => 0,
                'fees' => 0,
                'total' => 0,
                'guests' => 0,
            ];
        }

        foreach ($orders as $order) {
            $guests += $order->customer ?? 0;

            if (!$order->checks || $order->checks->isEmpty()) {
                continue;
            }

            foreach ($order->checks as $check) {
                if (!$check->orderItems || $check->orderItems->isEmpty()) {
                    continue;
                }

                foreach ($check->orderItems as $item) {
                    // Skip TEMP (2) and VOID (3) items
                    if (in_array($item->order_status, [2, 3])) {
                        continue;
                    }

                    // Calculate item total with modifiers
                    $itemTotal = ($item->unit_price * $item->qty);

                    // Add modifier prices
                    if ($item->relationLoaded('modifiers')) {
                        foreach ($item->modifiers as $modifier) {
                            $modifierPrice = $modifier->pivot->price ?? 0;
                            $modifierQty = $modifier->pivot->qty ?? 1;
                            $itemTotal += ($modifierPrice * $modifierQty);
                        }
                    }

                    // Subtract discount
                    $itemTotal -= ($item->discount_amount ?? 0);
                    $netSales += $itemTotal;
                }
            }

            // Calculate order-level net sales first
            $orderNetSales = 0;
            foreach ($order->checks as $check) {
                if ($check->orderItems && !$check->orderItems->isEmpty()) {
                    foreach ($check->orderItems as $item) {
                        // Skip TEMP (2) and VOID (3) items
                        if (in_array($item->order_status, [2, 3])) {
                            continue;
                        }

                        $itemTotal = ($item->unit_price * $item->qty);
                        if ($item->relationLoaded('modifiers')) {
                            foreach ($item->modifiers as $modifier) {
                                $modifierPrice = $modifier->pivot->price ?? 0;
                                $modifierQty = $modifier->pivot->qty ?? 1;
                                $itemTotal += ($modifierPrice * $modifierQty);
                            }
                        }
                        $itemTotal -= ($item->discount_amount ?? 0);
                        $orderNetSales += $itemTotal;
                    }
                }
            }

            // Add order-level charges
            $orderTaxes = $order->tax_value ?? 0;
            $taxes += $orderTaxes;
            $fees += $order->fee_value ?? 0;

            // Calculate gratuity (service charge) for this specific order
            $gratuityAmount = $this->calculateGratuityForOrder($order, $orderNetSales, $orderTaxes);
            $serviceCharge += $gratuityAmount;

            // Get tips from payment history (only from completed payments, not refunds)
            $orderTips = PaymentHistory::where('order_id', $order->id)
                ->where('status', 'completed')
                ->sum('tip_amount');
            $tips += $orderTips;
        }

        // Subtract total refunds from net sales across all orders (refunds appear as negative sales)
        $totalRefundedAmount = PaymentHistory::whereIn('order_id', $orders->pluck('id'))
            ->where('status', 'refunded')
            ->sum('amount');
        $netSales -= (float) $totalRefundedAmount;

        $total = $netSales + $taxes + $serviceCharge + $tips + $fees;

        return [
            'net_sales' => $netSales,
            'taxes' => $taxes,
            'service_charge' => $serviceCharge,
            'tips' => $tips,
            'fees' => $fees,
            'total' => $total,
            'guests' => $guests,
        ];
    }

    /**
     * Calculate gratuity for a single order
     */
    private function calculateGratuityForOrder($order, $netSales, $taxes)
    {
        $gratuityKey = $order->gratuity_key ?? 'NotApplicable';

        if ($gratuityKey === 'NotApplicable') {
            return 0;
        }

        $amountAfterTax = $netSales + $taxes;
        $gratuityType = $order->getAttributes()['gratuity_type'] ?? null;
        $gratuityValue = (float) ($order->getAttributes()['gratuity_value'] ?? 0);

        if ($gratuityKey === 'Manual' && $gratuityType && $gratuityValue > 0) {
            if ($gratuityType === 'percentage') {
                return ($amountAfterTax * $gratuityValue) / 100;
            } else {
                return $gratuityValue;
            }
        } elseif ($gratuityKey === 'Auto') {
            $gratuitySetting = GratuitySetting::where('business_id', $order->business_id)->first();
            if ($gratuitySetting) {
                if ($gratuitySetting->gratuity_type === 'percentage') {
                    return ($amountAfterTax * $gratuitySetting->gratuity_value) / 100;
                } else {
                    return $gratuitySetting->gratuity_value ?? 0;
                }
            }
        }

        return 0;
    }

    /**
     * Calculate payments breakdown
     */
    private function calculatePayments($orders)
    {
        $payments = [
            'cash' => ['qty' => 0, 'tips' => 0, 'total' => 0],
            'card' => ['qty' => 0, 'tips' => 0, 'total' => 0],
            'online' => ['qty' => 0, 'tips' => 0, 'total' => 0],
        ];

        $cardTypes = [
            'amex' => ['qty' => 0, 'tips' => 0, 'total' => 0],
            'mastercard' => ['qty' => 0, 'tips' => 0, 'total' => 0],
            'visa' => ['qty' => 0, 'tips' => 0, 'total' => 0],
        ];

        foreach ($orders as $order) {
            $paymentHistories = PaymentHistory::where('order_id', $order->id)
                ->whereIn('status', ['completed', 'refunded'])
                ->get();

            foreach ($paymentHistories as $payment) {
                $mode = strtolower($payment->payment_mode ?? '');
                $amount = (float) $payment->amount;
                $tipAmount = (float) $payment->tip_amount;
                $isRefund = $payment->status === 'refunded';

                if (in_array($mode, ['cash', 'card', 'online'])) {
                    if ($isRefund) {
                        // Refunds: subtract from totals (negative sales)
                        $payments[$mode]['qty']--; // Count refund as negative quantity
                        $payments[$mode]['tips'] -= $tipAmount; // Tips are not refunded, but we subtract if any
                        $payments[$mode]['total'] -= $amount; // Subtract refund amount (negative)
                    } else {
                        // Completed payments: add to totals
                        $payments[$mode]['qty']++;
                        $payments[$mode]['tips'] += $tipAmount;
                        $payments[$mode]['total'] += $amount;
                    }
                }

                // For card payments, you might want to track by card type
                // This is a simplified version - adjust based on your payment_mode values
                if ($mode === 'card') {
                    // You may need to add card_type field to payment_histories table
                    // For now, we'll just count as generic 'card'
                }
            }
        }

        return [
            'payments' => [
                'cash' => [
                    'qty' => $payments['cash']['qty'],
                    'tips' => number_format($payments['cash']['tips'], 2, '.', ''),
                    'total' => number_format($payments['cash']['total'], 2, '.', ''),
                ],
                'card' => [
                    'qty' => $payments['card']['qty'],
                    'tips' => number_format($payments['card']['tips'], 2, '.', ''),
                    'total' => number_format($payments['card']['total'], 2, '.', ''),
                ],
                'online' => [
                    'qty' => $payments['online']['qty'],
                    'tips' => number_format($payments['online']['tips'], 2, '.', ''),
                    'total' => number_format($payments['online']['total'], 2, '.', ''),
                ],
            ],
            'card_types' => [
                'amex' => [
                    'qty' => $cardTypes['amex']['qty'],
                    'tips' => number_format($cardTypes['amex']['tips'], 2, '.', ''),
                    'total' => number_format($cardTypes['amex']['total'], 2, '.', ''),
                ],
                'mastercard' => [
                    'qty' => $cardTypes['mastercard']['qty'],
                    'tips' => number_format($cardTypes['mastercard']['tips'], 2, '.', ''),
                    'total' => number_format($cardTypes['mastercard']['total'], 2, '.', ''),
                ],
                'visa' => [
                    'qty' => $cardTypes['visa']['qty'],
                    'tips' => number_format($cardTypes['visa']['tips'], 2, '.', ''),
                    'total' => number_format($cardTypes['visa']['total'], 2, '.', ''),
                ],
            ],
            'totals' => [
                'tips' => number_format(array_sum(array_column($payments, 'tips')), 2, '.', ''),
                'total' => number_format(array_sum(array_column($payments, 'total')), 2, '.', ''),
            ],
        ];
    }

    /**
     * Calculate cash summary
     */
    private function calculateCashSummary($orders)
    {
        $closedCash = 0;
        $openCash = 0;

        foreach ($orders as $order) {
            $cashPayments = PaymentHistory::where('order_id', $order->id)
                ->where('status', 'completed')
                ->where('payment_mode', 'cash')
                ->sum('amount');
            
            // Subtract cash refunds
            $cashRefunds = PaymentHistory::where('order_id', $order->id)
                ->where('status', 'refunded')
                ->where('payment_mode', 'cash')
                ->sum('amount');
            
            $netCash = (float) $cashPayments - (float) $cashRefunds;

            if ($order->status === 'completed') {
                $closedCash += $netCash;
            } else {
                $openCash += $netCash;
            }
        }

        return [
            'closed_orders' => number_format($closedCash, 2, '.', ''),
            'open_orders' => number_format($openCash, 2, '.', ''),
            'prepaid_load' => number_format($closedCash, 2, '.', ''), // Adjust based on your business logic
            'pay_in_pay_out' => '0.00', // Adjust based on your business logic
            'cash_on_hand_total' => number_format($closedCash + $openCash, 2, '.', ''),
        ];
    }

    /**
     * Calculate drawer summary
     */
    private function calculateDrawerSummary($orders, $businessId)
    {
        // This is a placeholder - implement based on your drawer tracking system
        return [
            'bar_drawer_left' => ['in_out' => '0.00', 'total' => '0.00'],
            'dining_room_drawer' => ['total' => '0.00'],
            'bar_drawer_right' => ['in_out' => '0.00', 'total' => '0.00'],
            'total_in_drawers' => '0.00',
        ];
    }

    /**
     * Calculate cash balance
     */
    private function calculateCashBalance($cashSummary, $orders)
    {
        $cashOnHand = $cashSummary['cash_on_hand_total'];

        $creditTips = PaymentHistory::whereIn('order_id', $orders->pluck('id'))
            ->where('status', 'completed')
            ->where('payment_mode', '!=', 'cash')
            ->sum('tip_amount');

        $serviceCharge = 0;
        foreach ($orders as $order) {
            $serviceCharge += $this->calculateGratuityForOrder(
                $order,
                $this->getOrderNetSales($order),
                $order->tax_value ?? 0
            );
        }

        return [
            'cash_on_hand' => number_format($cashOnHand, 2, '.', ''),
            'credit_tips' => number_format($creditTips, 2, '.', ''),
            'service_charge' => number_format($serviceCharge, 2, '.', ''),
            'total_cash' => number_format($cashOnHand + $creditTips + $serviceCharge, 2, '.', ''),
        ];
    }

    /**
     * Get net sales for a single order
     */
    private function getOrderNetSales($order)
    {
        $netSales = 0;

        if (!$order->checks || $order->checks->isEmpty()) {
            // Still need to subtract refunds even if no items
            $refundedAmount = PaymentHistory::where('order_id', $order->id)
                ->where('status', 'refunded')
                ->sum('amount');
            return -(float) $refundedAmount;
        }

        foreach ($order->checks as $check) {
            if (!$check->orderItems || $check->orderItems->isEmpty()) {
                continue;
            }

            foreach ($check->orderItems as $item) {
                // Skip TEMP (2) and VOID (3) items
                if (in_array($item->order_status, [2, 3])) {
                    continue;
                }

                $itemTotal = ($item->unit_price * $item->qty);
                if ($item->relationLoaded('modifiers')) {
                    foreach ($item->modifiers as $modifier) {
                        $modifierPrice = $modifier->pivot->price ?? 0;
                        $modifierQty = $modifier->pivot->qty ?? 1;
                        $itemTotal += ($modifierPrice * $modifierQty);
                    }
                }
                $itemTotal -= ($item->discount_amount ?? 0);
                $netSales += $itemTotal;
            }
        }
        
        // Subtract refunds from net sales (refunds appear as negative sales)
        $refundedAmount = PaymentHistory::where('order_id', $order->id)
            ->where('status', 'refunded')
            ->sum('amount');
        $netSales -= (float) $refundedAmount;
        
        return $netSales;
    }

    /**
     * Calculate audit/exceptions
     */
    private function calculateAuditExceptions($orders, $startOfDay, $endOfDay)
    {
        $othOrders = 0;
        $othDishes = 0;
        $voids = 0;
        $returns = 0;
        $discounts = 0;

        $voidAmount = 0;
        $returnAmount = 0;
        $discountAmount = 0;

        foreach ($orders as $order) {
            if (!$order->checks || $order->checks->isEmpty()) {
                continue;
            }

            foreach ($order->checks as $check) {
                if (!$check->orderItems || $check->orderItems->isEmpty()) {
                    continue;
                }

                foreach ($check->orderItems as $item) {
                    // Count voided items
                    if ($item->order_status == 3) {
                        $voids++;
                        $voidAmount += ($item->unit_price * $item->qty);
                    }

                    // Count discounts
                    if (!empty($item->discount_amount) && $item->discount_amount > 0) {
                        $discounts++;
                        $discountAmount += $item->discount_amount;
                    }
                }
            }
        }

        // Count void items from void_items table
        $voidItems = VoidItem::whereIn('order_id', $orders->pluck('id'))
            ->whereBetween('created_at', [$startOfDay, $endOfDay])
            ->count();

        return [
            'oth_orders' => ['qty' => $othOrders, 'total' => '0.00'],
            'oth_dishes' => ['qty' => $othDishes, 'total' => '0.00'],
            'voids' => ['qty' => $voids, 'total' => number_format($voidAmount, 2, '.', '')],
            'returns' => ['qty' => $returns, 'total' => number_format($returnAmount, 2, '.', '')],
            'discounts' => ['qty' => $discounts, 'total' => number_format($discountAmount, 2, '.', '')],
        ];
    }

    /**
     * Calculate server sales and tips
     */
    private function calculateServerSalesTips($orders, $filterEmployeeId = null)
    {
        $serverData = [];

        foreach ($orders as $order) {
            $employeeId = $order->created_by_employee_id;

            if ($filterEmployeeId && $employeeId != $filterEmployeeId) {
                continue;
            }

            if (!isset($serverData[$employeeId])) {
                $employee = $order->createdByEmployee;
                $serverData[$employeeId] = [
                    'employee_id' => $employeeId,
                    'name' => $employee ? trim($employee->first_name . ' ' . $employee->last_name) : 'Unknown',
                    'sales' => 0,
                    'tips' => 0,
                ];
            }

            // Calculate sales for this order
            $orderSales = $this->getOrderNetSales($order);
            $serverData[$employeeId]['sales'] += $orderSales;

            // Get tips for this order
            $orderTips = PaymentHistory::where('order_id', $order->id)
                ->where('status', 'completed')
                ->sum('tip_amount');
            $serverData[$employeeId]['tips'] += $orderTips;
        }

        $servers = array_values(array_map(function ($data) {
            return [
                'name' => $data['name'],
                'sales' => number_format($data['sales'], 2, '.', ''),
                'tips' => number_format($data['tips'], 2, '.', ''),
            ];
        }, $serverData));

        // Calculate totals
        $totalSales = array_sum(array_column($serverData, 'sales'));
        $totalTips = array_sum(array_column($serverData, 'tips'));

        // Ensure servers is always an array, never null
        if (empty($servers)) {
            $servers = [];
        }

        return [
            'servers' => $servers,
            'totals' => [
                'sales' => number_format($totalSales, 2, '.', ''),
                'tips' => number_format($totalTips, 2, '.', ''),
            ],
        ];
    }

    /**
     * Calculate cash out
     */
    private function calculateCashOut($orders)
    {
        $creditTips = PaymentHistory::whereIn('order_id', $orders->pluck('id'))
            ->where('status', 'completed')
            ->where('payment_mode', '!=', 'cash')
            ->sum('tip_amount');

        $serviceCharge = 0;
        foreach ($orders as $order) {
            $serviceCharge += $this->calculateGratuityForOrder(
                $order,
                $this->getOrderNetSales($order),
                $order->tax_value ?? 0
            );
        }

        $cashOnHand = PaymentHistory::whereIn('order_id', $orders->pluck('id'))
            ->where('status', 'completed')
            ->where('payment_mode', 'cash')
            ->sum('amount');
        
        // Subtract cash refunds
        $cashRefunds = PaymentHistory::whereIn('order_id', $orders->pluck('id'))
            ->where('status', 'refunded')
            ->where('payment_mode', 'cash')
            ->sum('amount');
        
        $cashOnHand -= (float) $cashRefunds;

        return [
            'credit_tips' => (float) $creditTips,
            'service_charge' => (float) $serviceCharge,
            'cash_on_hand' => (float) $cashOnHand,
        ];
    }

    /**
     * Calculate total owed to restaurant
     */
    private function calculateTotalOwedToRestaurant($cashOut)
    {
        // Total owed = Cash on Hand - (Credit Tips + Service Charge)
        $cashOnHand = (float) $cashOut['cash_on_hand'];
        $creditTips = (float) $cashOut['credit_tips'];
        $serviceCharge = (float) $cashOut['service_charge'];

        return $cashOnHand - ($creditTips + $serviceCharge);
    }

    /**
     * Calculate total tips
     */
    private function calculateTotalTips($orders)
    {
        $cashTips = PaymentHistory::whereIn('order_id', $orders->pluck('id'))
            ->where('status', 'completed')
            ->where('payment_mode', 'cash')
            ->sum('tip_amount');

        $creditTips = PaymentHistory::whereIn('order_id', $orders->pluck('id'))
            ->where('status', 'completed')
            ->where('payment_mode', '!=', 'cash')
            ->sum('tip_amount');

        return $cashTips + $creditTips;
    }

    /**
     * Calculate suggested tip out
     */
    private function calculateSuggestedTipOut($salesSummary, $businessId)
    {
        // This is a placeholder - implement based on your tip out rules
        // Example: Bar 10%, Busser 3%, Runner 3%, Bar Back 3%
        // Convert string to float for calculation
        $netSales = (float) str_replace(',', '', $salesSummary['closed_orders']['net_sales'] ?? '0.00');

        return [
            [
                'role' => 'Bar',
                'percentage' => '10.00',
                'base_amount' => number_format($netSales, 2, '.', ''),
                'tip_out' => number_format(($netSales * 10) / 100, 2, '.', ''),
            ],
            [
                'role' => 'Busser',
                'percentage' => '3.00',
                'base_amount' => number_format($netSales, 2, '.', ''),
                'tip_out' => number_format(($netSales * 3) / 100, 2, '.', ''),
            ],
            [
                'role' => 'Runner',
                'percentage' => '3.00',
                'base_amount' => number_format($netSales, 2, '.', ''),
                'tip_out' => number_format(($netSales * 3) / 100, 2, '.', ''),
            ],
            [
                'role' => 'Bar Back',
                'percentage' => '3.00',
                'base_amount' => number_format($netSales, 2, '.', ''),
                'tip_out' => number_format(($netSales * 3) / 100, 2, '.', ''),
            ],
        ];
    }

    /**
     * Format X-Report for thermal printer
     */
    private function formatXReportForThermal(
        $businessName,
        $reportDate,
        $salesSummary,
        $payments,
        $cashSummary,
        $cashBalance,
        $serverSalesTips
    ) {
        $lines = [];
        $lines[] = str_pad($businessName, 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad('ACTIVITY REPORT X', 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad(Carbon::parse($reportDate)->format('m/d/Y'), 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad(now()->format('m/d/Y h:i:s A'), 32, ' ', STR_PAD_BOTH);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'SALES SUMMARY:';
        $lines[] = 'CLOSED ORDERS:';
        $lines[] = '  Guests: ' . $salesSummary['closed_orders']['guests'];
        $lines[] = '  PPA: ' . number_format($salesSummary['closed_orders']['ppa'], 2);
        $lines[] = '  Net Sales: ' . number_format($salesSummary['closed_orders']['net_sales'], 2);
        $lines[] = '  Taxes: ' . number_format($salesSummary['closed_orders']['taxes'], 2);
        $lines[] = '  Service Charge: ' . number_format($salesSummary['closed_orders']['service_charge'], 2);
        $lines[] = '  Tips: ' . number_format($salesSummary['closed_orders']['tips'], 2);
        $lines[] = '  Fees: ' . number_format($salesSummary['closed_orders']['fees'], 2);
        $lines[] = '  Total: ' . number_format($salesSummary['closed_orders']['total'], 2);
        $lines[] = '';
        $lines[] = 'OPEN ORDERS:';
        $lines[] = '  Guests: ' . $salesSummary['open_orders']['guests'];
        $lines[] = '  PPA: ' . number_format($salesSummary['open_orders']['ppa'], 2);
        $lines[] = '  Net Sales: ' . number_format($salesSummary['open_orders']['net_sales'], 2);
        $lines[] = '  Taxes: ' . number_format($salesSummary['open_orders']['taxes'], 2);
        $lines[] = '  Service Charge: ' . number_format($salesSummary['open_orders']['service_charge'], 2);
        $lines[] = '  Tips: ' . number_format($salesSummary['open_orders']['tips'], 2);
        $lines[] = '  Fees: ' . number_format($salesSummary['open_orders']['fees'], 2);
        $lines[] = '  Total: ' . number_format($salesSummary['open_orders']['total'], 2);
        $lines[] = '';
        $lines[] = 'TOTAL SALES:';
        $lines[] = '  Guests: ' . $salesSummary['total_sales']['guests'];
        $lines[] = '  PPA: ' . number_format($salesSummary['total_sales']['ppa'], 2);
        $lines[] = '  Total Amount: ' . number_format($salesSummary['total_sales']['total_amount'], 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'PAYMENTS:';
        $lines[] = '  Cash: QTY ' . $payments['payments']['cash']['qty'] . ', Tips ' . number_format($payments['payments']['cash']['tips'], 2) . ', Total ' . number_format($payments['payments']['cash']['total'], 2);
        $lines[] = '  Card: QTY ' . $payments['payments']['card']['qty'] . ', Tips ' . number_format($payments['payments']['card']['tips'], 2) . ', Total ' . number_format($payments['payments']['card']['total'], 2);
        $lines[] = '  Online: QTY ' . $payments['payments']['online']['qty'] . ', Tips ' . number_format($payments['payments']['online']['tips'], 2) . ', Total ' . number_format($payments['payments']['online']['total'], 2);
        $lines[] = '  TOTALS: Tips ' . number_format($payments['totals']['tips'], 2) . ', Total ' . number_format($payments['totals']['total'], 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'CASH SUMMARY:';
        $lines[] = '  CLOSED ORDERS: ' . number_format($cashSummary['closed_orders'], 2);
        $lines[] = '  OPEN ORDERS: ' . number_format($cashSummary['open_orders'], 2);
        $lines[] = '  CASH ON HAND TOTAL: ' . number_format($cashSummary['cash_on_hand_total'], 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'CASH BALANCE:';
        $lines[] = '  CASH ON HAND: ' . number_format($cashBalance['cash_on_hand'], 2);
        $lines[] = '  CREDIT TIPS: ' . number_format($cashBalance['credit_tips'], 2);
        $lines[] = '  SERVICE CHARGE: ' . number_format($cashBalance['service_charge'], 2);
        $lines[] = '  TOTAL CASH: ' . number_format($cashBalance['total_cash'], 2);

        if (!empty($serverSalesTips['servers'])) {
            $lines[] = str_repeat('-', 32);
            $lines[] = 'SERVER NAME (Sales & Tips):';
            foreach ($serverSalesTips['servers'] as $server) {
                $lines[] = '  ' . str_pad($server['name'], 20) . ' Sales ' . $server['sales'] . ', Tips ' . $server['tips'];
            }
            if (isset($serverSalesTips['totals'])) {
                $lines[] = '  ' . str_pad('TOTALS', 20) . ' Sales ' . $serverSalesTips['totals']['sales'] . ', Tips ' . $serverSalesTips['totals']['tips'];
            }
        }

        $lines[] = str_repeat('-', 32);
        $lines[] = '';
        $lines[] = str_pad('END OF REPORT', 32, ' ', STR_PAD_BOTH);

        return implode("\n", $lines);
    }

    /**
     * Format Z-Report for thermal printer
     */
    private function formatZReportForThermal(
        $businessName,
        $reportDate,
        $serverName,
        $salesSummary,
        $payments,
        $cashOut,
        $totalOwedToRestaurant,
        $totalTips,
        $suggestedTipOut,
        $serverSalesTips
    ) {
        // Generate report number: YEAR-DAYOFYEAR (e.g., 2025-307)
        $carbonDate = Carbon::parse($reportDate);
        $year = $carbonDate->format('Y');
        $dayOfYear = $carbonDate->format('z') + 1; // z is 0-based, so add 1
        $reportNumber = $year . '-' . str_pad($dayOfYear, 3, '0', STR_PAD_LEFT);

        $lines = [];
        $lines[] = str_pad($businessName, 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad('Z REPORT - ' . $reportNumber, 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad(Carbon::parse($reportDate)->format('m/d/Y'), 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad('PRINTED # ' . now()->format('m/d/Y h:i:s A'), 32, ' ', STR_PAD_BOTH);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'SALES SUMMARY:';
        $lines[] = 'CLOSED Orders:';
        $lines[] = '  Guests: ' . $salesSummary['closed_orders']['guests'];
        $lines[] = '  PPA: ' . number_format($salesSummary['closed_orders']['ppa'], 2);
        $lines[] = '  Net Sales: ' . number_format($salesSummary['closed_orders']['net_sales'], 2);
        $lines[] = '  Taxes: ' . number_format($salesSummary['closed_orders']['taxes'], 2);
        $lines[] = '  Service Cha: ' . number_format($salesSummary['closed_orders']['service_charge'], 2);
        $lines[] = '  Tips: ' . number_format($salesSummary['closed_orders']['tips'], 2);
        $lines[] = '  Fees: ' . number_format($salesSummary['closed_orders']['fees'], 2);
        $lines[] = '  Total: ' . number_format($salesSummary['closed_orders']['total'], 2);
        $lines[] = '';
        $lines[] = 'OPEN Orders:';
        $lines[] = '  Net Sales: ' . number_format($salesSummary['open_orders']['net_sales'], 2);
        $lines[] = '  Taxes: ' . number_format($salesSummary['open_orders']['taxes'], 2);
        $lines[] = '  Service Cha: ' . number_format($salesSummary['open_orders']['service_charge'], 2);
        $lines[] = '  Tips: ' . number_format($salesSummary['open_orders']['tips'], 2);
        $lines[] = '  Fees: ' . number_format($salesSummary['open_orders']['fees'], 2);
        $lines[] = '  Total: ' . number_format($salesSummary['open_orders']['total'], 2);
        $lines[] = '';
        $lines[] = 'Total Sales:';
        $lines[] = '  Guests: ' . $salesSummary['total_sales']['guests'];
        $lines[] = '  PPA: ' . number_format($salesSummary['total_sales']['ppa'], 2);
        $lines[] = '  Total Amount: ' . number_format($salesSummary['total_sales']['total_amount'], 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'PAYMENTS:';
        $lines[] = '  Cash: Qty ' . $payments['payments']['cash']['qty'] . ', Tips ' . number_format($payments['payments']['cash']['tips'], 2) . ', Total ' . number_format($payments['payments']['cash']['total'], 2);
        $lines[] = '  Checks: Qty 0, Tips 0.00, Total 0.00';
        $lines[] = '  Credit Cards E: Qty ' . $payments['payments']['card']['qty'] . ', Tips ' . number_format($payments['payments']['card']['tips'], 2) . ', Total ' . number_format($payments['payments']['card']['total'], 2);
        $lines[] = '  Totals: Tips ' . number_format($payments['totals']['tips'], 2) . ', Total ' . number_format($payments['totals']['total'], 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'Cash Out:';
        $lines[] = '  Credit Tips: ' . number_format($cashOut['credit_tips'], 2);
        $lines[] = '  Service Charge: ' . number_format($cashOut['service_charge'], 2);
        $lines[] = '  Cash On Hand: ' . number_format($cashOut['cash_on_hand'], 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'Total owed to RESTAURANT: ' . number_format($totalOwedToRestaurant, 2);
        $lines[] = '';
        $lines[] = 'Total Tips: ' . number_format($totalTips, 2);
        $lines[] = '';
        $lines[] = 'Suggested Tip Out:';
        foreach ($suggestedTipOut as $tipOut) {
            $lines[] = '  ' . $tipOut['role'] . ': ' . number_format($tipOut['percentage'], 2) . '% / ' . number_format($tipOut['base_amount'], 2) . ' | ' . number_format($tipOut['tip_out'], 2);
        }

        if (!empty($serverSalesTips['servers'])) {
            $lines[] = str_repeat('-', 32);
            $lines[] = 'SERVER NAME | SALES | TIPS:';
            foreach ($serverSalesTips['servers'] as $server) {
                $lines[] = '  ' . str_pad($server['name'], 20) . ' Sales ' . $server['sales'] . ', Tips ' . $server['tips'];
            }
            if (isset($serverSalesTips['totals'])) {
                $lines[] = '  ' . str_pad('TOTALS', 20) . ' Sales ' . $serverSalesTips['totals']['sales'] . ', Tips ' . $serverSalesTips['totals']['tips'];
            }
        }

        $lines[] = str_repeat('-', 32);
        $lines[] = '';
        $lines[] = str_pad('END OF REPORT', 32, ' ', STR_PAD_BOTH);

        return implode("\n", $lines);
    }

    /**
     * Generate PDF response for thermal format
     * For now, returns plain text. Can be enhanced with PDF library later.
     */
    private function generatePdfResponse($thermalFormat, $reportType, $reportDate)
    {
        // For now, return as text/plain with PDF-like headers
        // TODO: Install PDF library (e.g., barryvdh/laravel-dompdf) and generate actual PDF
        // For thermal printers, plain text is often preferred anyway

        return response($thermalFormat, 200)
            ->header('Content-Type', 'application/pdf')
            ->header('Content-Disposition', 'inline; filename="' . strtolower($reportType) . '-' . $reportDate . '.pdf"');
    }

    /**
     * Convert thermal format text to HTML format
     */
    private function convertThermalToHtml($thermalFormat, $businessName, $reportTitle = null)
    {
        $lines = explode("\n", $thermalFormat);
        $html = '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>' . htmlspecialchars($reportTitle ?? 'Report') . '</title>
    <style>
        body {
            font-family: monospace;
            background: #f4f4f4;
            padding: 20px;
        }
        .receipt {
            width: 380px;
            margin: auto;
            background: #fff;
            padding: 15px;
            border: 1px solid #ddd;
        }
        .center {
            text-align: center;
        }
        .line {
            border-top: 1px dashed #000;
            margin: 10px 0;
        }
        .section-title {
            font-weight: bold;
            margin-top: 10px;
        }
        .row {
            display: flex;
            justify-content: space-between;
            margin: 2px 0;
        }
        .footer {
            text-align: center;
            margin-top: 15px;
            font-weight: bold;
        }
    </style>
</head>
<body>
<div class="receipt">';

        $inHeader = true;
        $headerStarted = false;

        foreach ($lines as $index => $line) {
            $line = rtrim($line);
            $originalLine = $line;
            $trimmedLine = trim($line);

            // Skip empty lines at the start
            if ($inHeader && empty($trimmedLine)) {
                continue;
            }

            // Detect header section (centered lines with business name, report title, dates)
            if ($inHeader) {
                // Check if line is centered (padded with spaces) or contains header info
                $isCentered = (strlen($line) > 0 && preg_match('/^[\s]+.+\s+$/', $line)) ||
                    (strlen($trimmedLine) <= 32 && (
                        stripos($trimmedLine, $businessName) !== false ||
                        stripos($trimmedLine, 'REPORT') !== false ||
                        stripos($trimmedLine, 'BILL') !== false ||
                        preg_match('/\d{2}\/\d{2}\/\d{4}/', $trimmedLine) ||
                        preg_match('/\d{2}:\d{2}:\d{2}/', $trimmedLine)
                    ));

                if ($isCentered && !preg_match('/^[\-]+$/', $trimmedLine)) {
                    if (!$headerStarted) {
                        $html .= '<div class="center">';
                        $headerStarted = true;
                    }
                    if (stripos($trimmedLine, $businessName) !== false) {
                        $html .= '<h3>' . htmlspecialchars($trimmedLine) . '</h3>';
                    } elseif (stripos($trimmedLine, 'REPORT') !== false || stripos($trimmedLine, 'BILL') !== false) {
                        $html .= '<strong>' . htmlspecialchars($trimmedLine) . '</strong><br>';
                    } else {
                        $html .= '<div>' . htmlspecialchars($trimmedLine) . '</div>';
                    }
                    continue;
                }
            }

            // Close header when we hit a separator
            if ($inHeader && (strpos($line, str_repeat('-', 32)) !== false || preg_match('/^[\-]+$/', $trimmedLine))) {
                if ($headerStarted) {
                    $html .= '</div>';
                    $headerStarted = false;
                }
                $html .= '<div class="line"></div>';
                $inHeader = false;
                continue;
            }

            // Handle separator lines
            if (strpos($line, str_repeat('-', 32)) !== false || preg_match('/^[\-]+$/', $trimmedLine)) {
                $html .= '<div class="line"></div>';
                continue;
            }

            // Handle section titles (all caps, ends with colon)
            if (preg_match('/^[A-Z\s\/]+:$/', $trimmedLine)) {
                $html .= '<div class="section-title">' . htmlspecialchars($trimmedLine) . '</div>';
                continue;
            }

            // Handle lines with key: value format (e.g., "  Guests: 43")
            if (preg_match('/^[\s]*([^:]+):[\s]*(.+)$/', $line, $matches)) {
                $key = trim($matches[1]);
                $value = trim($matches[2]);
                $isBold = (stripos($key, 'total') !== false || stripos($key, 'end') !== false ||
                    stripos($key, 'TOTALS') !== false);
                $keyTag = $isBold ? '<strong>' : '<span>';
                $keyClose = $isBold ? '</strong>' : '</span>';
                $valueTag = $isBold ? '<strong>' : '<span>';
                $valueClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $keyTag . htmlspecialchars($key) . $keyClose . '<span>' . htmlspecialchars($value) . '</span></div>';
                continue;
            }

            // Handle lines with multiple values (e.g., "  Cash: QTY 0, Tips 0.00, Total 0.00")
            if (preg_match('/^[\s]*([^:]+):[\s]*(.+)$/', $line, $matches)) {
                $key = trim($matches[1]);
                $values = trim($matches[2]);
                $isBold = (stripos($key, 'total') !== false || stripos($key, 'TOTALS') !== false);
                $keyTag = $isBold ? '<strong>' : '<span>';
                $keyClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $keyTag . htmlspecialchars($key) . $keyClose . '<span>' . htmlspecialchars($values) . '</span></div>';
                continue;
            }

            // Handle lines with name and values (e.g., "  JAYESH NAKTE Sales 233.00, Tips 60.36")
            if (preg_match('/^[\s]*([A-Z\s]+)[\s]+(Sales|Tips|QTY|Total)[\s]+(.+)$/i', $line, $matches)) {
                $name = trim($matches[1]);
                $rest = trim(substr($line, strlen($matches[0]) - strlen($matches[3])));
                $isBold = (stripos($name, 'TOTALS') !== false);
                $nameTag = $isBold ? '<strong>' : '<span>';
                $nameClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $nameTag . htmlspecialchars($name) . $nameClose . '<span>' . htmlspecialchars($rest) . '</span></div>';
                continue;
            }

            // Handle lines with two parts separated by multiple spaces (left-right alignment)
            // This handles lines like "  CASH ON HAND: 1328.00" or "  TOTALS Sales 468.50, Tips 97.36"
            if (preg_match('/^[\s]*([^\s].*?)[\s]{2,}(.+)$/', $line, $matches)) {
                $left = trim($matches[1]);
                $right = trim($matches[2]);
                $isBold = (stripos($left, 'total') !== false || stripos($left, 'TOTALS') !== false ||
                    stripos($left, 'end') !== false);
                $leftTag = $isBold ? '<strong>' : '<span>';
                $leftClose = $isBold ? '</strong>' : '</span>';
                $rightTag = $isBold ? '<strong>' : '<span>';
                $rightClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $leftTag . htmlspecialchars($left) . $leftClose . $rightTag . htmlspecialchars($right) . $rightClose . '</div>';
                continue;
            }

            // Handle simple lines (centered footer, etc.)
            if (!empty($trimmedLine)) {
                if (stripos($trimmedLine, 'END') !== false && (stripos($trimmedLine, 'REPORT') !== false ||
                    stripos($trimmedLine, 'BILL') !== false)) {
                    $html .= '<div class="footer">' . htmlspecialchars($trimmedLine) . '</div>';
                } else {
                    $html .= '<div>' . htmlspecialchars($trimmedLine) . '</div>';
                }
            } else {
                $html .= '<br>';
            }
        }

        $html .= '</div>
</body>
</html>';

        return $html;
    }
}
