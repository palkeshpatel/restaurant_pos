import 'package:flutter/material.dart';

class OrderItem {
  final String name;
  final double price;
  final IconData icon;
  final DateTime addedTime;
  int quantity;

  OrderItem({
    required this.name,
    required this.price,
    required this.icon,
    required this.addedTime,
    this.quantity = 1,
  });
}