<?php

namespace App\Http\Controllers\Api\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class BusinessController extends Controller
{
    use ApiResponse;

    public function index()
    {
        $businesses = Business::all();
        return $this->successResponse($businesses, 'Businesses retrieved successfully');
    }

    public function store(Request $request)
    {
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

    public function show($id)
    {
        $business = Business::find($id);

        if (!$business) {
            return $this->notFoundResponse('Business not found');
        }

        return $this->successResponse($business, 'Business retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $business = Business::find($id);

        if (!$business) {
            return $this->notFoundResponse('Business not found');
        }

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

    public function destroy($id)
    {
        $business = Business::find($id);

        if (!$business) {
            return $this->notFoundResponse('Business not found');
        }

        $business->delete();
        return $this->deletedResponse('Business deleted successfully');
    }
}
