<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\MenuType;
use App\Models\MenuItem;
use Illuminate\Http\Request;

class MenuTypeController extends BaseAdminController
{
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);
        $businessId = $this->currentBusinessId($request);

        $menuTypes = MenuType::with(['menuItems' => function($query) use ($businessId) {
            $query->where('business_id', $businessId);
        }])
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $menuTypes->items(),
            'total' => $menuTypes->total(),
            'per_page' => $menuTypes->perPage(),
            'current_page' => $menuTypes->currentPage(),
            'last_page' => $menuTypes->lastPage(),
        ], 'Menu types retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:menu_types,name',
            'description' => 'required|string',
            'is_active' => 'boolean',
        ]);

        $menuType = MenuType::create($validated);
        return $this->createdResponse($menuType, 'Menu type created successfully');
    }

    public function show(Request $request, $id)
    {
        $menuType = MenuType::with('menuItems')->find($id);

        if (!$menuType) {
            return $this->notFoundResponse('Menu type not found');
        }

        return $this->successResponse($menuType, 'Menu type retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $menuType = MenuType::find($id);

        if (!$menuType) {
            return $this->notFoundResponse('Menu type not found');
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:100|unique:menu_types,name,' . $id,
            'description' => 'required|string',
            'is_active' => 'boolean',
        ]);

        $menuType->update($validated);
        return $this->updatedResponse($menuType, 'Menu type updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $menuType = MenuType::find($id);

        if (!$menuType) {
            return $this->notFoundResponse('Menu type not found');
        }

        // Check if menu type is being used by any menu items
        if ($menuType->menuItems()->count() > 0) {
            return $this->errorResponse('Cannot delete menu type. It is being used by menu items.', 422);
        }

        $menuType->delete();
        return $this->deletedResponse('Menu type deleted successfully');
    }

    /**
     * Update is_auto_fire for all menu items with this menu_type_id
     */
    public function updateAutoFire(Request $request, $id)
    {
        $menuType = MenuType::find($id);

        if (!$menuType) {
            return $this->notFoundResponse('Menu type not found');
        }

        $validated = $request->validate([
            'is_auto_fire' => 'required|boolean',
        ]);

        $businessId = $this->currentBusinessId($request);

        // Update all menu items with this menu_type_id for the current business
        $updated = MenuItem::where('menu_type_id', $id)
            ->where('business_id', $businessId)
            ->update(['is_auto_fire' => $validated['is_auto_fire'] ? 1 : 0]);

        return $this->successResponse([
            'menu_type_id' => $id,
            'is_auto_fire' => $validated['is_auto_fire'],
            'updated_count' => $updated,
        ], "Auto fire updated for {$updated} menu items");
    }
}
