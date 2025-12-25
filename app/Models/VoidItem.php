<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VoidItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'item_id',
        'old_order_status',
    ];

    protected $casts = [
        'old_order_status' => 'integer',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function orderItem(): BelongsTo
    {
        return $this->belongsTo(OrderItem::class, 'item_id');
    }
}
