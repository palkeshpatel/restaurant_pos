class TableModel {
  final int id;
  final String name;
  final bool isOccupied;
  final List<Customer> customers;
  final bool isJoined;
  final List<int> joinedTables;

  TableModel({
    required this.id,
    required this.name,
    this.isOccupied = false,
    this.customers = const [],
    this.isJoined = false,
    this.joinedTables = const [],
  });

  TableModel copyWith({
    int? id,
    String? name,
    bool? isOccupied,
    List<Customer>? customers,
    bool? isJoined,
    List<int>? joinedTables,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isOccupied: isOccupied ?? this.isOccupied,
      customers: customers ?? this.customers,
      isJoined: isJoined ?? this.isJoined,
      joinedTables: joinedTables ?? this.joinedTables,
    );
  }
}

class Customer {
  final int id;
  final String name;
  final List<OrderItem> orders;

  Customer({
    required this.id,
    required this.name,
    this.orders = const [],
  });

  Customer copyWith({
    int? id,
    String? name,
    List<OrderItem>? orders,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      orders: orders ?? this.orders,
    );
  }
}

class OrderItem {
  final int id;
  final String name;
  final double price;
  final String icon;
  final String description;
  final ItemStatus status;
  final int quantity;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    this.status = ItemStatus.hold,
    this.quantity = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  OrderItem copyWith({
    int? id,
    String? name,
    double? price,
    String? icon,
    String? description,
    ItemStatus? status,
    int? quantity,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum ItemStatus {
  fire, // For drinks, soda, tea
  hold, // For main course items (pending)
  served,
}

extension ItemStatusExtension on ItemStatus {
  String get displayName {
    switch (this) {
      case ItemStatus.fire:
        return 'Fire';
      case ItemStatus.hold:
        return 'Hold';
      case ItemStatus.served:
        return 'Served';
    }
  }

  String get emoji {
    switch (this) {
      case ItemStatus.fire:
        return '🔥';
      case ItemStatus.hold:
        return '⏳'; // Using hourglass icon for Hold (pending)
      case ItemStatus.served:
        return '✅';
    }
  }
}
