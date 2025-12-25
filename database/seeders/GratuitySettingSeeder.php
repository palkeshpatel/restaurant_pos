<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\GratuitySetting;

class GratuitySettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        GratuitySetting::create([
            'business_id' => 1,
            'gratuity_key' => 'Auto',
            'gratuity_type' => 'percentage',
            'gratuity_value' => 10,
        ]);
    }
}