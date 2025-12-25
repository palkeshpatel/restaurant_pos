<?php

namespace App\Http\Middleware;

use App\Models\Employee;
use App\Traits\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateEmployeeWithToken
{
    use ApiResponse;

    public function handle(Request $request, Closure $next): Response
    {
        // Log middleware entry for order/send endpoint
        if ($request->is('api/pos/order/send')) {
            Log::info('AuthenticateEmployeeWithToken - Middleware called for order/send', [
                'path' => $request->path(),
                'method' => $request->method(),
                'ip' => $request->ip(),
                'has_token' => $request->bearerToken() !== null,
            ]);
        }

        $token = $request->bearerToken();

        if (!$token) {
            if ($request->is('api/pos/order/send')) {
                Log::warning('AuthenticateEmployeeWithToken - Token missing for order/send');
            }
            return $this->unauthorizedResponse('Authentication token is missing.');
        }

        $employee = Employee::where('api_token', hash('sha256', $token))->first();

        if (!$employee || !$employee->is_active) {
            if ($request->is('api/pos/order/send')) {
                Log::warning('AuthenticateEmployeeWithToken - Invalid token for order/send', [
                    'employee_found' => $employee !== null,
                    'is_active' => $employee?->is_active,
                ]);
            }
            return $this->unauthorizedResponse('Invalid authentication token.');
        }

        if ($request->is('api/pos/order/send')) {
            Log::info('AuthenticateEmployeeWithToken - Authentication successful for order/send', [
                'employee_id' => $employee->id,
                'employee_name' => $employee->name,
                'business_id' => $employee->business_id,
            ]);
        }

        Auth::setUser($employee);
        $request->setUserResolver(fn() => $employee);

        return $next($request);
    }
}