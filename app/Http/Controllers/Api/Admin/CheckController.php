<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Check;
use Illuminate\Http\Request;

class CheckController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $checks = Check::with(['order', 'orderItems', 'payments'])
            ->whereHas('order.table.floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->get();

        return $this->successResponse($checks, 'Checks retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'order_id' => 'required|exists:orders,id',
            'check_number' => 'required|string|max:50',
            'status' => 'sometimes|string|max:50',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureOrderBelongsToBusiness($validated['order_id'], $businessId);

        $check = Check::create($validated);

        return $this->createdResponse($check->load('order'), 'Check created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $this->ensureCheckBelongsToBusiness($id, $businessId);

        $check = Check::with(['order', 'orderItems', 'payments'])->find($id);

        return $this->successResponse($check, 'Check retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $check = $this->ensureCheckBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'order_id' => 'sometimes|required|exists:orders,id',
            'check_number' => 'sometimes|required|string|max:50',
            'status' => 'sometimes|string|max:50',
        ]);

        if (isset($validated['order_id'])) {
            $this->ensureOrderBelongsToBusiness($validated['order_id'], $businessId);
        }

        $check->update($validated);
        return $this->updatedResponse($check->fresh(['order']), 'Check updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $check = $this->ensureCheckBelongsToBusiness($id, $businessId);

        $check->delete();
        return $this->deletedResponse('Check deleted successfully');
    }
}
