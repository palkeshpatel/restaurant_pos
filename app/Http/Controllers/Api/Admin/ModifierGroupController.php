<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\ModifierGroup;
use Illuminate\Http\Request;

class ModifierGroupController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $modifierGroups = ModifierGroup::with(['modifiers', 'menuItems'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $modifierGroups->items(),
            'total' => $modifierGroups->total(),
            'per_page' => $modifierGroups->perPage(),
            'current_page' => $modifierGroups->currentPage(),
            'last_page' => $modifierGroups->lastPage(),
        ], 'Modifier groups retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'min_select' => 'nullable|integer|min:0',
            'max_select' => 'nullable|integer|min:0',
        ]);

        $modifierGroup = ModifierGroup::create([
            'business_id' => $this->currentBusinessId($request),
            ...$validated,
        ]);

        return $this->createdResponse($modifierGroup, 'Modifier group created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $modifierGroup = ModifierGroup::with(['modifiers', 'menuItems'])->find($id);

        $this->assertModelBelongsToBusiness($modifierGroup, $businessId, 'Modifier group');

        return $this->successResponse($modifierGroup, 'Modifier group retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $modifierGroup = ModifierGroup::find($id);

        $this->assertModelBelongsToBusiness($modifierGroup, $businessId, 'Modifier group');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'min_select' => 'nullable|integer|min:0',
            'max_select' => 'nullable|integer|min:0',
        ]);

        $modifierGroup->update($validated);
        return $this->updatedResponse($modifierGroup, 'Modifier group updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $modifierGroup = ModifierGroup::find($id);

        $this->assertModelBelongsToBusiness($modifierGroup, $businessId, 'Modifier group');

        $modifierGroup->delete();
        return $this->deletedResponse('Modifier group deleted successfully');
    }
}
