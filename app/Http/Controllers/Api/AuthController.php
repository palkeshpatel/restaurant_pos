<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Employee;
use App\Models\Role;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    use ApiResponse;

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $credentials['email'])->first();

        if (!$user || !Hash::check($credentials['password'], $user->password)) {
            return $this->unauthorizedResponse('Invalid email or password');
        }

        $plainToken = Str::random(64);
        $user->forceFill([
            'api_token' => hash('sha256', $plainToken),
        ])->save();

        // Load business
        $user->load('business');

        // Get roles with employees grouped under each role
        $rolesWithEmployees = [];
        if ($user->business_id) {
            $roles = Role::where('business_id', $user->business_id)
                ->with(['employees' => function ($query) use ($user) {
                    $query->where('employees.business_id', $user->business_id);
                }])
                ->get();

            $rolesWithEmployees = $roles->map(function ($role) {
                return [
                    'id' => $role->id,
                    'name' => $role->name,
                    'employees' => $role->employees->map(function ($employee) {
                        return [
                            'id' => $employee->id,
                            'first_name' => $employee->first_name,
                            'last_name' => $employee->last_name,
                            'email' => $employee->email,
                            'avatar' => $employee->avatar,
                            'is_active' => $employee->is_active,
                        ];
                    })->values(),
                ];
            })->values();
        }

        return $this->successResponse([
            'token' => $plainToken,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'avatar' => $user->avatar,
                'business_id' => $user->business_id,
                'is_super_admin' => $user->is_super_admin,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ],
            'business' => $user->business,
            'roles' => $rolesWithEmployees,
        ], 'Login successful');
    }

    public function logout(Request $request)
    {
        $user = $request->user();

        if ($user) {
            $user->forceFill([
                'api_token' => null,
            ])->save();
        }

        return $this->successResponse(null, 'Logged out successfully');
    }

    public function me(Request $request)
    {
        $user = $request->user();

        // Load business
        $user->load('business');

        // Get roles with employees grouped under each role
        $rolesWithEmployees = [];
        if ($user->business_id) {
            $roles = Role::where('business_id', $user->business_id)
                ->with(['employees' => function ($query) use ($user) {
                    $query->where('employees.business_id', $user->business_id);
                }])
                ->get();

            $rolesWithEmployees = $roles->map(function ($role) {
                return [
                    'id' => $role->id,
                    'name' => $role->name,
                    'employees' => $role->employees->map(function ($employee) {
                        return [
                            'id' => $employee->id,
                            'first_name' => $employee->first_name,
                            'last_name' => $employee->last_name,
                            'email' => $employee->email,
                            'avatar' => $employee->avatar,
                            'is_active' => $employee->is_active,
                        ];
                    })->values(),
                ];
            })->values();
        }

        return $this->successResponse([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'avatar' => $user->avatar,
                'business_id' => $user->business_id,
                'is_super_admin' => $user->is_super_admin,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ],
            'business' => $user->business,
            'roles' => $rolesWithEmployees,
        ], 'Authenticated user retrieved successfully');
    }
}
