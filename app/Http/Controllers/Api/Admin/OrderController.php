<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Order;
use Illuminate\Http\Request;

class OrderController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $orders = Order::with(['table', 'createdByEmployee', 'checks', 'kitchenTickets'])
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse($orders, 'Orders retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'table_id' => 'required|exists:restaurant_tables,id',
            'created_by_employee_id' => 'required|exists:employees,id',
            'status' => 'sometimes|string|max:50',
            'notes' => 'nullable|string|max:1000',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureTableBelongsToBusiness($validated['table_id'], $businessId);
        $this->ensureEmployeeBelongsToBusiness($validated['created_by_employee_id'], $businessId);

        $order = Order::create([
            ...$validated,
            'business_id' => $businessId,
        ]);

        return $this->createdResponse($order->load(['table', 'createdByEmployee']), 'Order created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $this->ensureOrderBelongsToBusiness($id, $businessId);

        $order = Order::with(['table', 'createdByEmployee', 'checks', 'kitchenTickets'])->find($id);

        return $this->successResponse($order, 'Order retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $order = $this->ensureOrderBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'table_id' => 'sometimes|required|exists:restaurant_tables,id',
            'created_by_employee_id' => 'sometimes|required|exists:employees,id',
            'status' => 'sometimes|string|max:50',
            'notes' => 'nullable|string|max:1000',
        ]);

        if (isset($validated['table_id'])) {
            $this->ensureTableBelongsToBusiness($validated['table_id'], $businessId);
        }

        if (isset($validated['created_by_employee_id'])) {
            $this->ensureEmployeeBelongsToBusiness($validated['created_by_employee_id'], $businessId);
        }

        $order->update([
            ...$validated,
            'business_id' => $businessId,
        ]);
        return $this->updatedResponse($order->fresh(['table', 'createdByEmployee']), 'Order updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $order = $this->ensureOrderBelongsToBusiness($id, $businessId);

        $order->delete();
        return $this->deletedResponse('Order deleted successfully');
    }
}
