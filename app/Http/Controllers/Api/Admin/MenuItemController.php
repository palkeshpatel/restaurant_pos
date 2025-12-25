<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Menu;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\ModifierGroup;
use App\Models\DecisionGroup;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class MenuItemController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);
        $menuId = $request->input('menu_id');

        $query = MenuItem::with(['business', 'menu', 'menuCategory', 'menuType', 'printerRoute', 'modifierGroups', 'decisionGroups'])
            ->where('business_id', $businessId);

        // Filter by menu_id if provided
        if ($menuId) {
            // Filter by menu_id directly (new approach)
            // Include items with this menu_id OR items with no menu_id (NULL) but no category
            $query->where(function ($q) use ($menuId) {
                $q->where('menu_id', $menuId)
                    ->orWhere(function ($subQ) {
                        // Items with NULL menu_id and NULL menu_category_id (unassigned items)
                        $subQ->whereNull('menu_id')
                            ->whereNull('menu_category_id');
                    });
            });
        } else {
            // If no menu_id provided, show ONLY items with NULL menu_id and NULL menu_category_id
            // These are items not bound to any menu
            $query->whereNull('menu_id')
                ->whereNull('menu_category_id');
        }

        $menuItems = $query->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $menuItems->items(),
            'total' => $menuItems->total(),
            'per_page' => $menuItems->perPage(),
            'current_page' => $menuItems->currentPage(),
            'last_page' => $menuItems->lastPage(),
        ], 'Menu items retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'menu_id' => 'nullable|exists:menus,id',
            'menu_category_id' => 'nullable|exists:menu_categories,id',
            'menu_type_id' => 'nullable|exists:menu_types,id',
            'name' => 'required|string|max:255',
            'price_cash' => 'required|numeric|min:0',
            'price_card' => 'required|numeric|min:0',
            'image' => 'nullable|string|max:255',
            'icon_image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
            'is_auto_fire' => 'boolean',
            'printer_route_id' => 'nullable|exists:printer_routes,id',
        ]);

        $businessId = $this->currentBusinessId($request);

        // Validate menu_id if provided
        if (isset($validated['menu_id']) && $validated['menu_id']) {
            $menu = Menu::where('id', $validated['menu_id'])
                ->where('business_id', $businessId)
                ->first();

            if (!$menu) {
                return $this->errorResponse('Menu does not belong to the specified business', 422);
            }
        }

        // Only validate menu category if it's provided
        if (isset($validated['menu_category_id']) && $validated['menu_category_id']) {
            $menuCategory = MenuCategory::where('id', $validated['menu_category_id'])
                ->where('business_id', $businessId)
                ->first();

            if (!$menuCategory) {
                return $this->errorResponse('Menu category does not belong to the specified business', 422);
            }

            // If menu_id is not provided but menu_category_id is, get menu_id from category
            if (!isset($validated['menu_id']) || !$validated['menu_id']) {
                $validated['menu_id'] = $menuCategory->menu_id;
            }
        }

        $validated['business_id'] = $businessId;

        // Set is_open_item to true if both prices are 0
        $validated['is_open_item'] = ($validated['price_cash'] == 0 && $validated['price_card'] == 0);

        // Ensure image and icon_image are never null - use empty string
        if (!isset($validated['image']) || $validated['image'] === null) {
            $validated['image'] = '';
        }
        if (!isset($validated['icon_image']) || $validated['icon_image'] === null) {
            $validated['icon_image'] = '';
        }

        $menuItem = MenuItem::create($validated);
        return $this->createdResponse($menuItem, 'Menu item created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menuItem = MenuItem::with(['business', 'menu', 'menuCategory', 'menuType', 'printerRoute', 'modifierGroups', 'decisionGroups'])->find($id);

        $this->assertModelBelongsToBusiness($menuItem, $businessId, 'Menu item');

        return $this->successResponse($menuItem, 'Menu item retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menuItem = MenuItem::find($id);

        $this->assertModelBelongsToBusiness($menuItem, $businessId, 'Menu item');

        $validated = $request->validate([
            'menu_id' => 'nullable|exists:menus,id',
            'menu_category_id' => 'nullable|exists:menu_categories,id',
            'menu_type_id' => 'nullable|exists:menu_types,id',
            'name' => 'sometimes|required|string|max:255',
            'price_cash' => 'sometimes|required|numeric|min:0',
            'price_card' => 'sometimes|required|numeric|min:0',
            'image' => 'nullable|string|max:255',
            'icon_image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
            'is_auto_fire' => 'boolean',
            'printer_route_id' => 'nullable|exists:printer_routes,id',
        ]);

        // Validate menu_id if provided
        if (isset($validated['menu_id']) && $validated['menu_id']) {
            $menu = Menu::where('id', $validated['menu_id'])
                ->where('business_id', $businessId)
                ->first();

            if (!$menu) {
                return $this->errorResponse('Menu does not belong to the specified business', 422);
            }
        }

        // Only validate menu category if it's provided and not null
        if (isset($validated['menu_category_id']) && $validated['menu_category_id']) {
            $menuCategory = MenuCategory::where('id', $validated['menu_category_id'])
                ->where('business_id', $businessId)
                ->first();

            if (!$menuCategory) {
                return $this->errorResponse('Menu category does not belong to the specified business', 422);
            }

            // If menu_id is not provided but menu_category_id is, get menu_id from category
            if (!isset($validated['menu_id']) || !$validated['menu_id']) {
                $validated['menu_id'] = $menuCategory->menu_id;
            }
        }

        $validated['business_id'] = $businessId;

        // Set is_open_item to true if both prices are 0
        $priceCash = $validated['price_cash'] ?? $menuItem->price_cash;
        $priceCard = $validated['price_card'] ?? $menuItem->price_card;
        $validated['is_open_item'] = ($priceCash == 0 && $priceCard == 0);

        $menuItem->update($validated);
        return $this->updatedResponse($menuItem, 'Menu item updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menuItem = MenuItem::find($id);

        $this->assertModelBelongsToBusiness($menuItem, $businessId, 'Menu item');

        $menuItem->delete();
        return $this->deletedResponse('Menu item deleted successfully');
    }

    public function attachModifierGroups(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menuItem = MenuItem::find($id);

        if (!$menuItem) {
            return $this->errorResponse('Menu item not found', 404);
        }

        $this->assertModelBelongsToBusiness($menuItem, $businessId, 'Menu item');

        // Accept array (can be empty to clear associations)
        $validated = $request->validate([
            'modifier_group_ids' => 'array',
        ]);

        // Ensure it's always an array, default to empty if not provided
        $modifierGroupIds = $validated['modifier_group_ids'] ?? [];

        // Validate each ID exists only if array is not empty
        if (!empty($modifierGroupIds)) {
            $request->validate([
                'modifier_group_ids.*' => 'exists:modifier_groups,id',
            ]);
        }

        $groupIds = [];
        if (!empty($modifierGroupIds)) {
            $groupIds = ModifierGroup::where('business_id', $businessId)
                ->whereIn('id', $modifierGroupIds)
                ->pluck('id')
                ->all();

            if (count($groupIds) !== count($modifierGroupIds)) {
                return $this->errorResponse('All modifier groups must belong to the authenticated business', 422);
            }
        }

        // Frontend handles validation - automatically clear decision groups when attaching modifiers
        // Only detach if we're actually attaching something (not just clearing)
        if (!empty($groupIds)) {
            // Remove all existing associations first, then add new ones
            $menuItem->decisionGroups()->detach();
            $detachedCount = $menuItem->modifierGroups()->detach();

            Log::info('Attach Modifier Groups', [
                'menu_item_id' => $menuItem->id,
                'detached_count' => $detachedCount,
                'group_ids_to_attach' => $groupIds,
            ]);

            // Add new modifier groups
            $menuItem->modifierGroups()->attach($groupIds);

            // Verify data was saved to database
            $savedGroups = DB::table('menu_item_modifier_groups')
                ->where('menu_item_id', $menuItem->id)
                ->pluck('modifier_group_id')
                ->toArray();

            Log::info('Attached modifier groups', [
                'menu_item_id' => $menuItem->id,
                'group_ids_to_attach' => $groupIds,
                'saved_in_db' => $savedGroups,
            ]);
        } else {
            // If empty array, just clear modifier groups without touching decision groups
            $detachedCount = $menuItem->modifierGroups()->detach();
            Log::info('Cleared modifier groups (empty array)', [
                'menu_item_id' => $menuItem->id,
                'detached_count' => $detachedCount,
            ]);
        }

        // Refresh the model instance to ensure we get fresh data
        $menuItem->refresh();

        // Reload relationships to ensure fresh data
        $menuItem->load(['modifierGroups', 'decisionGroups']);

        // Ensure relationships are included in response (Laravel converts to snake_case in JSON)
        $responseData = $menuItem->toArray();
        $responseData['modifier_groups'] = $menuItem->modifierGroups->toArray();
        $responseData['decision_groups'] = $menuItem->decisionGroups->toArray();

        Log::info('After attach - modifier groups count', [
            'menu_item_id' => $menuItem->id,
            'modifier_groups_count' => $menuItem->modifierGroups->count(),
            'modifier_groups' => $menuItem->modifierGroups->pluck('id')->toArray(),
            'response_has_modifier_groups' => isset($responseData['modifier_groups']),
        ]);

        return $this->successResponse($responseData, 'Modifier groups attached successfully');
    }

    public function attachDecisionGroups(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $menuItem = MenuItem::find($id);

        if (!$menuItem) {
            return $this->errorResponse('Menu item not found', 404);
        }

        $this->assertModelBelongsToBusiness($menuItem, $businessId, 'Menu item');

        // Accept array (can be empty to clear associations)
        $validated = $request->validate([
            'decision_group_ids' => 'array',
        ]);

        // Ensure it's always an array, default to empty if not provided
        $decisionGroupIds = $validated['decision_group_ids'] ?? [];

        // Validate each ID exists only if array is not empty
        if (!empty($decisionGroupIds)) {
            $request->validate([
                'decision_group_ids.*' => 'exists:decision_groups,id',
            ]);
        }

        // Only ONE decision group per menu item is allowed
        if (count($decisionGroupIds) > 1) {
            return $this->errorResponse('Only one decision group is allowed per menu item.', 422);
        }

        $groupIds = [];
        if (!empty($decisionGroupIds)) {
            $groupIds = DecisionGroup::where('business_id', $businessId)
                ->whereIn('id', $decisionGroupIds)
                ->pluck('id')
                ->all();

            if (count($groupIds) !== count($decisionGroupIds)) {
                return $this->errorResponse('All decision groups must belong to the authenticated business', 422);
            }
        }

        // Frontend handles validation - automatically clear modifier groups when attaching decisions
        // Only detach if we're actually attaching something (not just clearing)
        if (!empty($groupIds)) {
            // Remove all existing associations first, then add new ones
            $menuItem->modifierGroups()->detach();
            $detachedCount = $menuItem->decisionGroups()->detach();

            Log::info('Attach Decision Groups', [
                'menu_item_id' => $menuItem->id,
                'detached_count' => $detachedCount,
                'group_ids_to_attach' => $groupIds,
            ]);

            // Add new decision groups
            $menuItem->decisionGroups()->attach($groupIds);

            // Verify data was saved to database
            $savedGroups = DB::table('menu_item_decision_groups')
                ->where('menu_item_id', $menuItem->id)
                ->pluck('decision_group_id')
                ->toArray();

            Log::info('Attached decision groups', [
                'menu_item_id' => $menuItem->id,
                'group_ids_to_attach' => $groupIds,
                'saved_in_db' => $savedGroups,
            ]);
        } else {
            // If empty array, just clear decision groups without touching modifier groups
            $detachedCount = $menuItem->decisionGroups()->detach();
            Log::info('Cleared decision groups (empty array)', [
                'menu_item_id' => $menuItem->id,
                'detached_count' => $detachedCount,
            ]);
        }

        // Refresh the model instance to ensure we get fresh data
        $menuItem->refresh();

        // Reload relationships to ensure fresh data
        $menuItem->load(['modifierGroups', 'decisionGroups']);

        // Ensure relationships are included in response (Laravel converts to snake_case in JSON)
        $responseData = $menuItem->toArray();
        $responseData['modifier_groups'] = $menuItem->modifierGroups->toArray();
        $responseData['decision_groups'] = $menuItem->decisionGroups->toArray();

        Log::info('After attach - decision groups count', [
            'menu_item_id' => $menuItem->id,
            'decision_groups_count' => $menuItem->decisionGroups->count(),
            'decision_groups' => $menuItem->decisionGroups->pluck('id')->toArray(),
            'response_has_decision_groups' => isset($responseData['decision_groups']),
        ]);

        return $this->successResponse($responseData, 'Decision groups attached successfully');
    }
}
