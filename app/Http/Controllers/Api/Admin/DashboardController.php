<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Employee;
use App\Models\Role;
use App\Models\Floor;
use App\Models\MenuType;
use App\Models\Menu;
use App\Models\ModifierGroup;
use App\Models\DecisionGroup;
use App\Models\MenuItem;
use Illuminate\Http\Request;

class DashboardController extends BaseAdminController
{
    public function getCounts(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        // Get menu items breakdown by menu
        $menus = Menu::where('business_id', $businessId)->get();
        $menuItemsBreakdown = [];
        foreach ($menus as $menu) {
            $menuItemsBreakdown[] = [
                'menu_id' => $menu->id,
                'menu_name' => $menu->name,
                'count' => MenuItem::where('business_id', $businessId)
                    ->where('menu_id', $menu->id)
                    ->count(),
            ];
        }

        $counts = [
            'employees' => Employee::where('business_id', $businessId)->count(),
            'roles' => Role::where('business_id', $businessId)->count(),
            'floors' => Floor::where('business_id', $businessId)->count(),
            'menu_types' => MenuType::count(), // Menu types are global, not per business
            'modifier_groups' => ModifierGroup::where('business_id', $businessId)->count(),
            'decision_groups' => DecisionGroup::where('business_id', $businessId)->count(),
            'menu_items_breakdown' => $menuItemsBreakdown,
            'menu_items_total' => MenuItem::where('business_id', $businessId)->count(),
        ];

        return $this->successResponse($counts, 'Dashboard counts retrieved successfully');
    }
}