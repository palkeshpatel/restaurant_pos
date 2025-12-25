<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'table_id',
        'created_by_employee_id',
        'status',
        'customer',
        'notes',
        'order_ticket_id',
        'order_ticket_title',
        'gratuity_key',
        'gratuity_type',
        'gratuity_value',
        'tax_value',
        'fee_value',
        'discount_reason',
        'merged_table_ids',
    ];

    protected $casts = [
        'merged_table_ids' => 'array',
        'tax_value' => 'decimal:2',
        'fee_value' => 'decimal:2',
        'gratuity_value' => 'decimal:2',
    ];

    /**
     * Get the gratuity_type attribute - return empty string instead of null
     */
    public function getGratuityTypeAttribute($value)
    {
        return $value ?? '';
    }

    /**
     * Get the discount_reason attribute - return empty string instead of null
     */
    public function getDiscountReasonAttribute($value)
    {
        return $value ?? '';
    }

    /**
     * Get the gratuity_value attribute - format as string with 2 decimal places
     */
    public function getGratuityValueAttribute($value)
    {
        if ($value === null || $value === '') {
            return '0.00';
        }
        return number_format((float) $value, 2, '.', '');
    }

    public function table(): BelongsTo
    {
        return $this->belongsTo(RestaurantTable::class, 'table_id');
    }

    public function createdByEmployee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'created_by_employee_id');
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function checks(): HasMany
    {
        return $this->hasMany(Check::class);
    }

    public function kitchenTickets(): HasMany
    {
        return $this->hasMany(KitchenTicket::class);
    }

    public function paymentHistories(): HasMany
    {
        return $this->hasMany(PaymentHistory::class);
    }
}
