import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/table_model.dart';
import 'pos_screen.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class FloorLayoutScreen extends StatefulWidget {
  const FloorLayoutScreen({super.key});

  @override
  State<FloorLayoutScreen> createState() => _FloorLayoutScreenState();
}

class _FloorLayoutScreenState extends State<FloorLayoutScreen> {
  int? _selectedTableId;
  List<int> _joiningTables = [];
  DeviceType _deviceType = DeviceType.mobile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkScreenSize();
  }

  void _checkScreenSize() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Improved responsive breakpoints
    DeviceType newDeviceType;
    if (screenWidth < 768) {
      newDeviceType = DeviceType.mobile;
    } else if (screenWidth < 1200) {
      newDeviceType = DeviceType.tablet;
    } else {
      newDeviceType = DeviceType.desktop;
    }

    if (_deviceType != newDeviceType) {
      setState(() {
        _deviceType = newDeviceType;
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
                padding: EdgeInsets.all(_getResponsivePadding()),
                child: _buildResponsiveHeader(),
              ),

              // Instructions
              Container(
                margin: EdgeInsets.symmetric(horizontal: _getResponsiveMargin()),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  'Tap a table to select it, tap another table to join them, then tap "Enter Table" to start taking orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(14),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: _getResponsiveSpacing(20)),

              // Floor Layout
              Expanded(
                child: _buildResponsiveTableGrid(),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(_getResponsivePadding()),
                child: _buildResponsiveActionButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader() {
    return _deviceType == DeviceType.mobile
        ? _buildMobileHeader()
        : _buildDesktopHeader();
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
                fontSize: _getResponsiveFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Consumer<POSProvider>(
              builder: (context, posProvider, child) {
                return IconButton(
                  onPressed: () => posProvider.logout(),
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: _getResponsiveIconSize(24),
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
        Text(
          'Restaurant Floor Layout',
          style: TextStyle(
            fontSize: _getResponsiveFontSize(24),
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
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: _getResponsiveIconSize(28),
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

  Widget _buildResponsiveTableGrid() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _buildMobileTableGrid();
      case DeviceType.tablet:
      case DeviceType.desktop:
        return _buildDesktopTableGrid();
    }
  }

  Widget _buildMobileTableGrid() {
    return Consumer<POSProvider>(
      builder: (context, posProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid based on screen size
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 4 : 3;
            final spacing = _getResponsiveSpacing(12);

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
      margin: EdgeInsets.all(_getResponsiveMargin(20)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
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
              deviceType: _deviceType,
              tablesPerRow: _getTableGridConfig().$1,
              baseSpacing: _getTableGridConfig().$2,
              maxTableSize: _getMaxTableSize(),
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

  Widget _buildResponsiveActionButtons() {
    return _deviceType == DeviceType.mobile
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTableId != null ? _enterTable : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: _getResponsiveButtonPadding()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Enter Table',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: _getResponsiveSpacing(12)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _joiningTables.length >= 2 ? _joinTables : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4fc3f7),
                    padding: EdgeInsets.symmetric(vertical: _getResponsiveButtonPadding()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Join Tables (${_joiningTables.length}/2)',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(16),
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
                    padding: EdgeInsets.symmetric(vertical: _getResponsiveButtonPadding()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Join Tables (${_joiningTables.length}/2)',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(16)),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedTableId != null ? _enterTable : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: _getResponsiveButtonPadding()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Enter Table',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
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
                    ? Colors.red.withValues(alpha: 0.7)
                    : Colors.green.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.2),
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



  Offset _getResponsiveTablePosition(int tableId, BoxConstraints constraints) {
    // Responsive grid layout that adapts to container size and device type
    final containerWidth = constraints.maxWidth;
    final containerHeight = constraints.maxHeight;

    // Different table configurations based on device type
    final (tablesPerRow, baseSpacing) = _getTableGridConfig();

    final spacing = (containerWidth / tablesPerRow).clamp(baseSpacing, baseSpacing * 1.5);
    final tableSize = (spacing * 0.6).clamp(60.0, _getMaxTableSize());

    final row = (tableId - 1) ~/ tablesPerRow;
    final col = (tableId - 1) % tablesPerRow;

    // Center the grid within the container
    final totalGridWidth = (tablesPerRow - 1) * spacing;
    final totalGridHeight = (context.read<POSProvider>().tables.length / tablesPerRow).ceil() * spacing;

    final startX = (containerWidth - totalGridWidth) / 2;
    final startY = (containerHeight - totalGridHeight) / 2;

    return Offset(
      startX + col * spacing - tableSize / 2,
      startY + row * spacing - tableSize / 2,
    );
  }

  (int, double) _getTableGridConfig() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return (3, 120.0); // 3 columns for mobile
      case DeviceType.tablet:
        return (4, 140.0); // 4 columns for tablet
      case DeviceType.desktop:
        return (5, 160.0); // 5 columns for desktop
    }
  }

  double _getMaxTableSize() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 100.0;
      case DeviceType.tablet:
        return 120.0;
      case DeviceType.desktop:
        return 140.0;
    }
  }

  Widget _buildResponsiveTableWidget(TableModel table, BoxConstraints constraints) {
    final isSelected = _selectedTableId == table.id;
    final isJoining = _joiningTables.contains(table.id);

    // Responsive table size based on device type
    final tableSize = _getResponsiveTableSize(constraints.maxWidth);

    return Container(
      width: tableSize,
      height: tableSize,
      decoration: BoxDecoration(
        color: isSelected || isJoining
            ? const Color(0xFF4fc3f7)
            : table.isOccupied
                ? Colors.red.withValues(alpha: 0.7)
                : Colors.green.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : Colors.transparent,
          width: _getResponsiveBorderWidth(),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: _getResponsiveBlurRadius(),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            table.isJoined ? '🔗' : '🍽️',
            style: TextStyle(fontSize: _getResponsiveEmojiSize(tableSize)),
          ),
          Text(
            table.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveTableTextSize(tableSize),
            ),
          ),
          if (table.isOccupied)
            Text(
              'Occupied',
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveSmallTextSize(tableSize),
              ),
            ),
        ],
      ),
    );
  }

  double _getResponsiveTableSize(double containerWidth) {
    final (_, baseSpacing) = _getTableGridConfig();
    return (baseSpacing * 0.6).clamp(60.0, _getMaxTableSize());
  }

  double _getResponsiveBorderWidth() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 2.0;
      case DeviceType.tablet:
        return 2.5;
      case DeviceType.desktop:
        return 3.0;
    }
  }

  double _getResponsiveBlurRadius() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 6.0;
      case DeviceType.tablet:
        return 8.0;
      case DeviceType.desktop:
        return 10.0;
    }
  }

  double _getResponsiveEmojiSize(double tableSize) {
    return (tableSize * 0.3).clamp(16.0, 32.0);
  }

  double _getResponsiveTableTextSize(double tableSize) {
    return (tableSize * 0.15).clamp(8.0, 16.0);
  }

  double _getResponsiveSmallTextSize(double tableSize) {
    return (tableSize * 0.1).clamp(6.0, 12.0);
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
  final DeviceType deviceType;
  final int tablesPerRow;
  final double baseSpacing;
  final double maxTableSize;

  FloorLayoutPainter({
    required this.tables,
    required this.selectedTableId,
    required this.groupTables,
    this.containerSize,
    this.deviceType = DeviceType.mobile,
    this.tablesPerRow = 3,
    this.baseSpacing = 120.0,
    this.maxTableSize = 120.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = _getResponsiveStrokeWidth();

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

      final tableRadius = maxTableSize / 2;

      canvas.drawLine(
        Offset(startPos.dx + tableRadius, startPos.dy + tableRadius),
        Offset(endPos.dx + tableRadius, endPos.dy + tableRadius),
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

          final tableRadius = maxTableSize / 2;

          canvas.drawLine(
            Offset(startPos.dx + tableRadius, startPos.dy + tableRadius),
            Offset(endPos.dx + tableRadius, endPos.dy + tableRadius),
            paint..color = const Color(0xFF4fc3f7),
          );
        }
      }
    }
  }

  double _getResponsiveStrokeWidth() {
    switch (deviceType) {
      case DeviceType.mobile:
        return 2.0;
      case DeviceType.tablet:
        return 2.5;
      case DeviceType.desktop:
        return 3.0;
    }
  }


  Offset _getResponsiveTablePosition(int tableId, Size containerSize) {
    // Responsive grid layout that adapts to container size and device type
    final containerWidth = containerSize.width;
    final containerHeight = containerSize.height;

    final spacing = (containerWidth / tablesPerRow).clamp(baseSpacing, baseSpacing * 1.5);
    final tableSize = (spacing * 0.6).clamp(60.0, maxTableSize);

    final row = (tableId - 1) ~/ tablesPerRow;
    final col = (tableId - 1) % tablesPerRow;

    // Center the grid within the container
    final totalGridWidth = (tablesPerRow - 1) * spacing;
    final totalGridHeight = (tables.length / tablesPerRow).ceil() * spacing;

    final startX = (containerWidth - totalGridWidth) / 2;
    final startY = (containerHeight - totalGridHeight) / 2;

    return Offset(
      startX + col * spacing - tableSize / 2,
      startY + row * spacing - tableSize / 2,
    );
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

// Responsive Helper Methods
extension _ResponsiveHelpers on _FloorLayoutScreenState {
  double _getResponsivePadding([double base = 16]) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return base;
      case DeviceType.tablet:
        return base * 1.25;
      case DeviceType.desktop:
        return base * 1.5;
    }
  }

  double _getResponsiveMargin([double base = 16]) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return base;
      case DeviceType.tablet:
        return base * 1.5;
      case DeviceType.desktop:
        return base * 2;
    }
  }

  double _getResponsiveSpacing(double base) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return base;
      case DeviceType.tablet:
        return base * 1.2;
      case DeviceType.desktop:
        return base * 1.4;
    }
  }

  double _getResponsiveFontSize(double base) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return base;
      case DeviceType.tablet:
        return base * 1.1;
      case DeviceType.desktop:
        return base * 1.2;
    }
  }

  double _getResponsiveIconSize(double base) {
    switch (_deviceType) {
      case DeviceType.mobile:
        return base;
      case DeviceType.tablet:
        return base * 1.1;
      case DeviceType.desktop:
        return base * 1.2;
    }
  }

  double _getResponsiveButtonPadding() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 15;
      case DeviceType.tablet:
        return 18;
      case DeviceType.desktop:
        return 20;
    }
  }
}
