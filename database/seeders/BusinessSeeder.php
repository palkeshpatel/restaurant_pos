<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Business;

class BusinessSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Business::create([
            'name' => 'Nadiad City Restaurant',
            'llc_name' => 'Nadiad City Restaurant LLC',
            'address' => '123 Main Street, Nadiad, Gujarat, India',
            'logo_url' => 'https://example.com/logo.png',
            'timezone' => 'Asia/Kolkata',
            'auto_gratuity_percent' => 18.00,
            'auto_gratuity_min_guests' => 8,
            'cc_fee_percent' => 3.50,
        ]);
    }
}
