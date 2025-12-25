<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\GratuitySetting;
use Illuminate\Http\Request;

class GratuitySettingController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $gratuitySettings = GratuitySetting::with('business')
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse($gratuitySettings, 'Gratuity settings retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'gratuity_key' => 'required|in:Auto,Manual',
            'gratuity_type' => 'nullable|in:fixed_money,percentage',
            'gratuity_value' => 'nullable|integer|min:0',
        ]);

        $businessId = $this->currentBusinessId($request);

        if (GratuitySetting::where('business_id', $businessId)->exists()) {
            return $this->errorResponse('Gratuity setting already exists for this business', 422);
        }

        // If Manual gratuity, both type and value are required
        if ($validated['gratuity_key'] === 'Manual') {
            $request->validate([
                'gratuity_type' => 'required|in:fixed_money,percentage',
                'gratuity_value' => 'required|integer|min:0',
            ]);
        }

        $gratuitySetting = GratuitySetting::create([
            'business_id' => $businessId,
            ...$validated,
        ]);
        return $this->createdResponse($gratuitySetting->load('business'), 'Gratuity setting created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $gratuitySetting = GratuitySetting::with('business')->find($id);

        $this->assertModelBelongsToBusiness($gratuitySetting, $businessId, 'Gratuity setting');

        return $this->successResponse($gratuitySetting, 'Gratuity setting retrieved successfully');
    }

    public function getByBusiness(Request $request, $business_id)
    {
        $businessId = $this->currentBusinessId($request);

        if ((int) $business_id !== $businessId) {
            return $this->forbiddenResponse('You may only view gratuity settings for your own business');
        }

        $gratuitySetting = GratuitySetting::with('business')
            ->where('business_id', $businessId)
            ->first();

        if (!$gratuitySetting) {
            return $this->successResponse([
                'gratuity_key' => 'Auto',
                'gratuity_type' => null,
                'gratuity_value' => null,
            ], 'Default gratuity settings retrieved');
        }

        return $this->successResponse($gratuitySetting, 'Gratuity setting retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $gratuitySetting = GratuitySetting::find($id);

        $this->assertModelBelongsToBusiness($gratuitySetting, $businessId, 'Gratuity setting');

        $validated = $request->validate([
            'gratuity_key' => 'sometimes|required|in:Auto,Manual',
            'gratuity_type' => 'nullable|in:fixed_money,percentage',
            'gratuity_value' => 'nullable|integer|min:0',
        ]);

        // If Manual gratuity, both type and value are required
        if (isset($validated['gratuity_key']) && $validated['gratuity_key'] === 'Manual') {
            $request->validate([
                'gratuity_type' => 'required|in:fixed_money,percentage',
                'gratuity_value' => 'required|integer|min:0',
            ]);
        }

        $gratuitySetting->update($validated);
        return $this->updatedResponse($gratuitySetting->load('business'), 'Gratuity setting updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $gratuitySetting = GratuitySetting::find($id);

        $this->assertModelBelongsToBusiness($gratuitySetting, $businessId, 'Gratuity setting');

        $gratuitySetting->delete();
        return $this->deletedResponse('Gratuity setting deleted successfully');
    }
}