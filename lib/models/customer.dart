import 'order_item.dart';

class Customer {
  final String id;
  final String name;
  final List<OrderItem> items;

  Customer({
    required this.id,
    required this.name,
    List<OrderItem>? items,
  }) : items = items ?? [];

  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  double get tax => subtotal * 0.1;
  double get total => subtotal + tax;
}

