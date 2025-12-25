<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EndOfDay extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'eod_date',
        'completed_at',
        'completed_by_employee_id',
        'status',
        'total_sales',
        'total_orders',
        'notes',
    ];

    protected $casts = [
        'eod_date' => 'date',
        'completed_at' => 'datetime',
        'total_sales' => 'decimal:2',
        'total_orders' => 'integer',
    ];

    /**
     * Get the business that owns the EOD
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    /**
     * Get the employee who completed the EOD
     */
    public function completedByEmployee(): BelongsTo
    {
        return $this->belongsTo(Employee::class, 'completed_by_employee_id');
    }
}
