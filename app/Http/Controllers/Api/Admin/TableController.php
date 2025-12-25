<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\RestaurantTable;
use Illuminate\Http\Request;

class TableController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $tables = RestaurantTable::with(['floor', 'orders', 'reservations'])
            ->whereHas('floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $tables->items(),
            'total' => $tables->total(),
            'per_page' => $tables->perPage(),
            'current_page' => $tables->currentPage(),
            'last_page' => $tables->lastPage(),
        ], 'Tables retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'floor_id' => 'required|exists:floors,id',
            'name' => 'required|string|max:50',
            'size' => 'required|in:small,medium,large',
            'capacity' => 'required|integer|min:1',
            'status' => 'sometimes|string|max:50',
            'x_coordinates' => 'sometimes|nullable|numeric',
            'y_coordinates' => 'sometimes|nullable|numeric',
            'fire_status_pending' => 'sometimes|integer|in:0,1',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureFloorBelongsToBusiness($validated['floor_id'], $businessId);

        $table = RestaurantTable::create($validated);
        return $this->createdResponse($table, 'Table created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $this->ensureTableBelongsToBusiness($id, $businessId);

        $table = RestaurantTable::with(['floor', 'orders', 'reservations'])->find($id);

        return $this->successResponse($table, 'Table retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $table = $this->ensureTableBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'floor_id' => 'sometimes|required|exists:floors,id',
            'name' => 'sometimes|required|string|max:50',
            'size' => 'sometimes|required|in:small,medium,large',
            'capacity' => 'sometimes|required|integer|min:1',
            'status' => 'sometimes|string|max:50',
            'x_coordinates' => 'sometimes|nullable|numeric',
            'y_coordinates' => 'sometimes|nullable|numeric',
            'fire_status_pending' => 'sometimes|integer|in:0,1',
        ]);

        if (isset($validated['floor_id'])) {
            $this->ensureFloorBelongsToBusiness($validated['floor_id'], $businessId);
        }

        $table->update($validated);
        return $this->updatedResponse($table, 'Table updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $table = $this->ensureTableBelongsToBusiness($id, $businessId);

        $table->delete();
        return $this->deletedResponse('Table deleted successfully');
    }
}
