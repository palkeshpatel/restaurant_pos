<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Payment;
use Illuminate\Http\Request;

class PaymentController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $payments = Payment::with(['check', 'employee'])
            ->whereHas('check.order.table.floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->get();

        return $this->successResponse($payments, 'Payments retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'check_id' => 'required|exists:checks,id',
            'employee_id' => 'required|exists:employees,id',
            'method' => 'required|string|max:50',
            'amount' => 'required|numeric|min:0',
            'tip_amount' => 'nullable|numeric|min:0',
            'payment_date' => 'nullable|date',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureCheckBelongsToBusiness($validated['check_id'], $businessId);
        $this->ensureEmployeeBelongsToBusiness($validated['employee_id'], $businessId);

        $payment = Payment::create($validated);

        return $this->createdResponse($payment->load(['check', 'employee']), 'Payment created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $payment = $this->ensurePaymentBelongsToBusiness($id, $businessId);

        $payment->load(['check', 'employee']);

        return $this->successResponse($payment, 'Payment retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $payment = $this->ensurePaymentBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'check_id' => 'sometimes|required|exists:checks,id',
            'employee_id' => 'sometimes|required|exists:employees,id',
            'method' => 'sometimes|required|string|max:50',
            'amount' => 'sometimes|required|numeric|min:0',
            'tip_amount' => 'nullable|numeric|min:0',
            'payment_date' => 'nullable|date',
        ]);

        if (isset($validated['check_id'])) {
            $this->ensureCheckBelongsToBusiness($validated['check_id'], $businessId);
        }

        if (isset($validated['employee_id'])) {
            $this->ensureEmployeeBelongsToBusiness($validated['employee_id'], $businessId);
        }

        $payment->update($validated);
        return $this->updatedResponse($payment->fresh(['check', 'employee']), 'Payment updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $payment = $this->ensurePaymentBelongsToBusiness($id, $businessId);

        $payment->delete();
        return $this->deletedResponse('Payment deleted successfully');
    }
}
