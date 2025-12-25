<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderCancel extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'order_ticket_id',
        'order_ticket_title',
        'table_id',
        'created_by_employee_id',
        'status',
        'customer',
        'notes',
        'gratuity_key',
        'gratuity_type',
        'gratuity_value',
        'tax_value',
        'fee_value',
        'merged_table_ids',
    ];

    protected $casts = [
        'merged_table_ids' => 'array',
        'tax_value' => 'decimal:2',
        'fee_value' => 'decimal:2',
    ];
}
