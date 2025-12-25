<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Menu;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\MenuType;
use Illuminate\Database\Seeder;

class MenuSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $business = Business::first();

        if (!$business) {
            return;
        }

        // Get menu types for assignment
        $menuTypes = MenuType::all()->keyBy('name');

        $menuStructure = [
            [
                'name' => 'MAIN MENU',
                'description' => 'Default restaurant offerings',
                'categories' => [
                    [
                        'name' => 'BEVERAGES',
                        'is_active' => true,
                        'children' => [
                            ['name' => 'MOCKTAILS', 'items' => $this->mocktailItems(), 'is_active' => true],
                            ['name' => 'SODA', 'is_active' => true],
                            ['name' => 'JUICE', 'is_active' => true],
                            ['name' => 'N/A BEER & LIQ', 'is_active' => true],
                            ['name' => 'COFFEE', 'is_active' => true],
                        ],
                    ],
                    [
                        'name' => 'FOOD',
                        'is_active' => true,
                        'children' => [
                            ['name' => 'CHOTA DHAMAAL', 'is_active' => true],
                            ['name' => 'BADA DHAMAAL', 'is_active' => true],
                            ['name' => 'CLASSICS', 'items' => $this->classicItems(), 'is_active' => true],
                            ['name' => 'MEETHA DHAMAAL', 'is_active' => true],
                            ['name' => 'BREAD', 'is_active' => true],
                            ['name' => 'PIZZA', 'is_active' => true],
                            ['name' => 'SIDE ONION / CHILI', 'is_active' => true],
                            ['name' => 'BEVERAGES', 'is_active' => true],
                            ['name' => 'FOOD', 'is_active' => true],
                            ['name' => 'OPEN ITEMS', 'is_active' => true],
                        ],
                    ],
                    [
                        'name' => 'OPEN ITEMS',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'TAKE AWAY',
                'description' => 'Take away offerings',
                'categories' => [
                    [
                        'name' => 'BEVERAGES',
                        'is_active' => true,
                        'children' => [
                            ['name' => 'MOCKTAILS', 'items' => $this->mocktailItems(), 'is_active' => true],
                            ['name' => 'SODA', 'is_active' => true],
                            ['name' => 'JUICE', 'is_active' => true],
                            ['name' => 'N/A BEER & LIQ', 'is_active' => true],
                            ['name' => 'COFFEE', 'is_active' => true],
                        ],
                    ],
                    [
                        'name' => 'FOOD',
                        'is_active' => false,
                        'children' => [
                            ['name' => 'CHOTA DHAMAAL', 'is_active' => false],
                            ['name' => 'BADA DHAMAAL', 'is_active' => false],
                            ['name' => 'CLASSICS', 'items' => $this->classicItems(), 'is_active' => false],
                            ['name' => 'MEETHA DHAMAAL', 'is_active' => false],
                            ['name' => 'BREAD', 'is_active' => false],
                            ['name' => 'PIZZA', 'is_active' => false],
                            ['name' => 'SIDE ONION / CHILI', 'is_active' => false],
                            ['name' => 'BEVERAGES', 'is_active' => false],
                            ['name' => 'FOOD', 'is_active' => false],
                            ['name' => 'OPEN ITEMS', 'is_active' => false],
                        ],
                    ],
                    [
                        'name' => 'OPEN ITEMS',
                        'is_active' => false,
                    ],
                ],
            ],
            [
                'name' => 'BRUNCH',
                'description' => 'Brunch offerings',
                'categories' => [
                    [
                        'name' => 'BEVERAGES',
                        'is_active' => true,
                        'children' => [
                            ['name' => 'MOCKTAILS', 'items' => $this->mocktailItems(), 'is_active' => true],
                            ['name' => 'SODA', 'is_active' => true],
                            ['name' => 'JUICE', 'is_active' => true],
                            ['name' => 'N/A BEER & LIQ', 'is_active' => true],
                            ['name' => 'COFFEE', 'is_active' => true],
                        ],
                    ],
                    [
                        'name' => 'FOOD',
                        'is_active' => false,
                        'children' => [
                            ['name' => 'CHOTA DHAMAAL', 'is_active' => false],
                            ['name' => 'BADA DHAMAAL', 'is_active' => false],
                            ['name' => 'CLASSICS', 'items' => $this->classicItems(), 'is_active' => false],
                            ['name' => 'MEETHA DHAMAAL', 'is_active' => false],
                            ['name' => 'BREAD', 'is_active' => false],
                            ['name' => 'PIZZA', 'is_active' => false],
                            ['name' => 'SIDE ONION / CHILI', 'is_active' => false],
                            ['name' => 'BEVERAGES', 'is_active' => false],
                            ['name' => 'FOOD', 'is_active' => false],
                            ['name' => 'OPEN ITEMS', 'is_active' => false],
                        ],
                    ],
                    [
                        'name' => 'OPEN ITEMS',
                        'is_active' => false,
                    ],
                ],
            ],
            [
                'name' => 'CATERING',
                'description' => 'Catering offerings',
                'categories' => [
                    [
                        'name' => 'BEVERAGES',
                        'is_active' => true,
                        'children' => [
                            ['name' => 'MOCKTAILS', 'items' => $this->mocktailItems(), 'is_active' => true],
                            ['name' => 'SODA', 'is_active' => true],
                            ['name' => 'JUICE', 'is_active' => true],
                            ['name' => 'N/A BEER & LIQ', 'is_active' => true],
                            ['name' => 'COFFEE', 'is_active' => true],
                        ],
                    ],
                    [
                        'name' => 'FOOD',
                        'is_active' => false,
                        'children' => [
                            ['name' => 'CHOTA DHAMAAL', 'is_active' => false],
                            ['name' => 'BADA DHAMAAL', 'is_active' => false],
                            ['name' => 'CLASSICS', 'items' => $this->classicItems(), 'is_active' => false],
                            ['name' => 'MEETHA DHAMAAL', 'is_active' => false],
                            ['name' => 'BREAD', 'is_active' => false],
                            ['name' => 'PIZZA', 'is_active' => false],
                            ['name' => 'SIDE ONION / CHILI', 'is_active' => false],
                            ['name' => 'BEVERAGES', 'is_active' => false],
                            ['name' => 'FOOD', 'is_active' => false],
                            ['name' => 'OPEN ITEMS', 'is_active' => false],
                        ],
                    ],
                    [
                        'name' => 'OPEN ITEMS',
                        'is_active' => false,
                    ],
                ],
            ],
        ];

        foreach ($menuStructure as $menuData) {
            $menu = Menu::updateOrCreate(
                ['business_id' => $business->id, 'name' => $menuData['name']],
                [
                    'description' => $menuData['description'] ?? '',
                    'image' => $menuData['image'] ?? '',
                    'icon_image' => $menuData['icon_image'] ?? '',
                    'is_active' => true,
                ]
            );

            if (empty($menuData['categories'])) {
                continue;
            }

            foreach ($menuData['categories'] as $categoryData) {
                $isBeverage = strtoupper($categoryData['name']) === 'BEVERAGES';
                $this->createCategoryTree($business->id, $menu->id, $categoryData, null, $isBeverage, $menuTypes);
            }
        }
    }

    private function createCategoryTree(int $businessId, int $menuId, array $data, MenuCategory $parentCategory = null, bool $isParentBeverage = false, $menuTypes = null): void
    {
        $category = MenuCategory::updateOrCreate(
            [
                'business_id' => $businessId,
                'menu_id' => $menuId,
                'name' => $data['name'],
                'parent_id' => $parentCategory?->id,
            ],
            [
                'description' => $data['description'] ?? '',
                'image' => $data['image'] ?? '',
                'icon_image' => $data['icon_image'] ?? '',
                'is_active' => $data['is_active'] ?? true,
            ]
        );

        // Check if this category is BEVERAGES or if parent is BEVERAGES
        $isBeverage = $isParentBeverage || strtoupper($data['name']) === 'BEVERAGES';

        // Get menu type ID based on category name
        $menuTypeId = $this->getMenuTypeId($data['name'], $menuTypes);

        foreach ($data['items'] ?? [] as $itemConfig) {
            $itemName = is_array($itemConfig) ? $itemConfig['name'] : $itemConfig;
            $priceCash = is_array($itemConfig) ? ($itemConfig['price_cash'] ?? 0) : 0;
            $priceCard = is_array($itemConfig) ? ($itemConfig['price_card'] ?? $priceCash) : $priceCash;
            // Item is active if category is active and item doesn't explicitly set is_active to false
            $itemIsActive = $category->is_active && (!isset($itemConfig['is_active']) || $itemConfig['is_active'] !== false);

            MenuItem::updateOrCreate(
                [
                    'business_id' => $businessId,
                    'menu_category_id' => $category->id,
                    'name' => $itemName,
                ],
                [
                    'menu_type_id' => $menuTypeId,
                    'price_cash' => $priceCash,
                    'price_card' => $priceCard,
                    'is_active' => $itemIsActive,
                    'is_auto_fire' => $isBeverage,
                ]
            );
        }

        foreach ($data['children'] ?? [] as $child) {
            $this->createCategoryTree($businessId, $menuId, $child, $category, $isBeverage, $menuTypes);
        }
    }

    private function classicItems(): array
    {
        return [
            ['name' => 'Dal Bukhara', 'price_cash' => 320, 'price_card' => 330],
            ['name' => 'Dal Frontier', 'price_cash' => 295, 'price_card' => 305],
            ['name' => 'Dal Tadka', 'price_cash' => 250, 'price_card' => 260],
            ['name' => 'Homestyle Chicken', 'price_cash' => 360, 'price_card' => 370],
            ['name' => 'Butter Chicken', 'price_cash' => 380, 'price_card' => 395],
            ['name' => 'Dhaba Ghosht', 'price_cash' => 410, 'price_card' => 425],
            ['name' => 'Goat Curry', 'price_cash' => 450, 'price_card' => 465],
            ['name' => 'Boom Boom Shrimp', 'price_cash' => 430, 'price_card' => 445],
            ['name' => 'Aloo Gobi', 'price_cash' => 240, 'price_card' => 250],
            ['name' => 'Paneer Lababdaar', 'price_cash' => 310, 'price_card' => 320],
        ];
    }

    private function mocktailItems(): array
    {
        return [
            ['name' => 'Anarkali', 'price_cash' => 210, 'price_card' => 220],
            ['name' => 'Bournvita Martini', 'price_cash' => 230, 'price_card' => 240],
            ['name' => 'Chatpata Limbu', 'price_cash' => 190, 'price_card' => 200],
            ['name' => 'Krazy Keri', 'price_cash' => 205, 'price_card' => 215],
            ['name' => 'Masti Queen', 'price_cash' => 225, 'price_card' => 235],
            ['name' => 'Mongo Cooler', 'price_cash' => 215, 'price_card' => 225],
            ['name' => 'Peach Please', 'price_cash' => 220, 'price_card' => 230],
            ['name' => 'Taaki Taaki', 'price_cash' => 200, 'price_card' => 210],
            ['name' => 'Corkage Fee', 'price_cash' => 150, 'price_card' => 150],
        ];
    }

    /**
     * Get menu type ID based on category name
     */
    private function getMenuTypeId(string $categoryName, $menuTypes): ?int
    {
        if (!$menuTypes) {
            return null;
        }

        $normalizedCategory = strtoupper(trim($categoryName));

        // Map categories to menu types (same mapping as MenuItemSeeder)
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
    }
}
