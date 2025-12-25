<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Business;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BusinessController extends BaseAdminController
{
    /**
     * Display a listing of the businesses.
     */
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);
        $business = Business::find($businessId);

        return $this->successResponse(
            $business ? [$business] : [],
            'Businesses retrieved successfully'
        );
    }

    /**
     * Store a newly created business in storage.
     */
    public function store(Request $request)
    {
        if (!$request->user()->is_super_admin) {
            return $this->forbiddenResponse('Only super admin can create businesses');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'llc_name' => 'nullable|string|max:255',
            'address' => 'nullable|string|max:500',
            'logo_url' => 'nullable|url|max:500',
            'timezone' => 'nullable|string|max:50',
            'auto_gratuity_percent' => 'nullable|numeric|min:0|max:100',
            'auto_gratuity_min_guests' => 'nullable|integer|min:1',
            'cc_fee_percent' => 'nullable|numeric|min:0|max:100',
        ]);

        $business = Business::create($validated);
        return $this->createdResponse($business, 'Business created successfully');
    }

    /**
     * Display the specified business.
     */
    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $business = Business::find($id);

        $this->assertModelBelongsToBusiness($business, $businessId, 'Business');

        return $this->successResponse($business, 'Business retrieved successfully');
    }

    /**
     * Update the specified business in storage.
     */
    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $business = Business::find($id);

        $this->assertModelBelongsToBusiness($business, $businessId, 'Business');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'llc_name' => 'nullable|string|max:255',
            'address' => 'nullable|string|max:500',
            'logo_url' => 'nullable|url|max:500',
            'timezone' => 'nullable|string|max:50',
            'auto_gratuity_percent' => 'nullable|numeric|min:0|max:100',
            'auto_gratuity_min_guests' => 'nullable|integer|min:1',
            'cc_fee_percent' => 'nullable|numeric|min:0|max:100',
        ]);

        $business->update($validated);
        return $this->updatedResponse($business, 'Business updated successfully');
    }

    /**
     * Remove the specified business from storage.
     */
    public function destroy(Request $request, $id)
    {
        if (!$request->user()->is_super_admin) {
            return $this->forbiddenResponse('Only super admin can delete businesses');
        }

        $business = Business::find($id);

        if (!$business) {
            return $this->notFoundResponse('Business not found');
        }

        $business->delete();
        return $this->deletedResponse('Business deleted successfully');
    }
}
