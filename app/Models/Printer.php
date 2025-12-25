<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Printer extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'name',
        'ip_address',
        'is_kitchen',
        'is_receipt',
    ];

    protected $casts = [
        'is_kitchen' => 'boolean',
        'is_receipt' => 'boolean',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function printerRoutes(): HasMany
    {
        return $this->hasMany(PrinterRoute::class);
    }

    public function kitchenTickets(): HasMany
    {
        return $this->hasMany(KitchenTicket::class);
    }
}
