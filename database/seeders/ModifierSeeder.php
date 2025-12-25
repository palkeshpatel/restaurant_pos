<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\MenuItem;
use App\Models\Modifier;
use App\Models\ModifierGroup;
use Illuminate\Database\Seeder;

class ModifierSeeder extends Seeder
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

        $groupDefinitions = [
            'Protein Option' => [
                'min_select' => 1,
                'max_select' => 1,
                'modifiers' => [
                    ['name' => 'Chicken', 'price' => 0.00],
                    ['name' => 'Paneer', 'price' => 40.00],
                ],
            ],
            'Extra' => [
                'min_select' => 0,
                'max_select' => 1,
                'modifiers' => [
                    ['name' => 'paneer bhurji', 'price' => 10.00],
                    ['name' => 'cheese', 'price' => 40.00],
                ],
            ],
            'Add-ons' => [
                'min_select' => 0,
                'max_select' => 2,
                'modifiers' => [
                    ['name' => 'Mint Leaves', 'price' => 5.00],
                    ['name' => 'Lime Wedge', 'price' => 5.00],
                ],
            ],
            'Add-ons-cheese' => [
                'min_select' => 0,
                'max_select' => 2,
                'modifiers' => [
                    ['name' => 'Mint Leaves', 'price' => 5.00],
                    ['name' => 'Lime Wedge', 'price' => 5.00],
                    ['name' => 'Mint Leaves1', 'price' => 5.00],
                    ['name' => 'Lime Wedg2e', 'price' => 5.00],
                ],
            ],
        ];

        $groups = [];

        foreach ($groupDefinitions as $groupName => $config) {
            $group = ModifierGroup::updateOrCreate(
                [
                    'business_id' => $business->id,
                    'name' => $groupName,
                ],
                [
                    'min_select' => $config['min_select'],
                    'max_select' => $config['max_select'],
                ]
            );

            $groups[$groupName] = $group;

            foreach ($config['modifiers'] as $modifierData) {
                Modifier::updateOrCreate(
                    [
                        'business_id' => $business->id,
                        'group_id' => $group->id,
                        'name' => $modifierData['name'],
                    ],
                    [
                        'additional_price' => $modifierData['price'],
                    ]
                );
            }
        }

        $menuAssignments = [
            'Butter Chicken' => ['Protein Option'],
            'Dal Bukhara' => ['Topping Add-ons'],
            'Dhaba Ghosht' => ['Side Choice'],
            'Anarkali' => ['Glass Size'],
            'Krazy Keri' => ['Add-ons', 'Add-ons-cheese'],
        ];

        foreach ($menuAssignments as $itemName => $groupNames) {
            $menuItem = MenuItem::where('business_id', $business->id)
                ->where('name', $itemName)
                ->first();

            if (! $menuItem) {
                continue;
            }

            $groupIds = collect($groupNames)
                ->map(fn(string $name) => $groups[$name]->id ?? null)
                ->filter()
                ->all();

            if (! empty($groupIds)) {
                $menuItem->modifierGroups()->syncWithoutDetaching($groupIds);
            }
        }
    }
}