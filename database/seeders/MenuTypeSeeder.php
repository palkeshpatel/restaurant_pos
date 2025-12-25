<?php

namespace Database\Seeders;

use App\Models\MenuType;
use Illuminate\Database\Seeder;

class MenuTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $menuTypes = [
            ['name' => 'Main', 'description' => 'Main course items', 'is_active' => true],
            ['name' => 'Appetizer', 'description' => 'Appetizer items', 'is_active' => true],
            ['name' => 'Beverages', 'description' => 'Beverage items', 'is_active' => true],
            ['name' => 'Dessert', 'description' => 'Dessert items', 'is_active' => true],
            ['name' => 'Other', 'description' => 'Other menu items', 'is_active' => true],
        ];

        foreach ($menuTypes as $menuType) {
            MenuType::updateOrCreate(
                ['name' => $menuType['name']],
                $menuType
            );
        }

        $this->command->info('Menu types seeded successfully.');
    }
}