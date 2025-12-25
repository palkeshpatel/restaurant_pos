<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Decision;
use App\Models\DecisionGroup;
use Illuminate\Http\Request;

class DecisionController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $decisions = Decision::with(['group', 'business'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $decisions->items(),
            'total' => $decisions->total(),
            'per_page' => $decisions->perPage(),
            'current_page' => $decisions->currentPage(),
            'last_page' => $decisions->lastPage(),
        ], 'Decisions retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'group_id' => 'required|exists:decision_groups,id',
            'name' => 'required|string|max:255',
        ]);

        $businessId = $this->currentBusinessId($request);
        $group = $this->ensureDecisionGroupBelongsToBusiness($validated['group_id'], $businessId);

        $decision = Decision::create([
            'business_id' => $businessId,
            ...$validated,
        ]);

        return $this->createdResponse($decision, 'Decision created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $decision = Decision::with(['group', 'business'])->find($id);

        $this->assertModelBelongsToBusiness($decision, $businessId, 'Decision');

        return $this->successResponse($decision, 'Decision retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $decision = Decision::find($id);

        $this->assertModelBelongsToBusiness($decision, $businessId, 'Decision');

        $validated = $request->validate([
            'group_id' => 'sometimes|required|exists:decision_groups,id',
            'name' => 'sometimes|required|string|max:255',
        ]);

        if (isset($validated['group_id'])) {
            $this->ensureDecisionGroupBelongsToBusiness($validated['group_id'], $businessId);
        }

        $decision->update($validated);
        return $this->updatedResponse($decision, 'Decision updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $decision = Decision::find($id);

        $this->assertModelBelongsToBusiness($decision, $businessId, 'Decision');

        $decision->delete();
        return $this->deletedResponse('Decision deleted successfully');
    }

    protected function ensureDecisionGroupBelongsToBusiness(int $groupId, int $businessId): DecisionGroup
    {
        $group = DecisionGroup::find($groupId);

        if (!$group || (int) $group->business_id !== $businessId) {
            throw new \Illuminate\Http\Exceptions\HttpResponseException(
                $this->errorResponse('Decision group does not belong to the authenticated business', 422)
            );
        }

        return $group;
    }
}
