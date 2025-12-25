<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Menu;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\MenuType;
use Illuminate\Database\Seeder;

class MenuItemSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * This seeder populates all menu items from Flutter app into the database.
     * It adds items to all categories that were created by MenuSeeder but don't have items yet.
     *
     * Prerequisites:
     * 1. BusinessSeeder must be run
     * 2. MenuSeeder must be run (creates categories)
     *
     * After running this seeder, all categories will have items and will appear in the API response.
     */
    public function run(): void
    {
        $business = Business::first();

        if (!$business) {
            $this->command->warn('No business found. Please seed Business first.');
            return;
        }

        // Get menus that need items seeded
        $menusToSeed = Menu::where('business_id', $business->id)
            ->whereIn('name', ['MAIN MENU', 'TAKE AWAY', 'BRUNCH', 'CATERING'])
            ->get();

        if ($menusToSeed->isEmpty()) {
            $this->command->warn('No menus found. Please run MenuSeeder first.');
            return;
        }

        // Get all categories from all menus (including nested ones)
        $allCategories = MenuCategory::where('business_id', $business->id)
            ->whereIn('menu_id', $menusToSeed->pluck('id'))
            ->get();

        // Helper function to find category by name in a specific menu
        $findCategoryInMenu = function ($categoryName, $menuCategories) {
            $normalizedName = strtoupper(trim($categoryName));

            // Special mapping for Flutter category names to Laravel category names
            $categoryMappings = [
                'OPEN SPECIALS' => 'OPEN ITEMS',
            ];

            if (isset($categoryMappings[$normalizedName])) {
                $normalizedName = $categoryMappings[$normalizedName];
            }

            // Try exact match first
            $category = $menuCategories->first(function ($cat) use ($normalizedName) {
                return strtoupper(trim($cat->name)) === $normalizedName;
            });

            if ($category) {
                return $category;
            }

            // Try partial matches (for cases like "SIDE ONION / CHILI" vs "SIDE ONION/CHILI")
            $category = $menuCategories->first(function ($cat) use ($normalizedName) {
                $catNameClean = str_replace(['/', ' ', '-'], '', strtoupper(trim($cat->name)));
                $normalizedClean = str_replace(['/', ' ', '-'], '', $normalizedName);
                return $catNameClean === $normalizedClean;
            });

            if ($category) {
                return $category;
            }

            // Try fuzzy match
            $category = $menuCategories->first(function ($cat) use ($normalizedName) {
                $catName = strtoupper(trim($cat->name));
                return str_contains($catName, $normalizedName) || str_contains($normalizedName, $catName);
            });

            return $category;
        };

        // Get menu types for assignment
        $menuTypes = MenuType::all()->keyBy('name');
        
        // Helper function to get menu type ID based on category name
        $getMenuTypeId = function ($categoryName) use ($menuTypes) {
            $normalizedCategory = strtoupper(trim($categoryName));
            
            // Map categories to menu types
            $categoryToTypeMap = [
                'CHOTA DHAMAAL' => 'Appetizer',
                'BADA DHAMAAL' => 'Main',
                'CLASSICS' => 'Main',
                'MEETHA DHAMAAL' => 'Dessert',
                'BREAD' => 'Other',
                'PIZZA' => 'Main',
                'SIDE ONION / CHILI' => 'Other',
                'SIDE ONION/CHILI' => 'Other',
                'OPEN SPECIALS' => 'Other',
                'OPEN ITEMS' => 'Other',
                'MOCKTAILS' => 'Beverages',
                'SODA' => 'Beverages',
                'JUICE' => 'Beverages',
                'N/A BEER & LIQ' => 'Beverages',
                'COFFEE' => 'Beverages',
            ];
            
            $menuTypeName = $categoryToTypeMap[$normalizedCategory] ?? 'Other';
            return $menuTypes->get($menuTypeName)?->id ?? null;
        };

        // All menu items from Flutter code
        $menuItems = $this->getAllMenuItems();

        $seededCount = 0;
        $skippedCount = 0;

        // Process items for each menu
        foreach ($menusToSeed as $menu) {
            $menuCategories = $allCategories->where('menu_id', $menu->id);
            
            foreach ($menuItems as $item) {
                // Find category in this specific menu
                $category = $findCategoryInMenu($item['category'], $menuCategories);

                if (!$category) {
                    // Skip if category not found in this menu
                    continue;
                }

                // Get menu type ID based on category
                $menuTypeId = $getMenuTypeId($item['category']);

                // Item is active if category is active
                $itemIsActive = $category->is_active;

                // Debug output for successful matches (only for first few)
                if ($seededCount < 5) {
                    $this->command->info("✓ Menu: {$menu->name} | Category: {$category->name} | Item: {$item['name']} | Active: " . ($itemIsActive ? 'Yes' : 'No'));
                }

                // Calculate price_card as price_cash + 10 (or same if specified)
                $priceCard = $item['price_card'] ?? ($item['price_cash'] + 10);

                MenuItem::updateOrCreate(
                    [
                        'business_id' => $business->id,
                        'menu_category_id' => $category->id,
                        'name' => $item['name'],
                    ],
                    [
                        'menu_id' => $menu->id,
                        'menu_type_id' => $menuTypeId,
                        'price_cash' => $item['price_cash'],
                        'price_card' => $priceCard,
                        'is_active' => $itemIsActive,
                        'is_auto_fire' => $item['is_auto_fire'] ?? false,
                    ]
                );

                $seededCount++;
            }
        }

        $this->command->info("\n=== Seeding Summary ===");
        $this->command->info("✓ Successfully seeded: {$seededCount} menu items");
        if ($skippedCount > 0) {
            $this->command->warn("⚠ Skipped: {$skippedCount} items (category not found)");
        }
        $this->command->info("=======================\n");
    }

    /**
     * Get all menu items from Flutter code
     */
    private function getAllMenuItems(): array
    {
        return [
            // CHOTA DHAMAAL (Appetizer)
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Ajwani Salmon Tikka', 'price_cash' => 120, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Chettinad Chicken', 'price_cash' => 125, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Chicken Malai Tikka', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Heirloom Tacos', 'price_cash' => 120, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Kale \'Pakora\'', 'price_cash' => 125, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Kolhapuri Murg Tikka', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Masala Mapu Tofu', 'price_cash' => 120, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Murg Tikka', 'price_cash' => 125, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Paneer Pinwheels', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CHOTA DHAMAAL', 'name' => 'Rawalpindi Channa Chaat', 'price_cash' => 115, 'is_auto_fire' => false],

            // BADA DHAMAAL (Main)
            ['category' => 'BADA DHAMAAL', 'name' => 'Saag Burata', 'price_cash' => 230, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => 'The Bharat\' Khichdi', 'price_cash' => 200, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => '\'Samvedi\' Baby Eggplant', 'price_cash' => 211, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => 'Jackfruit \'Koft\' Curry', 'price_cash' => 120, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => 'Kerala Pulao', 'price_cash' => 125, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => 'Duck Pepper Fry', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => '\'Kokam\' Branzino', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => 'Afghani lamb Chops', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BADA DHAMAAL', 'name' => 'Shirmp Gassi', 'price_cash' => 115, 'is_auto_fire' => false],

            // CLASSICS (Main) - Using Flutter prices as source
            ['category' => 'CLASSICS', 'name' => 'Dal Bukhara', 'price_cash' => 180, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Dal Frontier', 'price_cash' => 260, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Dal Tadka', 'price_cash' => 120, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Homestyle Chiken', 'price_cash' => 125, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Butter Chicken', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Dhaba Ghosht', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Goat Curry', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Boom Boom Shrimp', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Aloo Gobi', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'CLASSICS', 'name' => 'Paneer Lababdaar', 'price_cash' => 115, 'is_auto_fire' => false],

            // MEETHA DHAMAAL (Dessert)
            ['category' => 'MEETHA DHAMAAL', 'name' => 'Gulkanth Rose Kulfi', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'MEETHA DHAMAAL', 'name' => 'Mango Kulfi', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'MEETHA DHAMAAL', 'name' => 'Gulab Jamun Churros', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'MEETHA DHAMAAL', 'name' => 'Citafel Crumble', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'MEETHA DHAMAAL', 'name' => 'Chikoo Cloud Crumble', 'price_cash' => 115, 'is_auto_fire' => false],

            // BREAD
            ['category' => 'BREAD', 'name' => 'Arabic Naan', 'price_cash' => 120, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Butter Naan', 'price_cash' => 125, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Plain Naan', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Chilli Naan', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Garlic Naan', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Lacha Paratha', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Rosemary Naan', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Tandoori Roti', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'BREAD', 'name' => 'Variety Basket', 'price_cash' => 115, 'is_auto_fire' => false],

            // PIZZA
            ['category' => 'PIZZA', 'name' => 'Bombay Twist Pizza', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'PIZZA', 'name' => 'Chicken Tikka Pizza', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'PIZZA', 'name' => 'Chicken Kheema Pizza', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'PIZZA', 'name' => 'Kids Pizza', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'PIZZA', 'name' => 'Truffle Mushroom Pizza', 'price_cash' => 115, 'is_auto_fire' => false],

            // SIDE ONION / CHILI
            ['category' => 'SIDE ONION / CHILI', 'name' => 'Side Onions / Chili', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'SIDE ONION / CHILI', 'name' => 'Side Papad', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'SIDE ONION / CHILI', 'name' => 'Side Raita', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'SIDE ONION / CHILI', 'name' => 'Side Rice', 'price_cash' => 115, 'is_auto_fire' => false],
            ['category' => 'SIDE ONION / CHILI', 'name' => 'Plain Yogurt', 'price_cash' => 115, 'is_auto_fire' => false],

            // OPEN ITEMS / OPEN SPECIALS (Flutter uses "Open Specials", Laravel uses "OPEN ITEMS")
            ['category' => 'OPEN SPECIALS', 'name' => 'Open Food', 'price_cash' => 999, 'is_auto_fire' => false],
            ['category' => 'OPEN SPECIALS', 'name' => 'Open Beverage', 'price_cash' => 999, 'is_auto_fire' => false],
            ['category' => 'OPEN SPECIALS', 'name' => 'Party Payment', 'price_cash' => 999, 'is_auto_fire' => false],

            // MOCKTAILS (Beverages - is_auto_fire = true) - Using Flutter prices as source
            ['category' => 'MOCKTAILS', 'name' => 'Anarkali', 'price_cash' => 150, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Bournvita Martini', 'price_cash' => 160, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Chatpata Limbu', 'price_cash' => 120, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Krazy Keri', 'price_cash' => 130, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Masti Queen', 'price_cash' => 140, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Mongo Cooler', 'price_cash' => 150, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Peach Please', 'price_cash' => 155, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Taaki Taaki', 'price_cash' => 160, 'is_auto_fire' => true],
            ['category' => 'MOCKTAILS', 'name' => 'Corkage Fee', 'price_cash' => 100, 'is_auto_fire' => true],

            // SODA (Beverages - is_auto_fire = true)
            ['category' => 'SODA', 'name' => 'Sprite', 'price_cash' => 150, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Masala Soda', 'price_cash' => 160, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Thumbs up', 'price_cash' => 120, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Coke', 'price_cash' => 130, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Diet Coke', 'price_cash' => 140, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Limca', 'price_cash' => 150, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Masala Chai', 'price_cash' => 155, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Sparkling Water', 'price_cash' => 160, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Still Water', 'price_cash' => 100, 'is_auto_fire' => true],
            ['category' => 'SODA', 'name' => 'Seltzer', 'price_cash' => 120, 'is_auto_fire' => true],

            // JUICE (Beverages - is_auto_fire = true)
            ['category' => 'JUICE', 'name' => 'Apple Juice', 'price_cash' => 150, 'is_auto_fire' => true],
            ['category' => 'JUICE', 'name' => 'Cranberry', 'price_cash' => 160, 'is_auto_fire' => true],
            ['category' => 'JUICE', 'name' => 'Sweet Tea', 'price_cash' => 120, 'is_auto_fire' => true],
            ['category' => 'JUICE', 'name' => 'Unsweet Tea', 'price_cash' => 130, 'is_auto_fire' => true],

            // N/A BEER & LIQ (Beverages - is_auto_fire = true)
            ['category' => 'N/A BEER & LIQ', 'name' => 'NA Athletic IPA', 'price_cash' => 100, 'is_auto_fire' => true],
            ['category' => 'N/A BEER & LIQ', 'name' => 'Clausthaler Grapefruit', 'price_cash' => 120, 'is_auto_fire' => true],
            ['category' => 'N/A BEER & LIQ', 'name' => 'NA Heineken', 'price_cash' => 150, 'is_auto_fire' => true],
            ['category' => 'N/A BEER & LIQ', 'name' => 'NA Corona', 'price_cash' => 160, 'is_auto_fire' => true],
            ['category' => 'N/A BEER & LIQ', 'name' => 'NA Peroni Nastro', 'price_cash' => 120, 'is_auto_fire' => true],
            ['category' => 'N/A BEER & LIQ', 'name' => 'NA White Claw', 'price_cash' => 130, 'is_auto_fire' => true],

            // COFFEE (Beverages - is_auto_fire = true)
            ['category' => 'COFFEE', 'name' => 'Espresso', 'price_cash' => 130, 'is_auto_fire' => true],
        ];
    }
}