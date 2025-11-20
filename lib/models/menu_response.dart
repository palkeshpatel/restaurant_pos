import 'menu_category.dart';

class MenuResponse {
  final List<MenuSection> menus;

  MenuResponse({required this.menus});

  factory MenuResponse.fromJson(List<dynamic> json) {
    return MenuResponse(
      menus: json.map((menu) => MenuSection.fromJson(menu)).toList(),
    );
  }
}

class MenuSection {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final String? iconImage;
  final List<MenuCategory> categories;

  MenuSection({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.iconImage,
    this.categories = const [],
  });

  factory MenuSection.fromJson(Map<String, dynamic> json) {
    return MenuSection(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      iconImage: json['icon_image'],
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((category) => MenuCategory.fromJson(category))
          .toList(),
    );
  }
}

