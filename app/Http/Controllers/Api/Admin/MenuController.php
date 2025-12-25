<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Menu;
use Illuminate\Http\Request;

class MenuController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $menus = Menu::with(['business', 'categories.children', 'categories.menuItems'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $menus->items(),
            'total' => $menus->total(),
            'per_page' => $menus->perPage(),
            'current_page' => $menus->currentPage(),
            'last_page' => $menus->lastPage(),
        ], 'Menus retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|string|max:255',
            'icon_image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        $validated['business_id'] = $this->currentBusinessId($request);

        $menu = Menu::create($validated);
        return $this->createdResponse($menu, 'Menu created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menu = Menu::with(['business', 'categories.children', 'categories.menuItems'])->find($id);

        $this->assertModelBelongsToBusiness($menu, $businessId, 'Menu');

        return $this->successResponse($menu, 'Menu retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menu = Menu::find($id);

        $this->assertModelBelongsToBusiness($menu, $businessId, 'Menu');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|string|max:255',
            'icon_image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        $validated['business_id'] = $businessId;

        $menu->update($validated);
        return $this->updatedResponse($menu, 'Menu updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menu = Menu::find($id);

        $this->assertModelBelongsToBusiness($menu, $businessId, 'Menu');

        $menu->delete();
        return $this->deletedResponse('Menu deleted successfully');
    }
}
