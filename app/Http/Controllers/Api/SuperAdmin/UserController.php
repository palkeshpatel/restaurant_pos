<?php

namespace App\Http\Controllers\Api\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    use ApiResponse;

    public function index()
    {
        $users = User::with('business')->get();
        return $this->successResponse($users, 'Users retrieved successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'business_id' => 'nullable|exists:businesses,id',
            'is_super_admin' => 'boolean',
        ]);

        if (!($validated['is_super_admin'] ?? false) && empty($validated['business_id'])) {
            return $this->errorResponse('Non super-admin users must be associated with a business', 422);
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'business_id' => $validated['business_id'] ?? null,
            'is_super_admin' => $validated['is_super_admin'] ?? false,
        ]);

        return $this->createdResponse($user, 'User created successfully');
    }

    public function show($id)
    {
        $user = User::with('business')->find($id);

        if (!$user) {
            return $this->notFoundResponse('User not found');
        }

        return $this->successResponse($user, 'User retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->notFoundResponse('User not found');
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => [
                'sometimes',
                'required',
                'email',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'password' => 'nullable|string|min:6',
            'business_id' => 'nullable|exists:businesses,id',
            'is_super_admin' => 'boolean',
        ]);

        if (array_key_exists('is_super_admin', $validated) ? !$validated['is_super_admin'] : !$user->is_super_admin) {
            $businessId = $validated['business_id'] ?? $user->business_id;

            if (!$businessId) {
                return $this->errorResponse('Non super-admin users must be associated with a business', 422);
            }
        }

        if (!empty($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        $user->update($validated);
        return $this->updatedResponse($user->fresh('business'), 'User updated successfully');
    }

    public function destroy($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->notFoundResponse('User not found');
        }

        $user->delete();
        return $this->deletedResponse('User deleted successfully');
    }
}
