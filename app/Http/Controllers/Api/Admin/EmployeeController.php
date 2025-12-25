<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Employee;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class EmployeeController extends BaseAdminController
{
    /**
     * Display a listing of the employees.
     */
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $employees = Employee::with(['business', 'roles'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        // Return paginated response in the format expected by frontend
        return $this->successResponse([
            'data' => $employees->items(),
            'total' => $employees->total(),
            'per_page' => $employees->perPage(),
            'current_page' => $employees->currentPage(),
            'last_page' => $employees->lastPage(),
        ], 'Employees retrieved successfully');
    }

    /**
     * Store a newly created employee in storage.
     */
    public function store(Request $request)
    {
        // Clean up invalid avatar input (empty objects, empty arrays, etc.)
        if ($request->has('avatar') && !$request->hasFile('avatar')) {
            $avatarInput = $request->input('avatar');
            // If avatar is not a valid string (empty object, array, etc.), remove it
            if (!is_string($avatarInput) || trim($avatarInput) === '') {
                // Remove invalid avatar from request
                $request->request->remove('avatar');
            }
        }

        $validated = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'required|email|unique:employees,email',
            'pin4' => 'required|string|size:4',
            'avatar' => 'nullable|image|max:5120', // 5MB max
            'image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        $validated['business_id'] = $this->currentBusinessId($request);

        // Handle avatar file upload
        if ($request->hasFile('avatar')) {
            try {
                $file = $request->file('avatar');

                // Verify file is valid
                if (!$file->isValid()) {
                    return $this->errorResponse('Invalid file uploaded', 422);
                }

                // Store the file
                $path = $file->store('employees/avatars', 'public');

                // Verify file was stored
                if (!$path) {
                    return $this->errorResponse('Failed to store file', 500);
                }

                // Generate the public URL
                $relativeUrl = Storage::url($path);
                $appUrl = rtrim(config('app.url'), '/');
                $fullUrl = $appUrl . $relativeUrl;

                $validated['avatar'] = $fullUrl;
                Log::info('Avatar uploaded successfully', ['path' => $path, 'url' => $fullUrl]);
            } catch (\Exception $e) {
                Log::error('Avatar upload error in store: ' . $e->getMessage(), [
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                    'trace' => $e->getTraceAsString()
                ]);
                return $this->errorResponse('Failed to upload avatar: ' . $e->getMessage(), 500);
            }
        } elseif ($request->has('avatar') && is_string($request->input('avatar'))) {
            // If avatar is provided as a string (URL), use it directly
            $validated['avatar'] = $request->input('avatar');
        } elseif ($request->has('image') && is_string($request->input('image'))) {
            // Fallback: if image URL is provided, use it for avatar
            $validated['avatar'] = $request->input('image');
        }

        // Remove image from validated if it was used for avatar
        unset($validated['image']);

        $employee = Employee::create($validated);
        return $this->createdResponse($employee, 'Employee created successfully');
    }

    /**
     * Display the specified employee.
     */
    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $employee = Employee::with(['business', 'roles'])->find($id);

        $this->assertModelBelongsToBusiness($employee, $businessId, 'Employee');

        return $this->successResponse($employee, 'Employee retrieved successfully');
    }

    /**
     * Update the specified employee in storage.
     */
    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $employee = Employee::find($id);

        $this->assertModelBelongsToBusiness($employee, $businessId, 'Employee');

        // Debug: Log request info to see if file is being received
        Log::info('Employee update request', [
            'hasFile_avatar' => $request->hasFile('avatar'),
            'has_avatar' => $request->has('avatar'),
            'all_files' => array_keys($request->allFiles()),
            'content_type' => $request->header('Content-Type'),
        ]);

        // Clean up invalid avatar input (empty objects, empty arrays, etc.)
        if ($request->has('avatar') && !$request->hasFile('avatar')) {
            $avatarInput = $request->input('avatar');
            // If avatar is not a valid string (empty object, array, etc.), remove it
            if (!is_string($avatarInput) || trim($avatarInput) === '') {
                // Remove invalid avatar from request
                $request->request->remove('avatar');
            }
        }

        // Validate avatar separately - can be file OR string URL
        $avatarRules = 'nullable';
        if ($request->hasFile('avatar')) {
            $avatarRules = 'nullable|image|max:5120';
        } elseif ($request->has('avatar')) {
            $avatarRules = 'nullable|string|url|max:500';
        }

        $validated = $request->validate([
            'first_name' => 'sometimes|required|string|max:100',
            'last_name' => 'sometimes|required|string|max:100',
            'email' => 'sometimes|required|email|unique:employees,email,' . $id,
            'pin4' => 'nullable|string|size:4',
            'avatar' => $avatarRules,
            'image' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        // Remove pin4 from validated if it's empty (don't update PIN if not provided)
        if (isset($validated['pin4']) && empty($validated['pin4'])) {
            unset($validated['pin4']);
        }

        $validated['business_id'] = $businessId;

        // Handle avatar file upload
        if ($request->hasFile('avatar')) {
            try {
                // Delete old avatar file if exists
                if ($employee->avatar) {
                    $appUrl = rtrim(config('app.url'), '/');
                    // Only delete if it's a local file (not external URL)
                    if (strpos($employee->avatar, $appUrl) === 0) {
                        // Extract the path relative to storage
                        $relativeUrl = str_replace($appUrl, '', $employee->avatar);
                        $oldPath = str_replace('/storage/', '', $relativeUrl);
                        if (Storage::exists('public/' . $oldPath)) {
                            Storage::delete('public/' . $oldPath);
                        }
                    }
                }

                $file = $request->file('avatar');

                // Verify file is valid
                if (!$file->isValid()) {
                    return $this->errorResponse('Invalid file uploaded', 422);
                }

                // Store the file
                $path = $file->store('employees/avatars', 'public');

                // Verify file was stored
                if (!$path) {
                    return $this->errorResponse('Failed to store file', 500);
                }

                // Generate the public URL
                $relativeUrl = Storage::url($path);
                $appUrl = rtrim(config('app.url'), '/');
                $fullUrl = $appUrl . $relativeUrl;

                $validated['avatar'] = $fullUrl;
                Log::info('Avatar uploaded successfully in update', ['path' => $path, 'url' => $fullUrl]);
            } catch (\Exception $e) {
                Log::error('Avatar upload error in update: ' . $e->getMessage(), [
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                    'trace' => $e->getTraceAsString()
                ]);
                return $this->errorResponse('Failed to upload avatar: ' . $e->getMessage(), 500);
            }
        } elseif ($request->has('avatar') && is_string($request->input('avatar'))) {
            // If avatar is provided as a string (URL), use it directly
            $validated['avatar'] = $request->input('avatar');
        } elseif ($request->has('image') && is_string($request->input('image'))) {
            // Fallback: if image URL is provided, use it for avatar
            $validated['avatar'] = $request->input('image');
        }

        // Remove image from validated if it was used for avatar
        unset($validated['image']);

        $employee->update($validated);
        return $this->updatedResponse($employee, 'Employee updated successfully');
    }

    /**
     * Remove the specified employee from storage.
     */
    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $employee = Employee::find($id);

        $this->assertModelBelongsToBusiness($employee, $businessId, 'Employee');

        $employee->delete();
        return $this->deletedResponse('Employee deleted successfully');
    }

    /**
     * Assign roles to an employee.
     */
    public function assignRoles(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $employee = Employee::with('roles')->find($id);

        $this->assertModelBelongsToBusiness($employee, $businessId, 'Employee');

        $validated = $request->validate([
            'role_ids' => 'required|array',
            'role_ids.*' => 'exists:roles,id',
        ]);

        $roleIds = Role::where('business_id', $businessId)
            ->whereIn('id', $validated['role_ids'])
            ->pluck('id')
            ->all();

        $employee->roles()->syncWithPivotValues($roleIds, [
            'business_id' => $businessId,
        ]);

        return $this->successResponse($employee->load('roles'), 'Roles assigned successfully');
    }

    /**
     * Upload avatar for an employee
     */
    public function uploadAvatar(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $employee = Employee::find($id);

        if (!$employee) {
            return $this->notFoundResponse('Employee not found');
        }

        $this->assertModelBelongsToBusiness($employee, $businessId, 'Employee');

        $validated = $request->validate([
            'avatar' => 'required|image|max:5120', // 5MB max
        ]);

        try {
            // Delete old avatar file if exists
            if ($employee->avatar) {
                $appUrl = rtrim(config('app.url'), '/');
                // Only delete if it's a local file (not external URL)
                if (strpos($employee->avatar, $appUrl) === 0) {
                    // Extract the path relative to storage
                    $relativeUrl = str_replace($appUrl, '', $employee->avatar);
                    $oldPath = str_replace('/storage/', '', $relativeUrl);
                    if (Storage::exists('public/' . $oldPath)) {
                        Storage::delete('public/' . $oldPath);
                    }
                }
            }

            $file = $request->file('avatar');

            // Verify file is valid
            if (!$file->isValid()) {
                return $this->errorResponse('Invalid file uploaded', 422);
            }

            // Store the file
            $path = $file->store('employees/avatars', 'public');

            // Verify file was stored
            if (!$path) {
                return $this->errorResponse('Failed to store file', 500);
            }

            // Generate the public URL
            $relativeUrl = Storage::url($path);
            $appUrl = rtrim(config('app.url'), '/');
            $fullUrl = $appUrl . $relativeUrl;

            // Update employee with new avatar URL
            $employee->update(['avatar' => $fullUrl]);

            Log::info('Avatar uploaded successfully', ['path' => $path, 'url' => $fullUrl, 'employee_id' => $id]);

            return $this->successResponse([
                'avatar' => $fullUrl,
            ], 'Avatar uploaded successfully');
        } catch (\Exception $e) {
            Log::error('Avatar upload error: ' . $e->getMessage(), [
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Failed to upload avatar: ' . $e->getMessage(), 500);
        }
    }
}
