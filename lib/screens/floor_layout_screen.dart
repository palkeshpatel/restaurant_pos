import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/table_model.dart';
import 'pos_screen.dart';

class FloorLayoutScreen extends StatefulWidget {
  const FloorLayoutScreen({super.key});

  @override
  State<FloorLayoutScreen> createState() => _FloorLayoutScreenState();
}

class _FloorLayoutScreenState extends State<FloorLayoutScreen> {
  int? _selectedTableId;
  List<int> _joiningTables = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a2a3a),
              Color(0xFF0d1b2a),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Restaurant Floor Layout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Consumer<POSProvider>(
                          builder: (context, posProvider, child) {
                            return IconButton(
                              onPressed: () => posProvider.logout(),
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 28,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Consumer<POSProvider>(
                          builder: (context, posProvider, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4fc3f7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Tables: ${posProvider.tables.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Instructions
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Text(
                  'Tap a table to select it, tap another table to join them, then tap "Enter Table" to start taking orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Floor Layout
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPaint(
                    painter: FloorLayoutPainter(
                      tables: context.watch<POSProvider>().tables,
                      selectedTableId: _selectedTableId,
                      groupTables: _joiningTables,
                    ),
                    child: Consumer<POSProvider>(
                      builder: (context, posProvider, child) {
                        return Stack(
                          children: posProvider.tables.map((table) {
                            return Positioned(
                              left: _getTablePosition(table.id).dx,
                              top: _getTablePosition(table.id).dy,
                              child: GestureDetector(
                                onTap: () => _handleTableTap(table.id),
                                child: _buildTableWidget(table),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _joiningTables.length >= 2 ? _joinTables : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4fc3f7),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Join Tables (${_joiningTables.length}/2)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedTableId != null ? _enterTable : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Enter Table',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableWidget(TableModel table) {
    final isSelected = _selectedTableId == table.id;
    final isJoining = _joiningTables.contains(table.id);
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isSelected || isJoining 
            ? const Color(0xFF4fc3f7) 
            : table.isOccupied 
                ? Colors.red.withOpacity(0.7)
                : Colors.green.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : Colors.transparent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            table.isJoined ? '🔗' : '🍽️',
            style: const TextStyle(fontSize: 24),
          ),
          Text(
            table.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (table.isOccupied)
            const Text(
              'Occupied',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
            ),
        ],
      ),
    );
  }

  Offset _getTablePosition(int tableId) {
    // Create a grid layout for tables
    const double spacing = 120;
    const int tablesPerRow = 4;
    
    final row = (tableId - 1) ~/ tablesPerRow;
    final col = (tableId - 1) % tablesPerRow;
    
    return Offset(
      col * spacing + 40,
      row * spacing + 40,
    );
  }

  void _handleTableTap(int tableId) {
    setState(() {
      if (_joiningTables.contains(tableId)) {
        _joiningTables.remove(tableId);
      } else if (_joiningTables.length < 2) {
        _joiningTables.add(tableId);
      } else {
        // Reset and select new table
        _joiningTables = [tableId];
      }
      
      if (_selectedTableId == tableId) {
        _selectedTableId = null;
      } else {
        _selectedTableId = tableId;
      }
    });
  }

  void _joinTables() {
    if (_joiningTables.length >= 2) {
      context.read<POSProvider>().joinTables(_joiningTables[0], _joiningTables[1]);
      setState(() {
        _joiningTables = [];
        _selectedTableId = _joiningTables[0];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tables joined successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _enterTable() {
    if (_selectedTableId != null) {
      final posProvider = context.read<POSProvider>();
      final selectedTable = posProvider.tables.firstWhere(
        (table) => table.id == _selectedTableId,
      );
      
      posProvider.selectTable(selectedTable);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const POSScreen(),
        ),
      );
    }
  }
}

class FloorLayoutPainter extends CustomPainter {
  final List<TableModel> tables;
  final int? selectedTableId;
  final List<int> groupTables;

  FloorLayoutPainter({
    required this.tables,
    required this.selectedTableId,
    required this.groupTables,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;

    // Draw connection lines for joined tables
    for (int i = 0; i < groupTables.length - 1; i++) {
      final startPos = _getTablePosition(groupTables[i]);
      final endPos = _getTablePosition(groupTables[i + 1]);
      
      canvas.drawLine(
        Offset(startPos.dx + 40, startPos.dy + 40),
        Offset(endPos.dx + 40, endPos.dy + 40),
        paint,
      );
    }

    // Draw connection lines for already joined tables
    for (final table in tables) {
      if (table.isJoined) {
        for (final joinedTableId in table.joinedTables) {
          final startPos = _getTablePosition(table.id);
          final endPos = _getTablePosition(joinedTableId);
          
          canvas.drawLine(
            Offset(startPos.dx + 40, startPos.dy + 40),
            Offset(endPos.dx + 40, endPos.dy + 40),
            paint..color = const Color(0xFF4fc3f7),
          );
        }
      }
    }
  }

  Offset _getTablePosition(int tableId) {
    const double spacing = 120;
    const int tablesPerRow = 4;
    
    final row = (tableId - 1) ~/ tablesPerRow;
    final col = (tableId - 1) % tablesPerRow;
    
    return Offset(
      col * spacing + 40,
      row * spacing + 40,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
