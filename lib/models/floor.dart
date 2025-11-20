import 'package:flutter/material.dart';
import 'table.dart';

class Floor {
  final int id;
  final String name;
  final String floorType;
  final List<TableModel> tables;

  Floor({
    required this.id,
    required this.name,
    required this.floorType,
    required this.tables,
  });

  IconData get icon {
    switch (floorType.toLowerCase()) {
      case 'outdoor':
        return Icons.deck;
      case 'indoor':
        return name.toLowerCase().contains('first')
            ? Icons.stairs
            : name.toLowerCase().contains('second')
                ? Icons.location_city
                : Icons.home;
      default:
        return Icons.home;
    }
  }

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      floorType: json['floor_type'] ?? 'indoor',
      tables: (json['tables'] as List<dynamic>? ?? [])
          .map((table) => TableModel.fromJson(table))
          .toList(),
    );
  }
}