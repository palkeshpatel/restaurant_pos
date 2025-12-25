<?php

namespace App\Services;

use Illuminate\Support\Facades\View;

class ReportService
{
    /**
     * Generate thermal format (text) from Blade template
     */
    public function generateThermalFormat($templateName, $data)
    {
        return View::make("reports.thermal.{$templateName}", $data)->render();
    }

    /**
     * Generate thermal format HTML from Blade template
     */
    public function generateThermalFormatHtml($templateName, $data)
    {
        return View::make("reports.html.{$templateName}", $data)->render();
    }
}

