<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Modifier;
use Illuminate\Http\Request;

class ModifierController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $modifiers = Modifier::with(['group', 'orderItems'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $modifiers->items(),
            'total' => $modifiers->total(),
            'per_page' => $modifiers->perPage(),
            'current_page' => $modifiers->currentPage(),
            'last_page' => $modifiers->lastPage(),
        ], 'Modifiers retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'group_id' => 'required|exists:modifier_groups,id',
            'name' => 'required|string|max:255',
            'additional_price' => 'nullable|numeric|min:0',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureModifierGroupBelongsToBusiness($validated['group_id'], $businessId);

        $modifier = Modifier::create([
            ...$validated,
            'business_id' => $businessId,
        ]);
        return $this->createdResponse($modifier, 'Modifier created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $modifier = $this->ensureModifierBelongsToBusiness($id, $businessId);

        $modifier->load(['group', 'orderItems']);

        return $this->successResponse($modifier, 'Modifier retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $modifier = $this->ensureModifierBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'group_id' => 'sometimes|required|exists:modifier_groups,id',
            'name' => 'sometimes|required|string|max:255',
            'additional_price' => 'nullable|numeric|min:0',
        ]);

        if (isset($validated['group_id'])) {
            $this->ensureModifierGroupBelongsToBusiness($validated['group_id'], $businessId);
        }

        $modifier->update([
            ...$validated,
            'business_id' => $businessId,
        ]);
        return $this->updatedResponse($modifier, 'Modifier updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $modifier = $this->ensureModifierBelongsToBusiness($id, $businessId);

        $modifier->delete();
        return $this->deletedResponse('Modifier deleted successfully');
    }
}
