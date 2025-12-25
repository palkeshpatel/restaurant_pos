<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MenuCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'menu_id',
        'parent_id',
        'name',
        'description',
        'image',
        'icon_image',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function menu(): BelongsTo
    {
        return $this->belongsTo(Menu::class);
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(MenuCategory::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(MenuCategory::class, 'parent_id');
    }

    public function childrenRecursive(): HasMany
    {
        return $this->children()
            ->where('is_active', true)
            ->with([
                'childrenRecursive',
                'menuItems' => function ($query) {
                    $query->where('is_active', true)
                        ->with([
                            'menuType',
                            'modifierGroups.modifiers',
                            'decisionGroups.decisions',
                        ]);
                },
            ]);
    }

    public function menuItems(): HasMany
    {
        return $this->hasMany(MenuItem::class);
    }
}
