class MenuItem {
  final int id;
  final String name;
  final double priceCash;
  final double priceCard;
  final String? image;
  final String? iconImage;
  final int? printerRouteId;
  final List<ModifierGroup> modifierGroups;
  final List<DecisionGroup> decisionGroups;
  final String categoryName;

  const MenuItem({
    required this.id,
    required this.name,
    required this.priceCash,
    required this.priceCard,
    this.image,
    this.iconImage,
    this.printerRouteId,
    this.modifierGroups = const [],
    this.decisionGroups = const [],
    required this.categoryName,
  });

  double get price => priceCash != 0 ? priceCash : priceCard;

  factory MenuItem.fromJson(
    Map<String, dynamic> json, {
    required String categoryName,
  }) {
    final modifierGroups = (json['modifier_groups'] as List<dynamic>? ?? [])
        .map((group) => ModifierGroup.fromJson(group))
        .toList();

    final decisionGroups = (json['decision_groups'] as List<dynamic>? ?? [])
        .map((group) => DecisionGroup.fromJson(group))
        .toList();

    // Handle price_cash and price_card - they might come as strings or numbers
    double parsePrice(dynamic priceValue) {
      if (priceValue == null) return 0.0;
      if (priceValue is num) return priceValue.toDouble();
      if (priceValue is String) {
        return double.tryParse(priceValue) ?? 0.0;
      }
      return 0.0;
    }
    
    return MenuItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      priceCash: parsePrice(json['price_cash']),
      priceCard: parsePrice(json['price_card']),
      image: json['image'],
      iconImage: json['icon_image'],
      printerRouteId: json['printer_route_id'],
      modifierGroups: modifierGroups,
      decisionGroups: decisionGroups,
      categoryName: categoryName,
    );
  }
}

class ModifierGroup {
  final int id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<Modifier> modifiers;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    this.modifiers = const [],
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      minSelect: json['min_select'] ?? 0,
      maxSelect: json['max_select'] ?? 0,
      modifiers: (json['modifiers'] as List<dynamic>? ?? [])
          .map((modifier) => Modifier.fromJson(modifier))
          .toList(),
    );
  }
}

class Modifier {
  final int id;
  final String name;
  final double additionalPrice;

  const Modifier({
    required this.id,
    required this.name,
    required this.additionalPrice,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    // Handle additional_price - might come as string or number
    double parsePrice(dynamic priceValue) {
      if (priceValue == null) return 0.0;
      if (priceValue is num) return priceValue.toDouble();
      if (priceValue is String) {
        return double.tryParse(priceValue) ?? 0.0;
      }
      return 0.0;
    }
    
    return Modifier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      additionalPrice: parsePrice(json['additional_price']),
    );
  }
}

class DecisionGroup {
  final int id;
  final String name;
  final List<Decision> decisions;

  const DecisionGroup({
    required this.id,
    required this.name,
    this.decisions = const [],
  });

  factory DecisionGroup.fromJson(Map<String, dynamic> json) {
    return DecisionGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      decisions: (json['decisions'] as List<dynamic>? ?? [])
          .map((decision) => Decision.fromJson(decision))
          .toList(),
    );
  }
}

class Decision {
  final int id;
  final String name;

  const Decision({
    required this.id,
    required this.name,
  });

  factory Decision.fromJson(Map<String, dynamic> json) {
    return Decision(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}