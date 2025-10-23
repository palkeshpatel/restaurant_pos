class MenuItem {
  final int id;
  final String name;
  final double price;
  final String icon;
  final String description;
  final MenuCategory category;
  final bool isDrink; // To determine if it should use "fire" status

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    required this.category,
    this.isDrink = false,
  });
}

enum MenuCategory {
  combos,
  thali,
  soups,
  starters,
  maincourse,
  breads,
  rice,
  noodles,
  snacks,
  drinks,
}

extension MenuCategoryExtension on MenuCategory {
  String get displayName {
    switch (this) {
      case MenuCategory.combos:
        return 'Combos';
      case MenuCategory.thali:
        return 'Thali';
      case MenuCategory.soups:
        return 'Soups & Salads';
      case MenuCategory.starters:
        return 'Starters';
      case MenuCategory.maincourse:
        return 'Main Course';
      case MenuCategory.breads:
        return 'Breads';
      case MenuCategory.rice:
        return 'Rice & Biryani';
      case MenuCategory.noodles:
        return 'Fried Rice & Noodles';
      case MenuCategory.snacks:
        return 'Snacks';
      case MenuCategory.drinks:
        return 'Drinks';
    }
  }

  String get emoji {
    switch (this) {
      case MenuCategory.combos:
        return '🍱';
      case MenuCategory.thali:
        return '🍽️';
      case MenuCategory.soups:
        return '🥣';
      case MenuCategory.starters:
        return '🍢';
      case MenuCategory.maincourse:
        return '🍛';
      case MenuCategory.breads:
        return '🫓';
      case MenuCategory.rice:
        return '🍚';
      case MenuCategory.noodles:
        return '🍜';
      case MenuCategory.snacks:
        return '🍿';
      case MenuCategory.drinks:
        return '🥤';
    }
  }
}
