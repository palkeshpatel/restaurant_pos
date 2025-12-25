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
        Schema::create('end_of_days', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->onDelete('cascade');
            $table->date('eod_date')->comment('The date for which EOD is being done');
            $table->dateTime('completed_at')->comment('Date-time when EOD was completed');
            $table->foreignId('completed_by_employee_id')->nullable()->constrained('employees')->onDelete('set null');
            $table->enum('status', ['pending', 'completed'])->default('pending');
            $table->decimal('total_sales', 12, 2)->nullable()->comment('Total sales for the day');
            $table->integer('total_orders')->nullable()->comment('Total number of orders for the day');
            $table->text('notes')->nullable();
            $table->timestamps();
            
            // Ensure one EOD per business per date
            $table->unique(['business_id', 'eod_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('end_of_days');
    }
};
