<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Permission;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class PermissionController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $permissions = Permission::with('roles')
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $permissions->items(),
            'total' => $permissions->total(),
            'per_page' => $permissions->perPage(),
            'current_page' => $permissions->currentPage(),
            'last_page' => $permissions->lastPage(),
        ], 'Permissions retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|max:100|unique:permissions,code',
            'description' => 'nullable|string|max:255',
        ]);

        $permission = Permission::create($validated);
        return $this->createdResponse($permission, 'Permission created successfully');
    }

    public function show($id)
    {
        $permission = Permission::with('roles')->find($id);

        if (!$permission) {
            return $this->notFoundResponse('Permission not found');
        }

        return $this->successResponse($permission, 'Permission retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $permission = Permission::find($id);

        if (!$permission) {
            return $this->notFoundResponse('Permission not found');
        }

        $validated = $request->validate([
            'code' => 'sometimes|required|string|max:100|unique:permissions,code,' . $id,
            'description' => 'nullable|string|max:255',
        ]);

        $permission->update($validated);
        return $this->updatedResponse($permission, 'Permission updated successfully');
    }

    public function destroy($id)
    {
        $permission = Permission::find($id);

        if (!$permission) {
            return $this->notFoundResponse('Permission not found');
        }

        $permission->delete();
        return $this->deletedResponse('Permission deleted successfully');
    }
}
