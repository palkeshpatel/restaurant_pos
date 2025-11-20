import 'package:flutter/material.dart';
import 'order_item.dart';

class OrderStatus {
  final String name;
  final IconData icon;
  final Color color;
  final List<OrderItem> items;

  OrderStatus({
    required this.name,
    required this.icon,
    required this.color,
    required this.items,
  });
}