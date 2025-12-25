<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Floor;
use App\Models\RestaurantTable;

class FloorTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $businessId = 1;

        // Create floors
        $groundFloor = Floor::create([
            'business_id' => $businessId,
            'name' => 'Ground Floor',
            'floor_type' => 'indoor',
            'width_px' => 1200,
            'height_px' => 800,
        ]);

        $firstFloor = Floor::create([
            'business_id' => $businessId,
            'name' => 'First Floor',
            'floor_type' => 'indoor',
            'width_px' => 1200,
            'height_px' => 800,
        ]);

        $outdoorFloor = Floor::create([
            'business_id' => $businessId,
            'name' => 'Outdoor Seating',
            'floor_type' => 'outdoor',
            'width_px' => 1000,
            'height_px' => 600,
        ]);

        // Create tables for Ground Floor
        $groundFloorId = $groundFloor->id;

        // Small tables (8 tables)
        $smallTables = [
            ['name' => 'T1', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 30, 'y_coordinates' => 240],
            ['name' => 'T2', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 30, 'y_coordinates' => 320],
            ['name' => 'T3', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 30, 'y_coordinates' => 400],
            ['name' => 'T4', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 30, 'y_coordinates' => 480],
            ['name' => 'T5', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 720, 'y_coordinates' => 240],
            ['name' => 'T6', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 720, 'y_coordinates' => 320],
            ['name' => 'T7', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 720, 'y_coordinates' => 400],
            ['name' => 'T8', 'size' => 'small', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 720, 'y_coordinates' => 480],
        ];

        // Large tables (16 tables) - IDs 9-24
        $largeTables = [
            ['name' => 'T9', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 160, 'y_coordinates' => 150],
            ['name' => 'T10', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 150],
            ['name' => 'T11', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 440, 'y_coordinates' => 150],
            ['name' => 'T12', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 580, 'y_coordinates' => 150],
            ['name' => 'T13', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 160, 'y_coordinates' => 300],
            ['name' => 'T14', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 300],
            ['name' => 'T15', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 440, 'y_coordinates' => 300],
            ['name' => 'T16', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 580, 'y_coordinates' => 300],
            ['name' => 'T17', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 160, 'y_coordinates' => 460],
            ['name' => 'T18', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 460],
            ['name' => 'T19', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 440, 'y_coordinates' => 460],
            ['name' => 'T20', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 580, 'y_coordinates' => 460],
            ['name' => 'T21', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 160, 'y_coordinates' => 620],
            ['name' => 'T22', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 620],
            ['name' => 'T23', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 440, 'y_coordinates' => 620],
            ['name' => 'T24', 'size' => 'large', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 580, 'y_coordinates' => 620],
        ];

        // Medium tables (10 tables) - IDs 25-34
        $mediumTables = [
            ['name' => 'T25', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 160, 'y_coordinates' => 20],
            ['name' => 'T26', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 20],
            ['name' => 'T27', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 450, 'y_coordinates' => 20],
            ['name' => 'T28', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 590, 'y_coordinates' => 20],
            ['name' => 'T29', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 160, 'y_coordinates' => 800],
            ['name' => 'T30', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 310, 'y_coordinates' => 800],
            ['name' => 'T31', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 460, 'y_coordinates' => 800],
            ['name' => 'T32', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 600, 'y_coordinates' => 800],
            ['name' => 'T33', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 900],
            ['name' => 'T34', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 460, 'y_coordinates' => 900],
        ];

        // Create all tables
        $allTables = array_merge($smallTables, $largeTables, $mediumTables);

        foreach ($allTables as $tableData) {
            RestaurantTable::create([
                'floor_id' => $groundFloorId,
                'name' => $tableData['name'],
                'size' => $tableData['size'],
                'capacity' => $tableData['capacity'],
                'status' => $tableData['status'],
                'x_coordinates' => $tableData['x_coordinates'],
                'y_coordinates' => $tableData['y_coordinates'],
            ]);
        }

        // Create tables for First Floor
        $firstFloorId = $firstFloor->id;
        $firstFloorTables = [
            ['name' => 'T9', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 100, 'y_coordinates' => 200],
            ['name' => 'T10', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 200, 'y_coordinates' => 200],
            ['name' => 'T11', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 200],
            ['name' => 'T12', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 100, 'y_coordinates' => 400],
            ['name' => 'T13', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 200, 'y_coordinates' => 400],
            ['name' => 'T14', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 300, 'y_coordinates' => 400],
        ];

        foreach ($firstFloorTables as $tableData) {
            RestaurantTable::create([
                'floor_id' => $firstFloorId,
                'name' => $tableData['name'],
                'size' => $tableData['size'],
                'capacity' => $tableData['capacity'],
                'status' => $tableData['status'],
                'x_coordinates' => $tableData['x_coordinates'],
                'y_coordinates' => $tableData['y_coordinates'],
            ]);
        }

        // Create tables for Outdoor
        $outdoorFloorId = $outdoorFloor->id;
        $outdoorTables = [
            ['name' => 'O1', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 100, 'y_coordinates' => 150],
            ['name' => 'O2', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 200, 'y_coordinates' => 150],
            ['name' => 'O3', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 100, 'y_coordinates' => 300],
            ['name' => 'O4', 'size' => 'medium', 'capacity' => 10, 'status' => 'available', 'x_coordinates' => 200, 'y_coordinates' => 300],
        ];

        foreach ($outdoorTables as $tableData) {
            RestaurantTable::create([
                'floor_id' => $outdoorFloorId,
                'name' => $tableData['name'],
                'size' => $tableData['size'],
                'capacity' => $tableData['capacity'],
                'status' => $tableData['status'],
                'x_coordinates' => $tableData['x_coordinates'],
                'y_coordinates' => $tableData['y_coordinates'],
            ]);
        }
    }
}