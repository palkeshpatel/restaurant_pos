<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\TaxRate;
use App\Models\Fee;
use App\Models\GratuitySetting;
use Illuminate\Http\Request;

class SettingsController extends BaseAdminController
{
    /**
     * Get all configuration values (tax, fee, gratuity)
     */
    public function getConfig(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        // Get tax rate from tax_rates table (food)
        $taxValue = 0.00;
        $taxId = null;
        $taxName = '';
        $foodTaxRate = TaxRate::where('business_id', $businessId)
            ->where('applies_to', 'food')
            ->first();

        if ($foodTaxRate && $foodTaxRate->rate_percent > 0) {
            $taxValue = (float) $foodTaxRate->rate_percent;
            $taxId = $foodTaxRate->id;
            $taxName = $foodTaxRate->name;
        }

        // Get fee preset from fees table
        $feeValue = 0.00;
        $feeId = null;
        $fee = Fee::where('business_id', $businessId)->first();

        if ($fee && $fee->fee_preset > 0) {
            $feeValue = (float) $fee->fee_preset;
            $feeId = $fee->id;
        }

        // Get gratuity value from gratuity_settings table
        $gratuityValue = 0.00;
        $gratuityId = null;
        $gratuitySetting = GratuitySetting::where('business_id', $businessId)->first();

        if ($gratuitySetting && $gratuitySetting->gratuity_value > 0) {
            $gratuityValue = (float) $gratuitySetting->gratuity_value;
            $gratuityId = $gratuitySetting->id;
        }

        return $this->successResponse([
            'tax' => [
                'id' => $taxId,
                'value' => number_format($taxValue, 2, '.', ''),
                'name' => $taxName,
            ],
            'fee' => [
                'id' => $feeId,
                'value' => number_format($feeValue, 2, '.', ''),
            ],
            'gratuity' => [
                'id' => $gratuityId,
                'value' => number_format($gratuityValue, 2, '.', ''),
            ],
        ], 'Configuration data retrieved successfully');
    }

    /**
     * Update all configuration values (tax, fee, gratuity)
     */
    public function updateConfig(Request $request)
    {
        $validated = $request->validate([
            'tax_value' => 'required|numeric|min:0|max:100',
            'fee_value' => 'required|numeric|min:0',
            'gratuity_value' => 'required|numeric|min:0',
        ]);

        $businessId = $this->currentBusinessId($request);

        // Update or create tax rate
        $taxRate = TaxRate::updateOrCreate(
            [
                'business_id' => $businessId,
                'applies_to' => 'food',
            ],
            [
                'business_id' => $businessId,
                'name' => 'Food Tax',
                'rate_percent' => $validated['tax_value'],
                'applies_to' => 'food',
            ]
        );

        // Update or create fee
        $fee = Fee::updateOrCreate(
            [
                'business_id' => $businessId,
            ],
            [
                'business_id' => $businessId,
                'fee_preset' => $validated['fee_value'],
            ]
        );

        // Update or create gratuity setting
        $gratuitySetting = GratuitySetting::updateOrCreate(
            [
                'business_id' => $businessId,
            ],
            [
                'business_id' => $businessId,
                'gratuity_key' => 'Auto',
                'gratuity_type' => 'percentage',
                'gratuity_value' => (int) $validated['gratuity_value'],
            ]
        );

        return $this->successResponse([
            'tax' => [
                'id' => $taxRate->id,
                'value' => number_format((float) $taxRate->rate_percent, 2, '.', ''),
            ],
            'fee' => [
                'id' => $fee->id,
                'value' => number_format((float) $fee->fee_preset, 2, '.', ''),
            ],
            'gratuity' => [
                'id' => $gratuitySetting->id,
                'value' => number_format((float) $gratuitySetting->gratuity_value, 2, '.', ''),
            ],
        ], 'Configuration updated successfully');
    }
}