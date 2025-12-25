<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RestaurantTable extends Model
{
    use HasFactory;

    protected $fillable = [
        'floor_id',
        'name',
        'size',
        'capacity',
        'status',
        'x_coordinates',
        'y_coordinates',
        'fire_status_pending',
        'is_table_locked',
        'current_served_by_id',
    ];

    protected $casts = [
        'is_table_locked' => 'boolean',
        'fire_status_pending' => 'integer',
    ];

    public function floor(): BelongsTo
    {
        return $this->belongsTo(Floor::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'table_id');
    }

    public function reservations(): HasMany
    {
        return $this->hasMany(Reservation::class, 'table_id');
    }

    public function currentServedBy(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'current_served_by_id');
    }
}
