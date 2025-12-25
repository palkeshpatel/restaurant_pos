<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Floor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FloorController extends BaseAdminController
{
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $floors = Floor::with(['business', 'tables'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $floors->items(),
            'total' => $floors->total(),
            'per_page' => $floors->perPage(),
            'current_page' => $floors->currentPage(),
            'last_page' => $floors->lastPage(),
        ], 'Floors retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'floor_type' => 'nullable|string|max:50',
            'width_px' => 'nullable|integer',
            'height_px' => 'nullable|integer',
            'background_image_url' => 'nullable|string|max:500',
        ]);

        $validated['business_id'] = $this->currentBusinessId($request);

        $floor = Floor::create($validated);
        return $this->createdResponse($floor, 'Floor created successfully');
    }

    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $floor = Floor::with(['business', 'tables'])->find($id);

        $this->assertModelBelongsToBusiness($floor, $businessId, 'Floor');

        return $this->successResponse($floor, 'Floor retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $floor = Floor::find($id);

        $this->assertModelBelongsToBusiness($floor, $businessId, 'Floor');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:100',
            'floor_type' => 'nullable|string|max:50',
            'width_px' => 'nullable|integer',
            'height_px' => 'nullable|integer',
            'background_image_url' => 'nullable|string|max:500',
        ]);

        $validated['business_id'] = $businessId;

        $floor->update($validated);
        return $this->updatedResponse($floor, 'Floor updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $floor = Floor::find($id);

        $this->assertModelBelongsToBusiness($floor, $businessId, 'Floor');

        $floor->delete();
        return $this->deletedResponse('Floor deleted successfully');
    }

    public function uploadBackground(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $floor = Floor::find($id);

        $this->assertModelBelongsToBusiness($floor, $businessId, 'Floor');

        $validated = $request->validate([
            'background_image' => 'required|image|max:10240', // 10MB max, accept any image type
        ]);

        // Delete old image if exists
        if ($floor->background_image_url) {
            $oldPath = str_replace(Storage::url(''), '', $floor->background_image_url);
            if (Storage::exists($oldPath)) {
                Storage::delete($oldPath);
            }
        }

        // Store the uploaded file
        $file = $request->file('background_image');
        $path = $file->store('floors/backgrounds', 'public');

        // Generate the public URL - use full URL with APP_URL
        $relativeUrl = Storage::url($path);
        $appUrl = rtrim(config('app.url'), '/');
        $fullUrl = $appUrl . $relativeUrl;

        // Update floor with new image URL (store full URL for cross-origin access)
        $floor->update(['background_image_url' => $fullUrl]);

        return $this->successResponse([
            'background_image_url' => $fullUrl,
        ], 'Background image uploaded successfully');
    }

    public function getBackgroundImage(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $floor = Floor::find($id);

        $this->assertModelBelongsToBusiness($floor, $businessId, 'Floor');

        if (!$floor->background_image_url) {
            return response()->json(['error' => 'No background image found'], 404);
        }

        // Extract the storage path from the URL
        $url = $floor->background_image_url;

        // Handle both full URL and relative URL
        if (strpos($url, '/storage/') !== false) {
            $path = str_replace(config('app.url'), '', $url);
            $path = ltrim($path, '/');
            $path = str_replace('storage/', '', $path);
            $storagePath = 'public/' . $path;
        } else {
            // If it's already a relative path
            $storagePath = 'public/' . ltrim(str_replace('/storage/', '', $url), '/');
        }

        if (!Storage::exists($storagePath)) {
            // Try alternative path format
            $altPath = 'floors/backgrounds/' . basename($url);
            if (Storage::exists('public/' . $altPath)) {
                $storagePath = 'public/' . $altPath;
            } else {
                return response()->json(['error' => 'Image file not found'], 404);
            }
        }

        $file = Storage::get($storagePath);
        $mimeType = Storage::mimeType($storagePath);

        return response($file, 200)
            ->header('Content-Type', $mimeType)
            ->header('Access-Control-Allow-Origin', '*')
            ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
            ->header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    }

    public function deleteBackground(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $floor = Floor::find($id);

        $this->assertModelBelongsToBusiness($floor, $businessId, 'Floor');

        if (!$floor->background_image_url) {
            return response()->json(['error' => 'No background image found'], 404);
        }

        // Extract the storage path from the URL
        $url = $floor->background_image_url;

        // Handle both full URL and relative URL
        if (strpos($url, '/storage/') !== false) {
            $path = str_replace(config('app.url'), '', $url);
            $path = ltrim($path, '/');
            $path = str_replace('storage/', '', $path);
            $storagePath = 'public/' . $path;
        } else {
            // If it's already a relative path
            $storagePath = 'public/' . ltrim(str_replace('/storage/', '', $url), '/');
        }

        // Delete the file if it exists
        if (Storage::exists($storagePath)) {
            Storage::delete($storagePath);
        }

        // Update floor to remove background image URL
        $floor->update(['background_image_url' => null]);

        return $this->successResponse(null, 'Background image removed successfully');
    }
}
