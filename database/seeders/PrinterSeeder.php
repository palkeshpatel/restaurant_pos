<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Printer;
use App\Models\PrinterRoute;

class PrinterSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $businessId = 1;

        // Create printers
        $printers = [
            [
                // 'id' => '550e8400-e29b-41d4-a716-446655440040',
                'business_id' => $businessId,
                'name' => 'Kitchen Printer 1',
                'ip_address' => '192.168.1.100',
                'is_kitchen' => true,
                'is_receipt' => false,
            ],
            [
                // 'id' => '550e8400-e29b-41d4-a716-446655440041',
                'business_id' => $businessId,
                'name' => 'Kitchen Printer 2',
                'ip_address' => '192.168.1.101',
                'is_kitchen' => true,
                'is_receipt' => false,
            ],
            [
                // 'id' => '550e8400-e29b-41d4-a716-446655440042',
                'business_id' => $businessId,
                'name' => 'Receipt Printer 1',
                'ip_address' => '192.168.1.102',
                'is_kitchen' => false,
                'is_receipt' => true,
            ],
            [
                // 'id' => '550e8400-e29b-41d4-a716-446655440043',
                'business_id' => $businessId,
                'name' => 'Receipt Printer 2',
                'ip_address' => '192.168.1.103',
                'is_kitchen' => false,
                'is_receipt' => true,
            ],
        ];

        $createdPrinters = [];
        foreach ($printers as $printerData) {
            $createdPrinters[] = Printer::create($printerData);
        }

        // Create printer routes using the created printer IDs
        $printerRoutes = [
            [
                'business_id' => $businessId,
                'name' => 'Main Kitchen Route',
                'printer_id' => $createdPrinters[0]->id,
            ],
            [
                'business_id' => $businessId,
                'name' => 'Secondary Kitchen Route',
                'printer_id' => $createdPrinters[1]->id,
            ],
            [
                'business_id' => $businessId,
                'name' => 'Main Receipt Route',
                'printer_id' => $createdPrinters[2]->id,
            ],
            [
                'business_id' => $businessId,
                'name' => 'Secondary Receipt Route',
                'printer_id' => $createdPrinters[3]->id,
            ],
        ];

        foreach ($printerRoutes as $routeData) {
            PrinterRoute::create($routeData);
        }
    }
}
