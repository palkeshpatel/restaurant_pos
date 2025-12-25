<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'check_id',
        'employee_id',
        'amount',
        'tip_type',
        'tip_value',
        'tip_amount',
        'payment_mode',
        'status',
        'failure_reason',
        'total_bill_amount',
        'remaining_amount',
        'paid_amount_before',
        'refunded_payment_id',
        'refund_reason',
        'payment_is_refund',
        'comment',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'tip_value' => 'decimal:2',
        'tip_amount' => 'decimal:2',
        'total_bill_amount' => 'decimal:2',
        'remaining_amount' => 'decimal:2',
        'paid_amount_before' => 'decimal:2',
        'refunded_payment_id' => 'integer',
        'payment_is_refund' => 'boolean',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function check(): BelongsTo
    {
        return $this->belongsTo(Check::class);
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    /**
     * Get the original payment that this refund is for
     */
    public function refundedPayment(): BelongsTo
    {
        return $this->belongsTo(PaymentHistory::class, 'refunded_payment_id');
    }

    /**
     * Get all refunds for this payment
     */
    public function refunds()
    {
        return $this->hasMany(PaymentHistory::class, 'refunded_payment_id');
    }
}
