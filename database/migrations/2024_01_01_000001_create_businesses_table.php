<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('businesses', function (Blueprint $table) {
            $table->id();
            $table->string('name', 255);
            $table->string('llc_name', 255)->default('');
            $table->string('address', 1000)->default('');
            $table->string('logo_url', 500)->default('');
            $table->string('timezone', 50);
            $table->decimal('auto_gratuity_percent', 5, 2)->default(0.00);
            $table->integer('auto_gratuity_min_guests')->default(0);
            $table->decimal('cc_fee_percent', 5, 2)->default(0.00);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('businesses');
    }
};