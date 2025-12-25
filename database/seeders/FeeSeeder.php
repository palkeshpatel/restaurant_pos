<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Fee;

class FeeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $businessId = 1;

        // Create fee preset for business
        Fee::updateOrCreate(
            [
                'business_id' => $businessId,
            ],
            [
                'fee_preset' => 2.00,
            ]
        );
    }
}