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
        Schema::create('menu_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->onDelete('cascade');
            $table->foreignId('menu_id')->nullable()->constrained('menus')->onDelete('cascade');
            $table->foreignId('menu_category_id')->nullable()->constrained('menu_categories')->onDelete('cascade');
            $table->foreignId('menu_type_id')->nullable()->constrained('menu_types')->onDelete('set null');
            $table->string('name', 255);
            $table->decimal('price_cash', 10, 2);
            $table->decimal('price_card', 10, 2);
            $table->string('image')->default('');
            $table->string('icon_image')->default('');
            $table->boolean('is_active')->default(true);
            $table->boolean('is_auto_fire')->default(false);
            $table->boolean('is_open_item')->default(false);
            $table->foreignId('printer_route_id')->nullable()->constrained('printer_routes')->onDelete('set null');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('menu_items');
    }
};
