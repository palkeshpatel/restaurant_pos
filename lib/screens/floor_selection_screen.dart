import 'package:flutter/material.dart';
import '../models/floor.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'table_selection_screen.dart';
import 'settings_screen.dart';
import '../screens/dashboard_screen.dart';

class FloorSelectionScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const FloorSelectionScreen({super.key, required this.onThemeChange});

  @override
  State<FloorSelectionScreen> createState() => _FloorSelectionScreenState();
}

class _FloorSelectionScreenState extends State<FloorSelectionScreen> {
  List<Floor> floors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFloors();
  }

  Future<void> _loadFloors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getTables();
      if (response.success && response.data != null) {
        setState(() {
          floors = response.data!.floors;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading floors: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _selectFloor(Floor floor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableSelectionScreen(
          floor: floor,
          onThemeChange: widget.onThemeChange,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ApiService.logoutEmployee();
      await StorageService.removeCurrentEmployee();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DashboardScreen(onThemeChange: widget.onThemeChange),
          ),
          (route) => false,
        );
      }
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsScreen(onThemeChange: widget.onThemeChange),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).colorScheme.primary),
                    iconSize: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 8 : 20),
                  Expanded(
                    child: Text(
                      'Select Floor',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    color: Colors.red,
                    iconSize: isMobile ? 20 : 24,
                    tooltip: 'Logout',
                  ),
                  IconButton(
                    onPressed: _showSettings,
                    icon: const Icon(Icons.settings),
                    color: Theme.of(context).colorScheme.primary,
                    iconSize: isMobile ? 20 : 24,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: isMobile ? 48 : 64,
                                  color: Colors.red,
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isMobile ? 16 : 20),
                                ElevatedButton.icon(
                                  onPressed: _loadFloors,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : floors.isEmpty
                            ? Center(
                                child: Text(
                                  'No floors found',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile ? 1 : 2,
                                  mainAxisSpacing: isMobile ? 12 : 18,
                                  crossAxisSpacing: isMobile ? 12 : 18,
                                  childAspectRatio: isMobile ? 2.1 : 2.4,
                                ),
                                itemCount: floors.length,
                                itemBuilder: (context, index) {
                                  final floor = floors[index];
                                  final occupiedCount = floor.tables
                                      .where((t) => t.isOccupied)
                                      .length;
                                  final availableCount = floor.tables
                                      .where((t) => t.isAvailable)
                                      .length;
                                  final gradientPalettes = [
                                    [
                                      const Color(0xFFFFE4C4),
                                      const Color(0xFFFFF4E3)
                                    ],
                                    [
                                      const Color(0xFFE4F5FF),
                                      const Color(0xFFF3FAFF)
                                    ],
                                    [
                                      const Color(0xFFEFE5FF),
                                      const Color(0xFFF8F2FF)
                                    ],
                                  ];
                                  final colors = gradientPalettes[
                                      index % gradientPalettes.length];

                                  return InkWell(
                                    onTap: () => _selectFloor(floor),
                                    borderRadius: BorderRadius.circular(25),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding:
                                          EdgeInsets.all(isMobile ? 16 : 20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: colors,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: isMobile ? 64 : 72,
                                            height: isMobile ? 64 : 72,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.7),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.35),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              floor.icon,
                                              size: isMobile ? 30 : 36,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: isMobile ? 14 : 18),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  floor.name,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isMobile ? 18 : 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(
                                                    height: isMobile ? 6 : 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.table_bar,
                                                      size: isMobile ? 18 : 20,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      '${floor.tables.length} tables',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade700,
                                                        fontSize:
                                                            isMobile ? 13 : 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: isMobile ? 12 : 16),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              _buildStatusChip(
                                                'Available',
                                                availableCount,
                                                Colors.green,
                                                isMobile,
                                              ),
                                              SizedBox(height: 10),
                                              _buildStatusChip(
                                                'Occupied',
                                                occupiedCount,
                                                Colors.orange,
                                                isMobile,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Available' ? Icons.check_circle : Icons.circle,
            size: isMobile ? 14 : 16,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
