<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class FixSwaggerServerUrl extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'swagger:fix-server-url';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Fix the server URL in the generated Swagger API documentation JSON file';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $docsPath = storage_path('api-docs/api-docs.json');
        
        if (!File::exists($docsPath)) {
            $this->error('Swagger documentation file not found at: ' . $docsPath);
            $this->info('Please run: php artisan l5-swagger:generate first');
            return 1;
        }

        // Get the APP_URL from environment
        $appUrl = env('APP_URL', 'http://127.0.0.1:8000');
        $appUrl = rtrim($appUrl, '/');
        $serverUrl = $appUrl . '/api';
        
        $this->info('Updating server URL to: ' . $serverUrl);

        // Read the JSON file
        $jsonContent = File::get($docsPath);
        $json = json_decode($jsonContent, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            $this->error('Invalid JSON in api-docs.json: ' . json_last_error_msg());
            return 1;
        }

        // Update the servers array
        $json['servers'] = [
            [
                'url' => $serverUrl,
                'description' => env('APP_ENV') === 'production' ? 'Production Server' : 'API Server'
            ]
        ];

        // Write back to file
        $newJsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        File::put($docsPath, $newJsonContent);

        $this->info('✓ Successfully updated server URL in api-docs.json');
        $this->info('Server URL is now: ' . $serverUrl);
        
        return 0;
    }
}
