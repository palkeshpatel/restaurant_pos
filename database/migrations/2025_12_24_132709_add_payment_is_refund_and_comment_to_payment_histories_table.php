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
        Schema::table('payment_histories', function (Blueprint $table) {
            // Add payment_is_refund field (boolean, default false)
            // true = this payment has been refunded, false = not refunded
            $table->boolean('payment_is_refund')->default(false)->after('refund_reason');
            
            // Add comment field (nullable text)
            $table->text('comment')->nullable()->after('payment_is_refund');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payment_histories', function (Blueprint $table) {
            $table->dropColumn('payment_is_refund');
            $table->dropColumn('comment');
        });
    }
};