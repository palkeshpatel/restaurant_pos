import 'package:flutter/material.dart';

class OrderItem {
  final String name;
  final double price;
  final IconData icon;
  final DateTime addedTime;
  final int menuItemId; // ID from MenuItem
  int quantity;
  String? instructions; // Special instructions for kitchen
  List<int>? decisionIds; // Selected decision IDs
  List<Map<String, dynamic>>? modifiers; // Modifiers with qty and price

  OrderItem({
    required this.name,
    required this.price,
    required this.icon,
    required this.addedTime,
    required this.menuItemId,
    this.quantity = 1,
    this.instructions,
    this.decisionIds,
    this.modifiers,
  });
}