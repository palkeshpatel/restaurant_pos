<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\TaxRate;
use Illuminate\Http\Request;

class TaxRateController extends BaseAdminController
{
    /**
     * Create or update food tax rate
     * Only one tax rate (food) is allowed per business
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'rate_percent' => 'required|numeric|min:0|max:100',
        ]);

        $businessId = $this->currentBusinessId($request);

        // Force applies_to to 'food' and ensure only one food tax rate exists
        $validated['business_id'] = $businessId;
        $validated['applies_to'] = 'food';

        // Update or create food tax rate for this business
        $taxRate = TaxRate::updateOrCreate(
            [
                'business_id' => $businessId,
                'applies_to' => 'food',
            ],
            $validated
        );

        return $this->createdResponse($taxRate, 'Tax rate saved successfully');
    }

    /**
     * Update food tax rate
     * Only food tax rate can be updated
     */
    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $taxRate = TaxRate::where('id', $id)
            ->where('business_id', $businessId)
            ->where('applies_to', 'food')
            ->first();

        if (!$taxRate) {
            return $this->notFoundResponse('Food tax rate not found');
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:100',
            'rate_percent' => 'sometimes|required|numeric|min:0|max:100',
        ]);

        // Ensure applies_to remains 'food'
        $validated['applies_to'] = 'food';

        $taxRate->update($validated);
        return $this->updatedResponse($taxRate, 'Tax rate updated successfully');
    }
}
