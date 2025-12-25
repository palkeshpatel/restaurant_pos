<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SetReferrerPolicy
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Handle preflight OPTIONS requests
        if ($request->getMethod() === 'OPTIONS') {
            $origin = $request->header('Origin');
            $allowedOrigins = [
                'https://main.d2c4xzwlwb8jkv.amplifyapp.com', // AWS Amplify domain (React app)
                'https://servecheckpos.store',                 // API domain (if accessed directly)
                'http://localhost:3000',
                'http://127.0.0.1:3000',
                'http://localhost:64722',
                'http://127.0.0.1:64722',
            ];

            // When supports_credentials is true, cannot use '*' - must be specific origin
            if (in_array($origin, $allowedOrigins)) {
                return response('', 200)
                    ->header('Access-Control-Allow-Origin', $origin)
                    ->header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')
                    ->header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin')
                    ->header('Access-Control-Allow-Credentials', 'true')
                    ->header('Access-Control-Max-Age', '86400');
            }

            // If origin is not allowed, return 403
            return response('', 403);
        }

        $response = $next($request);

        // Set Referrer Policy header
        $referrerPolicy = env('REFERRER_POLICY', 'strict-origin-when-cross-origin');
        $response->headers->set('Referrer-Policy', $referrerPolicy);

        // Get the origin from the request
        $origin = $request->header('Origin');

        // List of allowed origins
        $allowedOrigins = [
            'https://main.d2c4xzwlwb8jkv.amplifyapp.com', // AWS Amplify domain (React app)
            'https://servecheckpos.store',                 // API domain (if accessed directly)
            'http://localhost:3000',
            'http://127.0.0.1:3000',
        ];

        // Add CORS headers if origin is allowed
        // When supports_credentials is true, cannot use '*' - must be specific origin
        if (in_array($origin, $allowedOrigins)) {
            $response->headers->set('Access-Control-Allow-Origin', $origin);
            $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
            $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin');
            $response->headers->set('Access-Control-Allow-Credentials', 'true');
            $response->headers->set('Access-Control-Max-Age', '86400');
        } elseif ($origin === null) {
            // For same-origin requests (no Origin header), don't set CORS headers
            // This is fine - same-origin requests don't need CORS
        }

        return $response;
    }
}
