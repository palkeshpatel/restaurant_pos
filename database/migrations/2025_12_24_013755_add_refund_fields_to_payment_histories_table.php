<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('payment_histories', function (Blueprint $table) {
            // Add refunded_payment_id field (default 0, not nullable)
            // 0 = original payment, > 0 = refund record linking to original payment
            $table->unsignedBigInteger('refunded_payment_id')->default(0)->after('status');
            
            // Add refund_reason field
            $table->string('refund_reason', 500)->nullable()->after('refunded_payment_id');
        });

        // Update status enum to include 'refunded'
        // Note: Laravel doesn't support modifying enum columns directly
        // We'll use raw SQL to alter the enum
        DB::statement("ALTER TABLE payment_histories MODIFY COLUMN status ENUM('completed', 'failed', 'cancelled', 'refunded') NOT NULL");
        
        // Add foreign key constraint for refunded_payment_id (only for non-zero values)
        // Since we're using 0 as default, we can't use standard foreign key constraint
        // We'll handle referential integrity at application level
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payment_histories', function (Blueprint $table) {
            // Drop columns
            $table->dropColumn('refunded_payment_id');
            $table->dropColumn('refund_reason');
        });

        // Revert status enum to original values
        DB::statement("ALTER TABLE payment_histories MODIFY COLUMN status ENUM('completed', 'failed', 'cancelled') NOT NULL");
    }
};
