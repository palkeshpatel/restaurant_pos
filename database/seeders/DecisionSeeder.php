<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Decision;
use App\Models\DecisionGroup;
use App\Models\MenuItem;
use Illuminate\Database\Seeder;

class DecisionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $business = Business::first();

        if (! $business) {
            return;
        }

        // Only ONE decision group per business is allowed
        // This decision group can have multiple decisions
        $groupName = 'Ice Preference';
        
        $group = DecisionGroup::updateOrCreate(
            [
                'business_id' => $business->id,
                'name' => $groupName,
            ]
        );

        // Create multiple decisions for this single group
        $decisions = ['Regular', 'Light', 'None'];
        foreach ($decisions as $decisionName) {
            Decision::updateOrCreate(
                [
                    'business_id' => $business->id,
                    'group_id' => $group->id,
                    'name' => $decisionName,
                ]
            );
        }

        // Attach this decision group to the menu items
        $menuItems = MenuItem::where('business_id', $business->id)
            ->whereIn('name', ['Anarkali', 'Peach Please'])
            ->get();

        foreach ($menuItems as $menuItem) {
            $menuItem->decisionGroups()->sync([$group->id]);
        }
    }
}
