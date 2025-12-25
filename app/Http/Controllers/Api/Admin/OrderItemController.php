<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\OrderItem;
use Illuminate\Http\Request;

class OrderItemController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $orderItems = OrderItem::with(['order', 'check', 'menuItem', 'modifiers'])
            ->whereHas('check.order.table.floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->get();

        return $this->successResponse($orderItems, 'Order items retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'order_id' => 'required|exists:orders,id',
            'check_id' => 'required|exists:checks,id',
            'menu_item_id' => 'required|exists:menu_items,id',
            'qty' => 'required|integer|min:1',
            'unit_price' => 'required|numeric|min:0',
            'instructions' => 'nullable|string|max:500',
            'status' => 'nullable|string|max:50',
            'order_status' => 'nullable|integer|in:0,1,2,3',
        ]);

        $businessId = $this->currentBusinessId($request);
        $order = $this->ensureOrderBelongsToBusiness($validated['order_id'], $businessId);
        $check = $this->ensureCheckBelongsToBusiness($validated['check_id'], $businessId);

        if ((int) $check->order_id !== (int) $order->id) {
            return $this->errorResponse('Check does not belong to the specified order', 422);
        }

        $this->ensureMenuItemBelongsToBusiness($validated['menu_item_id'], $businessId);

        // Convert null instructions to empty string
        if (!isset($validated['instructions']) || $validated['instructions'] === null) {
            $validated['instructions'] = '';
        }

        $orderItem = OrderItem::create($validated);

        return $this->createdResponse($orderItem->load(['order', 'check', 'menuItem']), 'Order item created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $orderItem = $this->ensureOrderItemBelongsToBusiness($id, $businessId);

        $orderItem->load(['check', 'menuItem', 'modifiers']);

        return $this->successResponse($orderItem, 'Order item retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $orderItem = $this->ensureOrderItemBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'order_id' => 'sometimes|required|exists:orders,id',
            'check_id' => 'sometimes|required|exists:checks,id',
            'menu_item_id' => 'sometimes|required|exists:menu_items,id',
            'qty' => 'sometimes|required|integer|min:1',
            'unit_price' => 'sometimes|required|numeric|min:0',
            'instructions' => 'nullable|string|max:500',
            'status' => 'nullable|string|max:50',
        ]);

        $targetOrderId = $validated['order_id'] ?? $orderItem->order_id;
        $targetCheckId = $validated['check_id'] ?? $orderItem->check_id;

        $order = $this->ensureOrderBelongsToBusiness($targetOrderId, $businessId);
        $check = $this->ensureCheckBelongsToBusiness($targetCheckId, $businessId);

        if ((int) $check->order_id !== (int) $order->id) {
            return $this->errorResponse('Check does not belong to the specified order', 422);
        }

        $validated['order_id'] = $order->id;
        $validated['check_id'] = $check->id;

        if (isset($validated['menu_item_id'])) {
            $this->ensureMenuItemBelongsToBusiness($validated['menu_item_id'], $businessId);
        }

        // Convert null instructions to empty string
        if (isset($validated['instructions']) && $validated['instructions'] === null) {
            $validated['instructions'] = '';
        }

        $orderItem->update($validated);
        return $this->updatedResponse($orderItem->fresh(['order', 'check', 'menuItem']), 'Order item updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $orderItem = $this->ensureOrderItemBelongsToBusiness($id, $businessId);

        $orderItem->delete();
        return $this->deletedResponse('Order item deleted successfully');
    }
}
