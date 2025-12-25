<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Shift;
use Illuminate\Http\Request;

class ShiftController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $shifts = Shift::with('employee')
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse($shifts, 'Shifts retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'clock_in_at' => 'required|date',
            'clock_out_at' => 'nullable|date|after:clock_in_at',
        ]);

        $businessId = $this->currentBusinessId($request);
        $this->ensureEmployeeBelongsToBusiness($validated['employee_id'], $businessId);

        $shift = Shift::create([
            ...$validated,
            'business_id' => $businessId,
        ]);

        return $this->createdResponse($shift->load('employee'), 'Shift created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $shift = $this->ensureShiftBelongsToBusiness($id, $businessId);

        $shift->load('employee');

        return $this->successResponse($shift, 'Shift retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $shift = $this->ensureShiftBelongsToBusiness($id, $businessId);

        $validated = $request->validate([
            'employee_id' => 'sometimes|required|exists:employees,id',
            'clock_in_at' => 'sometimes|required|date',
            'clock_out_at' => 'nullable|date|after:clock_in_at',
        ]);

        if (isset($validated['employee_id'])) {
            $this->ensureEmployeeBelongsToBusiness($validated['employee_id'], $businessId);
        }

        $shift->update([
            ...$validated,
            'business_id' => $businessId,
        ]);
        return $this->updatedResponse($shift->fresh('employee'), 'Shift updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $shift = $this->ensureShiftBelongsToBusiness($id, $businessId);

        $shift->delete();
        return $this->deletedResponse('Shift deleted successfully');
    }
}
