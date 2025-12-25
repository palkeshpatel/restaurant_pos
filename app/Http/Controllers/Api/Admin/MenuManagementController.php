<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\MenuCategory;
use App\Models\MenuItem;
use Illuminate\Http\Request;

class MenuManagementController extends BaseAdminController
{
    /**
     * Toggle active status for category/sub-category
     */
    public function toggleCategoryStatus(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $category = MenuCategory::find($id);

        $this->assertModelBelongsToBusiness($category, $businessId, 'Menu category');

        // Use direct DB update to only change is_active, avoiding any model attribute issues
        $newStatus = !$category->is_active;
        MenuCategory::where('id', $id)
            ->where('business_id', $businessId)
            ->update(['is_active' => $newStatus]);

        // Refresh the model to get updated data
        $category->refresh();
        $category->is_active = $newStatus;

        return $this->successResponse($category, 'Category status updated successfully');
    }

    /**
     * Toggle active status for menu item
     */
    public function toggleMenuItemStatus(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menuItem = MenuItem::find($id);

        $this->assertModelBelongsToBusiness($menuItem, $businessId, 'Menu item');

        // Use direct DB update to only change is_active, avoiding any model attribute issues
        $newStatus = !$menuItem->is_active;
        MenuItem::where('id', $id)
            ->where('business_id', $businessId)
            ->update(['is_active' => $newStatus]);

        // Refresh the model to get updated data
        $menuItem->refresh();
        $menuItem->is_active = $newStatus;

        return $this->successResponse($menuItem, 'Menu item status updated successfully');
    }

    /**
     * Get all menu data for pad view (categories, sub-categories, items)
     */
    public function getMenuPadData(Request $request)
    {
        $businessId = $this->currentBusinessId($request);
        $menuId = $request->input('menu_id');

        if (!$menuId) {
            return $this->errorResponse('Menu ID is required', 422);
        }

        // Get all categories for the menu
        $allCategories = MenuCategory::where('menu_id', $menuId)
            ->where('business_id', $businessId)
            ->get();

        // Separate parent categories and sub-categories
        $categories = $allCategories->whereNull('parent_id')->values();
        $subCategories = $allCategories->whereNotNull('parent_id')->values();

        // Get all menu items for categories in this menu
        $categoryIds = $allCategories->pluck('id');
        $items = MenuItem::whereIn('menu_category_id', $categoryIds)
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse([
            'categories' => $categories,
            'sub_categories' => $subCategories,
            'items' => $items,
        ], 'Menu pad data retrieved successfully');
    }
}