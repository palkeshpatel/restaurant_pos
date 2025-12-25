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
        Schema::create('restaurant_tables', function (Blueprint $table) {
            $table->id();
            $table->foreignId('floor_id')->constrained()->onDelete('cascade');
            $table->string('name', 50);
            $table->enum('size', ['small', 'medium', 'large']);
            $table->integer('capacity');
            $table->string('status', 50)->default('available');
            $table->integer('x_coordinates')->default(0);
            $table->integer('y_coordinates')->default(0);
            $table->tinyInteger('fire_status_pending')->default(0)->comment('1 = true (pending), 0 = false (not pending)');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('restaurant_tables');
    }
};
