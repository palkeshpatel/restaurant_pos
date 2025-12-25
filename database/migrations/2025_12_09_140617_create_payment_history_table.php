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
        Schema::create('payment_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('check_id')->constrained()->onDelete('cascade');
            $table->foreignId('employee_id')->constrained()->onDelete('cascade');
            $table->decimal('amount', 10, 2)->comment('Payment amount attempted');
            $table->enum('tip_type', ['percentage', 'fixed'])->nullable()->comment('Tip calculation type');
            $table->decimal('tip_value', 10, 2)->default(0)->comment('Tip value (percentage or fixed amount)');
            $table->decimal('tip_amount', 10, 2)->default(0)->comment('Calculated tip amount');
            $table->enum('payment_mode', ['cash', 'card', 'online'])->comment('Payment method used');
            $table->enum('status', ['completed', 'failed', 'cancelled'])->comment('Payment status');
            $table->string('failure_reason', 500)->nullable()->comment('Reason if payment failed or cancelled');
            $table->decimal('total_bill_amount', 10, 2)->comment('Total bill amount at time of payment');
            $table->decimal('remaining_amount', 10, 2)->comment('Remaining amount at time of payment');
            $table->decimal('paid_amount_before', 10, 2)->default(0)->comment('Total paid amount before this payment');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_histories');
    }
};
