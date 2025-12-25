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
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('check_id')->constrained()->onDelete('cascade');
            $table->foreignId('menu_item_id')->constrained()->onDelete('cascade');
            $table->integer('qty');
            $table->decimal('unit_price', 10, 2);
            $table->string('instructions', 1000)->default('');
            $table->tinyInteger('order_status')->default(0)->comment('0=HOLD, 1=FIRE, 2=TEMP, 3=VOID');
            $table->integer('customer_no')->default(1)->comment('Customer number (0=common shared box, 1, 2, 3, etc.)');
            $table->integer('sequence')->default(0)->comment('Order sequence for priority (lower number = higher priority)');
            $table->string('discount_type', 20)->default('')->comment('percentage, fixed, or empty string');
            $table->decimal('discount_value', 10, 2)->default(0)->comment('Percentage value (0-100) or fixed amount');
            $table->decimal('discount_amount', 10, 2)->default(0)->comment('Calculated discount amount in currency');
            $table->foreignId('employee_id')->nullable()->constrained('employees')->onDelete('set null');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_items');
    }
};