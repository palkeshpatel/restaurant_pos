<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\DiscountReason;
use Illuminate\Http\Request;

class DiscountReasonController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $reasons = DiscountReason::with('business')
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $reasons->items(),
            'total' => $reasons->total(),
            'per_page' => $reasons->perPage(),
            'current_page' => $reasons->currentPage(),
            'last_page' => $reasons->lastPage(),
        ], 'Discount reasons retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'requires_manager' => 'boolean',
        ]);

        $validated['business_id'] = $this->currentBusinessId($request);

        $reason = DiscountReason::create($validated);
        return $this->createdResponse($reason, 'Discount reason created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $reason = DiscountReason::with('business')->find($id);

        $this->assertModelBelongsToBusiness($reason, $businessId, 'Discount reason');

        return $this->successResponse($reason, 'Discount reason retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $reason = DiscountReason::find($id);

        $this->assertModelBelongsToBusiness($reason, $businessId, 'Discount reason');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'requires_manager' => 'boolean',
        ]);

        $validated['business_id'] = $businessId;

        $reason->update($validated);
        return $this->updatedResponse($reason, 'Discount reason updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $reason = DiscountReason::find($id);

        $this->assertModelBelongsToBusiness($reason, $businessId, 'Discount reason');

        $reason->delete();
        return $this->deletedResponse('Discount reason deleted successfully');
    }
}
