<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Menu;
use App\Models\MenuCategory;
use Illuminate\Http\Request;

class MenuCategoryController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $categories = MenuCategory::with(['business', 'menu', 'parent', 'children', 'menuItems'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $categories->items(),
            'total' => $categories->total(),
            'per_page' => $categories->perPage(),
            'current_page' => $categories->currentPage(),
            'last_page' => $categories->lastPage(),
        ], 'Menu categories retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'menu_id' => 'required|exists:menus,id',
            'parent_id' => 'nullable|exists:menu_categories,id',
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'image' => 'nullable|string|max:255',
            'icon_image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        $businessId = $this->currentBusinessId($request);

        $menu = Menu::where('id', $validated['menu_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$menu) {
            return $this->errorResponse('Menu does not belong to the specified business', 422);
        }

        if (!empty($validated['parent_id'])) {
            $parentCategory = MenuCategory::where('id', $validated['parent_id'])
                ->where('business_id', $businessId)
                ->where('menu_id', $validated['menu_id'])
                ->first();

            if (!$parentCategory) {
                return $this->errorResponse('Parent category must belong to the same business and menu', 422);
            }
        }

        $validated['business_id'] = $businessId;

        $category = MenuCategory::create($validated);
        return $this->createdResponse($category, 'Menu category created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $category = MenuCategory::with(['business', 'menu', 'parent', 'children', 'menuItems'])->find($id);

        $this->assertModelBelongsToBusiness($category, $businessId, 'Menu category');

        return $this->successResponse($category, 'Menu category retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $category = MenuCategory::find($id);

        $this->assertModelBelongsToBusiness($category, $businessId, 'Menu category');

        $validated = $request->validate([
            'menu_id' => 'sometimes|required|exists:menus,id',
            'parent_id' => 'nullable|exists:menu_categories,id',
            'name' => 'sometimes|required|string|max:255',
            'description' => 'required|string',
            'image' => 'nullable|string|max:255',
            'icon_image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        $menuId = $validated['menu_id'] ?? $category->menu_id;

        $menu = Menu::where('id', $menuId)
            ->where('business_id', $businessId)
            ->first();

        if (!$menu) {
            return $this->errorResponse('Menu does not belong to the specified business', 422);
        }

        if (!empty($validated['parent_id'])) {
            $parentCategory = MenuCategory::where('id', $validated['parent_id'])
                ->where('business_id', $businessId)
                ->where('menu_id', $menuId)
                ->first();

            if (!$parentCategory) {
                return $this->errorResponse('Parent category must belong to the same business and menu', 422);
            }
        }

        $validated['business_id'] = $businessId;
        $category->update($validated);
        return $this->updatedResponse($category, 'Menu category updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $category = MenuCategory::find($id);

        $this->assertModelBelongsToBusiness($category, $businessId, 'Menu category');

        // Check for child categories (sub-categories)
        $childCategories = $category->children()->get();
        
        // Check for menu items
        $menuItems = $category->menuItems()->get();

        // Build error message if there are children
        if ($childCategories->count() > 0 || $menuItems->count() > 0) {
            $childTitles = [];
            
            // Add sub-category names
            foreach ($childCategories as $child) {
                $childTitles[] = $child->name;
            }
            
            // Add menu item names
            foreach ($menuItems as $item) {
                $childTitles[] = $item->name;
            }

            $message = 'Sorry, you cannot delete this category. Please remove the following children first: ' . implode(', ', $childTitles);
            
            return $this->errorResponse($message, 422);
        }

        $category->delete();
        return $this->deletedResponse('Menu category deleted successfully');
    }
}
