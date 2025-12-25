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
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->onDelete('cascade');
            $table->string('order_ticket_id')->unique()->nullable();
            $table->string('order_ticket_title')->default('');
            $table->foreignId('table_id')->constrained('restaurant_tables')->onDelete('cascade');
            $table->foreignId('created_by_employee_id')->constrained('employees')->onDelete('cascade');
            $table->string('status', 50)->default('open');
            $table->integer('customer')->default(1)->comment('Number of customers for this order');
            $table->string('notes', 1000)->default('');
            $table->enum('gratuity_key', ['Auto', 'Manual', 'NotApplicable'])->default('NotApplicable');
            $table->enum('gratuity_type', ['fixed_money', 'percentage'])->nullable();
            $table->integer('gratuity_value')->default(0);
            $table->decimal('tax_value', 10, 2)->default(0.00)->comment('Calculated tax amount for the order');
            $table->decimal('fee_value', 10, 2)->default(0.00)->comment('Calculated fee amount for the order');
            $table->string('discount_reason', 500)->nullable()->comment('Discount reason text');
            $table->json('merged_table_ids')->nullable()->comment('Array of table IDs when tables are merged (e.g., [1,3] for T1T3)');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
