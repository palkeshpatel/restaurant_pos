<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Fee;
use Illuminate\Http\Request;

class FeeController extends BaseAdminController
{
    /**
     * Get fee for current business
     */
    public function show(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $fee = Fee::where('business_id', $businessId)->first();

        if (!$fee) {
            return $this->successResponse([
                'id' => null,
                'business_id' => $businessId,
                'fee_preset' => '0.00',
            ], 'Fee settings retrieved (default)');
        }

        return $this->successResponse($fee, 'Fee settings retrieved successfully');
    }

    /**
     * Create or update fee preset
     * Only one fee is allowed per business
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'fee_preset' => 'required|numeric|min:0',
        ]);

        $businessId = $this->currentBusinessId($request);

        // Update or create fee for this business
        $fee = Fee::updateOrCreate(
            [
                'business_id' => $businessId,
            ],
            [
                'business_id' => $businessId,
                'fee_preset' => $validated['fee_preset'],
            ]
        );

        return $this->createdResponse($fee, 'Fee preset saved successfully');
    }

    /**
     * Update fee preset
     */
    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $fee = Fee::where('id', $id)
            ->where('business_id', $businessId)
            ->first();

        if (!$fee) {
            return $this->notFoundResponse('Fee not found');
        }

        $validated = $request->validate([
            'fee_preset' => 'required|numeric|min:0',
        ]);

        $fee->update($validated);
        return $this->updatedResponse($fee, 'Fee preset updated successfully');
    }
}
