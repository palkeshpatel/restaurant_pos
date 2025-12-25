<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateWithToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $header = $request->bearerToken();

        if (!$header) {
            return response()->json([
                'success' => false,
                'message' => 'Authentication token is missing.',
            ], 401);
        }

        $hashedToken = hash('sha256', $header);

        $user = User::where('api_token', $hashedToken)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid authentication token.',
            ], 401);
        }

        Auth::setUser($user);
        $request->setUserResolver(fn() => $user);

        return $next($request);
    }
}
