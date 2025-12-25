<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $businessId = 1;

        // Check if business exists
        $business = Business::find($businessId);
        if (!$business) {
            $this->command->error("Business with ID {$businessId} not found. Please create it first.");
            return;
        }

        // Create only 2 roles: Waiter and Manager
        $waiterRole = Role::firstOrCreate(
            ['business_id' => $businessId, 'name' => 'Waiter'],
            ['business_id' => $businessId, 'name' => 'Waiter']
        );

        $managerRole = Role::firstOrCreate(
            ['business_id' => $businessId, 'name' => 'Manager'],
            ['business_id' => $businessId, 'name' => 'Manager']
        );

        $this->command->info('Roles seeded successfully!');
        $this->command->info('Created: Waiter, Manager');
    }
}

