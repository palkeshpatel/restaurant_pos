<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\TaxRate;

class TaxRateSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $businessId = 1;

        // Only create food tax rate
        TaxRate::updateOrCreate(
            [
                'business_id' => $businessId,
                'applies_to' => 'food',
            ],
            [
                'name' => 'GST (Food)',
                'rate_percent' => 5.00,
            ]
        );
    }
}
