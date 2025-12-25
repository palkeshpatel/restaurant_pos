<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'check_id',
        'menu_item_id',
        'qty',
        'unit_price',
        'instructions',
        'order_status',
        'customer_no',
        'sequence',
        'discount_type',
        'discount_value',
        'discount_amount',
        'served_by_id',
        'employee_id',
    ];

    protected $casts = [
        'unit_price' => 'decimal:2',
        'order_status' => 'integer',
        'discount_value' => 'decimal:2',
        'discount_amount' => 'decimal:2',
    ];

    /**
     * Get the discount_type attribute - return empty string instead of null
     */
    public function getDiscountTypeAttribute($value)
    {
        return $value ?? '';
    }

    public function check(): BelongsTo
    {
        return $this->belongsTo(Check::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function menuItem(): BelongsTo
    {
        return $this->belongsTo(MenuItem::class);
    }

    public function modifiers(): BelongsToMany
    {
        return $this->belongsToMany(Modifier::class, 'order_item_modifiers')
            ->withPivot('order_id', 'qty', 'price', 'employee_id')
            ->withTimestamps();
    }

    public function decisions(): BelongsToMany
    {
        return $this->belongsToMany(Decision::class, 'order_item_decision')
            ->withPivot('employee_id')
            ->withTimestamps();
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'employee_id');
    }

    public function servedBy(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'served_by_id');
    }
}
