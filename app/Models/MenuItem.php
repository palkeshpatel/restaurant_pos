<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MenuItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'menu_id',
        'menu_category_id',
        'menu_type_id',
        'name',
        'price_cash',
        'price_card',
        'image',
        'icon_image',
        'is_active',
        'is_auto_fire',
        'is_open_item',
        'printer_route_id',
    ];

    protected $casts = [
        'price_cash' => 'float',
        'price_card' => 'float',
        'is_active' => 'boolean',
        'is_auto_fire' => 'boolean',
        'is_open_item' => 'boolean',
    ];

    public function menu(): BelongsTo
    {
        return $this->belongsTo(Menu::class, 'menu_id');
    }

    public function menuCategory(): BelongsTo
    {
        return $this->belongsTo(MenuCategory::class, 'menu_category_id');
    }

    public function menuType(): BelongsTo
    {
        return $this->belongsTo(MenuType::class, 'menu_type_id');
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function printerRoute(): BelongsTo
    {
        return $this->belongsTo(PrinterRoute::class);
    }

    public function modifierGroups(): BelongsToMany
    {
        return $this->belongsToMany(ModifierGroup::class, 'menu_item_modifier_groups')
            ->withTimestamps();
    }

    public function decisionGroups(): BelongsToMany
    {
        return $this->belongsToMany(DecisionGroup::class, 'menu_item_decision_groups')
            ->withTimestamps();
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
