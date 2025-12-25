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
        Schema::create('menu_item_decision_groups', function (Blueprint $table) {
            $table->foreignId('menu_item_id')->constrained()->onDelete('cascade');
            $table->foreignId('decision_group_id')->constrained('decision_groups')->onDelete('cascade');
            $table->timestamps();
            $table->primary(['menu_item_id', 'decision_group_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('menu_item_decision_groups');
    }
};
