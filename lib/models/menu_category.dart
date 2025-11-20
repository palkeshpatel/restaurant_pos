import 'menu_item.dart';

class MenuCategory {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final String? image;
  final String? iconImage;
  final List<MenuItem> menuItems;
  final List<MenuCategory> children;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.image,
    this.iconImage,
    this.menuItems = const [],
    this.children = const [],
  });

  factory MenuCategory.fromJson(
    Map<String, dynamic> json, {
    String parentPath = '',
  }) {
    final name = json['name'] ?? '';
    final displayName = parentPath.isNotEmpty ? '$parentPath > $name' : name;

    final items = (json['menu_items'] as List<dynamic>? ?? [])
        .map((item) => MenuItem.fromJson(item, categoryName: name))
        .toList();

    final childCategories = (json['children'] as List<dynamic>? ?? [])
        .map((child) => MenuCategory.fromJson(child, parentPath: displayName))
        .toList();

    return MenuCategory(
      id: json['id'] ?? 0,
      name: name,
      displayName: displayName,
      description: json['description'],
      image: json['image'],
      iconImage: json['icon_image'],
      menuItems: items,
      children: childCategories,
    );
  }

  MenuCategory copyWith({
    int? id,
    String? name,
    String? displayName,
    String? description,
    String? image,
    String? iconImage,
    List<MenuItem>? menuItems,
    List<MenuCategory>? children,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      image: image ?? this.image,
      iconImage: iconImage ?? this.iconImage,
      menuItems: menuItems ?? this.menuItems,
      children: children ?? this.children,
    );
  }
}

