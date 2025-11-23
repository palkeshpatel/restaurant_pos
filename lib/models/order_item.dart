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
  int? orderItemId; // Unique ID from database (null = temporary/new item, not saved yet)
  bool fireStatus; // Fire status from database (false = hold, true = fire)
  int sequence; // Sequence for priority ordering (lower = higher priority)
  DateTime? createdAt; // Created timestamp from database

  OrderItem({
    required this.name,
    required dynamic price, // Accept dynamic but convert to double
    required this.icon,
    required this.addedTime,
    required this.menuItemId,
    this.quantity = 1,
    this.instructions,
    this.decisionIds,
    this.modifiers,
    this.orderItemId, // null for new items, set when loaded from API or after sending
    this.fireStatus = false, // Default to false (hold) for new items
    this.sequence = 0, // Default sequence
    this.createdAt, // Created timestamp from database
  }) : price = _ensureDouble(price);
  
  // Helper method to ensure price is always a double
  static double _ensureDouble(dynamic priceValue) {
    if (priceValue is double) return priceValue;
    if (priceValue is num) return priceValue.toDouble();
    if (priceValue is String) {
      return double.tryParse(priceValue) ?? 0.0;
    }
    return double.tryParse(priceValue.toString()) ?? 0.0;
  }
  
  // Helper to check if item is saved in database
  bool get isSaved => orderItemId != null;
  
  // Helper to check if item is temporary (new, not saved)
  bool get isTemporary => orderItemId == null;
  
  // Helper to check if item is on hold (not fired)
  bool get isOnHold => !fireStatus;
  
  // Helper to check if item is fired
  bool get isFired => fireStatus;
  
  // Get elapsed time since creation
  Duration get elapsedTime {
    final startTime = createdAt ?? addedTime;
    return DateTime.now().difference(startTime);
  }
  
  // Get formatted elapsed time string
  String get elapsedTimeString {
    final duration = elapsedTime;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
  
  // Get priority number (sequence + 1 for display)
  int get priority => sequence + 1;
}