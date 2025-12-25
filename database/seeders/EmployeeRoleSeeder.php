<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Employee;
use App\Models\Role;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Faker\Factory as Faker;
use Illuminate\Support\Facades\URL;

class EmployeeRoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $businessId = 1;
        $faker = Faker::create();
        $avatarFiles = [
            'assets/img/avtar1.png',
            'assets/img/avtar2.png',
            'assets/img/avtar3.png',
        ];
        $localAvatar = fn() => URL::asset($avatarFiles[array_rand($avatarFiles)]);

        // Check if business exists
        $business = Business::find($businessId);
        if (!$business) {
            $this->command->error("Business with ID {$businessId} not found. Please create it first.");
            return;
        }

        // Get existing roles (Waiter and Manager)
        $waiterRole = Role::where('business_id', $businessId)->where('name', 'Waiter')->first();
        $managerRole = Role::where('business_id', $businessId)->where('name', 'Manager')->first();

        if (!$waiterRole || !$managerRole) {
            $this->command->error("Roles not found. Please run RoleSeeder first.");
            return;
        }

        // Create 5 Waiter employees
        for ($i = 1; $i <= 5; $i++) {
            $firstName = $faker->firstName();
            $lastName = $faker->lastName();
            $employee = Employee::firstOrCreate(
                ['email' => "waiter{$i}@nadiadrestaurant.com"],
                [
                    'business_id' => $businessId,
                    'first_name' => $firstName,
                    'last_name' => $lastName,
                    'email' => "waiter{$i}@nadiadrestaurant.com",
                    'pin4' => '1234',
                    'image' => '',
                    'avatar' => $localAvatar(),
                    'is_active' => true,
                ]
            );
            $employee->roles()->syncWithoutDetaching([$waiterRole->id => ['business_id' => $businessId]]);
        }

        // Create 2 Manager employees
        for ($i = 1; $i <= 2; $i++) {
            $firstName = $faker->firstName();
            $lastName = $faker->lastName();
            $employee = Employee::firstOrCreate(
                ['email' => "manager{$i}@nadiadrestaurant.com"],
                [
                    'business_id' => $businessId,
                    'first_name' => $firstName,
                    'last_name' => $lastName,
                    'email' => "manager{$i}@nadiadrestaurant.com",
                    'pin4' => '1234',
                    'image' => '',
                    'avatar' => $localAvatar(),
                    'is_active' => true,
                ]
            );
            $employee->roles()->syncWithoutDetaching([$managerRole->id => ['business_id' => $businessId]]);
        }

        $this->command->info('Employee roles seeded successfully!');
        $this->command->info('Created: 5 Waiters, 2 Managers');
    }
}