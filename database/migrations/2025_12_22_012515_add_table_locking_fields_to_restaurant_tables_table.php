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
        Schema::table('restaurant_tables', function (Blueprint $table) {
            $table->boolean('is_table_locked')->default(true)->after('fire_status_pending');
            $table->foreignId('current_served_by_id')->nullable()->after('is_table_locked')->constrained('employees')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('restaurant_tables', function (Blueprint $table) {
            $table->dropForeign(['current_served_by_id']);
            $table->dropColumn(['is_table_locked', 'current_served_by_id']);
        });
    }
};
