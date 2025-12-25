<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie', 'api/documentation', 'api/docs', 'api-docs/*', 'api/pos/*', 'storage/*'],

    'allowed_methods' => ['*'],

    // IMPORTANT: Add your frontend domains here (origins that will make requests to this API)
    'allowed_origins' => [
        'https://main.d2c4xzwlwb8jkv.amplifyapp.com', // AWS Amplify domain (React app)
        'https://servecheckpos.store',                 // API domain (if accessed directly from browser)
        'http://localhost:3000',                      // Local development
        'http://127.0.0.1:3000',                       // Local development
        // Add your custom domain if you have one:
        // 'https://yourdomain.com',

        // 🔥 REQUIRED for Swagger
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://localhost:64722',
        'http://127.0.0.1:64722'
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => [
        '*',
        'Authorization',
        'Content-Type',
        'X-Requested-With',
        'Accept',
        'Origin',
        'X-CSRF-TOKEN',
    ],

    'exposed_headers' => ['Authorization'],

    'max_age' => 86400,

    // CRITICAL: Must be true to allow credentials (auth tokens)
    'supports_credentials' => true,
];