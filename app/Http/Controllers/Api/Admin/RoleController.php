<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Role;
use Illuminate\Http\Request;

class RoleController extends BaseAdminController
{
    /**
     * Display a listing of the roles.
     */
    public function index(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        $roles = Role::with(['business', 'employees', 'permissions'])
            ->where('business_id', $businessId)
            ->paginate($perPage, ['*'], 'page', $page);

        return $this->successResponse([
            'data' => $roles->items(),
            'total' => $roles->total(),
            'per_page' => $roles->perPage(),
            'current_page' => $roles->currentPage(),
            'last_page' => $roles->lastPage(),
        ], 'Roles retrieved successfully');
    }

    /**
     * Store a newly created role in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
        ]);

        $validated['business_id'] = $this->currentBusinessId($request);

        $role = Role::create($validated);
        return $this->createdResponse($role, 'Role created successfully');
    }

    /**
     * Display the specified role.
     */
    public function show(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $role = Role::with(['business', 'employees', 'permissions'])->find($id);

        $this->assertModelBelongsToBusiness($role, $businessId, 'Role');

        return $this->successResponse($role, 'Role retrieved successfully');
    }

    /**
     * Update the specified role in storage.
     */
    public function update(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $role = Role::find($id);

        $this->assertModelBelongsToBusiness($role, $businessId, 'Role');

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:100',
        ]);

        $validated['business_id'] = $businessId;

        $role->update($validated);
        return $this->updatedResponse($role, 'Role updated successfully');
    }

    /**
     * Remove the specified role from storage.
     */
    public function destroy(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $role = Role::find($id);

        $this->assertModelBelongsToBusiness($role, $businessId, 'Role');

        $role->delete();
        return $this->deletedResponse('Role deleted successfully');
    }

    /**
     * Assign permissions to a role.
     */
    public function assignPermissions(Request $request, $id)
    {
        $businessId = $this->currentBusinessId($request);
        $role = Role::find($id);

        $this->assertModelBelongsToBusiness($role, $businessId, 'Role');

        $validated = $request->validate([
            'permission_ids' => 'required|array',
            'permission_ids.*' => 'exists:permissions,id',
        ]);

        $role->permissions()->sync($validated['permission_ids']);

        return $this->successResponse($role->load('permissions'), 'Permissions assigned successfully');
    }
}
