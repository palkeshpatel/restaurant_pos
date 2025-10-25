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
  bool _isMobile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkScreenSize();
  }

  void _checkScreenSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // More responsive breakpoints for better tablet support
    final isMobile = screenWidth < 1024 || (screenWidth < 1200 && screenHeight < 800);
    
    if (_isMobile != isMobile) {
      setState(() {
        _isMobile = isMobile;
      });
    }
  }

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
                padding: EdgeInsets.all(_isMobile ? 16 : 20),
                child: _isMobile 
                    ? _buildMobileHeader()
                    : _buildDesktopHeader(),
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
                child: _isMobile 
                    ? _buildMobileTableGrid()
                    : _buildDesktopTableGrid(),
              ),
              
              // Action Buttons
              Container(
                padding: EdgeInsets.all(_isMobile ? 16 : 20),
                child: _isMobile 
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
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
                        ],
                      )
                    : Row(
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

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Restaurant Floor Layout',
              style: TextStyle(
                fontSize: _isMobile ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Consumer<POSProvider>(
              builder: (context, posProvider, child) {
                return IconButton(
                  onPressed: () => posProvider.logout(),
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Consumer<POSProvider>(
          builder: (context, posProvider, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4fc3f7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Tables: ${posProvider.tables.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
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
    );
  }

  Widget _buildMobileTableGrid() {
    return Consumer<POSProvider>(
      builder: (context, posProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid based on screen size
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 4 : 3;
            final spacing = screenWidth > 600 ? 16.0 : 12.0;
            
            return Container(
              margin: EdgeInsets.all(spacing),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: 1,
                ),
                itemCount: posProvider.tables.length,
                itemBuilder: (context, index) {
                  final table = posProvider.tables[index];
                  return GestureDetector(
                    onTap: () => _handleTableTap(table.id),
                    child: _buildMobileTableCard(table),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopTableGrid() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            painter: FloorLayoutPainter(
              tables: context.watch<POSProvider>().tables,
              selectedTableId: _selectedTableId,
              groupTables: _joiningTables,
              containerSize: Size(constraints.maxWidth, constraints.maxHeight),
            ),
            child: Consumer<POSProvider>(
              builder: (context, posProvider, child) {
                return Stack(
                  children: posProvider.tables.map((table) {
                    final position = _getResponsiveTablePosition(table.id, constraints);
                    return Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: GestureDetector(
                        onTap: () => _handleTableTap(table.id),
                        child: _buildResponsiveTableWidget(table, constraints),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileTableCard(TableModel table) {
    final isSelected = _selectedTableId == table.id;
    final isJoining = _joiningTables.contains(table.id);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on card size
        final cardSize = constraints.maxWidth;
        final iconSize = (cardSize * 0.3).clamp(20.0, 32.0);
        final fontSize = (cardSize * 0.12).clamp(10.0, 16.0);
        final smallFontSize = (cardSize * 0.08).clamp(6.0, 12.0);
        
        return Container(
          decoration: BoxDecoration(
            color: isSelected || isJoining 
                ? const Color(0xFF4fc3f7) 
                : table.isOccupied 
                    ? Colors.red.withOpacity(0.7)
                    : Colors.green.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
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
              Icon(
                Icons.table_restaurant,
                color: Colors.white,
                size: iconSize,
              ),
              SizedBox(height: cardSize * 0.05),
              Text(
                table.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
              if (table.isOccupied)
                Container(
                  margin: EdgeInsets.only(top: cardSize * 0.02),
                  padding: EdgeInsets.symmetric(
                    horizontal: cardSize * 0.05, 
                    vertical: cardSize * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Occupied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: smallFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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

  Offset _getResponsiveTablePosition(int tableId, BoxConstraints constraints) {
    // Responsive grid layout that adapts to container size
    final containerWidth = constraints.maxWidth;
    final containerHeight = constraints.maxHeight;
    
    // Calculate optimal grid based on container size
    final tablesPerRow = (containerWidth / 150).floor().clamp(3, 6);
    final spacing = (containerWidth / tablesPerRow).clamp(100.0, 200.0);
    final tableSize = (spacing * 0.6).clamp(60.0, 120.0);
    
    final row = (tableId - 1) ~/ tablesPerRow;
    final col = (tableId - 1) % tablesPerRow;
    
    // Center the grid within the container
    final startX = (containerWidth - (tablesPerRow - 1) * spacing) / 2;
    final startY = (containerHeight - (row * spacing)) / 2;
    
    return Offset(
      startX + col * spacing - tableSize / 2,
      startY + row * spacing - tableSize / 2,
    );
  }

  Widget _buildResponsiveTableWidget(TableModel table, BoxConstraints constraints) {
    final isSelected = _selectedTableId == table.id;
    final isJoining = _joiningTables.contains(table.id);
    
    // Responsive table size based on container
    final containerWidth = constraints.maxWidth;
    final tableSize = (containerWidth / 8).clamp(60.0, 120.0);
    
    return Container(
      width: tableSize,
      height: tableSize,
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
            style: TextStyle(fontSize: (tableSize * 0.3).clamp(16.0, 32.0)),
          ),
          Text(
            table.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: (tableSize * 0.15).clamp(8.0, 16.0),
            ),
          ),
          if (table.isOccupied)
            Text(
              'Occupied',
              style: TextStyle(
                color: Colors.white,
                fontSize: (tableSize * 0.1).clamp(6.0, 12.0),
              ),
            ),
        ],
      ),
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
  final Size? containerSize;

  FloorLayoutPainter({
    required this.tables,
    required this.selectedTableId,
    required this.groupTables,
    this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;

    // Use responsive positioning if container size is provided
    final useResponsive = containerSize != null;
    
    // Draw connection lines for joined tables
    for (int i = 0; i < groupTables.length - 1; i++) {
      final startPos = useResponsive 
          ? _getResponsiveTablePosition(groupTables[i], containerSize!)
          : _getTablePosition(groupTables[i]);
      final endPos = useResponsive 
          ? _getResponsiveTablePosition(groupTables[i + 1], containerSize!)
          : _getTablePosition(groupTables[i + 1]);
      
      final tableSize = useResponsive 
          ? (containerSize!.width / 8).clamp(60.0, 120.0) / 2
          : 40.0;
      
      canvas.drawLine(
        Offset(startPos.dx + tableSize, startPos.dy + tableSize),
        Offset(endPos.dx + tableSize, endPos.dy + tableSize),
        paint,
      );
    }

    // Draw connection lines for already joined tables
    for (final table in tables) {
      if (table.isJoined) {
        for (final joinedTableId in table.joinedTables) {
          final startPos = useResponsive 
              ? _getResponsiveTablePosition(table.id, containerSize!)
              : _getTablePosition(table.id);
          final endPos = useResponsive 
              ? _getResponsiveTablePosition(joinedTableId, containerSize!)
              : _getTablePosition(joinedTableId);
          
          final tableSize = useResponsive 
              ? (containerSize!.width / 8).clamp(60.0, 120.0) / 2
              : 40.0;
          
          canvas.drawLine(
            Offset(startPos.dx + tableSize, startPos.dy + tableSize),
            Offset(endPos.dx + tableSize, endPos.dy + tableSize),
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

  Offset _getResponsiveTablePosition(int tableId, Size containerSize) {
    // Responsive grid layout that adapts to container size
    final containerWidth = containerSize.width;
    final containerHeight = containerSize.height;
    
    // Calculate optimal grid based on container size
    final tablesPerRow = (containerWidth / 150).floor().clamp(3, 6);
    final spacing = (containerWidth / tablesPerRow).clamp(100.0, 200.0);
    final tableSize = (spacing * 0.6).clamp(60.0, 120.0);
    
    final row = (tableId - 1) ~/ tablesPerRow;
    final col = (tableId - 1) % tablesPerRow;
    
    // Center the grid within the container
    final startX = (containerWidth - (tablesPerRow - 1) * spacing) / 2;
    final startY = (containerHeight - (row * spacing)) / 2;
    
    return Offset(
      startX + col * spacing - tableSize / 2,
      startY + row * spacing - tableSize / 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
