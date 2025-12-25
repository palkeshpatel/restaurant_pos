<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\DecisionGroup;
use Illuminate\Http\Request;

class DecisionGroupController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $decisionGroups = DecisionGroup::with(['decisions', 'menuItems'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $decisionGroups->items(),
            'total' => $decisionGroups->total(),
            'per_page' => $decisionGroups->perPage(),
            'current_page' => $decisionGroups->currentPage(),
            'last_page' => $decisionGroups->lastPage(),
        ], 'Decision groups retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
        ]);

        $businessId = $this->currentBusinessId($request);

        // Only ONE decision group per business is allowed
        $existingGroup = DecisionGroup::where('business_id', $businessId)->first();
        if ($existingGroup) {
            return $this->errorResponse('Only one decision group is allowed per business. A decision group already exists for this business.', 422);
        }

        $decisionGroup = DecisionGroup::create([
            'business_id' => $businessId,
            ...$validated,
        ]);

        return $this->createdResponse($decisionGroup, 'Decision group created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $decisionGroup = DecisionGroup::with(['decisions', 'menuItems'])->find($id);

        $this->assertModelBelongsToBusiness($decisionGroup, $businessId, 'Decision group');

        return $this->successResponse($decisionGroup, 'Decision group retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $decisionGroup = DecisionGroup::find($id);

        $this->assertModelBelongsToBusiness($decisionGroup, $businessId, 'Decision group');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
        ]);

        $decisionGroup->update($validated);
        return $this->updatedResponse($decisionGroup, 'Decision group updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $decisionGroup = DecisionGroup::find($id);

        $this->assertModelBelongsToBusiness($decisionGroup, $businessId, 'Decision group');

        $decisionGroup->delete();
        return $this->deletedResponse('Decision group deleted successfully');
    }
}
