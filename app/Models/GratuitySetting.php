<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GratuitySetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'gratuity_key',
        'gratuity_type',
        'gratuity_value',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
