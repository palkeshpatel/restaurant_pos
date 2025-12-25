<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            BusinessSeeder::class,
            RoleSeeder::class,
            EmployeeSeeder::class,
            EmployeeRoleSeeder::class,
            MenuTypeSeeder::class,
            MenuSeeder::class,
            MenuItemSeeder::class,
            ModifierSeeder::class,
            DecisionSeeder::class,
            FloorTableSeeder::class,
            TaxRateSeeder::class,
            FeeSeeder::class,
            PrinterSeeder::class,
            GratuitySettingSeeder::class,
        ]);

        $business = Business::first();

        if ($business) {
            User::updateOrCreate(
                ['email' => 'admin@nadiadrestaurant.com'],
                [
                    'business_id' => $business->id,
                    'name' => 'Restaurant Admin',
                    'password' => Hash::make('password'),
                    'is_super_admin' => false,
                ]
            );
        }

        User::updateOrCreate(
            ['email' => 'superadmin@system.com'],
            [
                'business_id' => null,
                'name' => 'Super Admin',
                'password' => Hash::make('password'),
                'is_super_admin' => true,
            ]
        );
    }
}
