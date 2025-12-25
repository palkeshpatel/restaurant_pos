<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Reservation;
use Illuminate\Http\Request;

class ReservationController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $reservations = Reservation::with(['business', 'table'])
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse($reservations, 'Reservations retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'table_id' => 'required|exists:restaurant_tables,id',
            'guest_name' => 'required|string|max:255',
            'party_size' => 'required|integer|min:1',
            'reservation_at' => 'required|date',
            'status' => 'nullable|string|max:50',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureTableBelongsToBusiness($validated['table_id'], $businessId);

        $validated['business_id'] = $businessId;

        $reservation = Reservation::create($validated);
        return $this->createdResponse($reservation, 'Reservation created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $reservation = Reservation::with(['business', 'table'])->find($id);

        $this->assertModelBelongsToBusiness($reservation, $businessId, 'Reservation');

        return $this->successResponse($reservation, 'Reservation retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $reservation = Reservation::find($id);

        $this->assertModelBelongsToBusiness($reservation, $businessId, 'Reservation');

        $validated = $request->validate([
            'table_id' => 'sometimes|required|exists:restaurant_tables,id',
            'guest_name' => 'sometimes|required|string|max:255',
            'party_size' => 'sometimes|required|integer|min:1',
            'reservation_at' => 'sometimes|required|date',
            'status' => 'nullable|string|max:50',
        ]);

        if (isset($validated['table_id'])) {
            $this->ensureTableBelongsToBusiness($validated['table_id'], $businessId);
        }

        $reservation->update($validated);
        return $this->updatedResponse($reservation, 'Reservation updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $reservation = Reservation::find($id);

        $this->assertModelBelongsToBusiness($reservation, $businessId, 'Reservation');

        $reservation->delete();
        return $this->deletedResponse('Reservation deleted successfully');
    }
}
