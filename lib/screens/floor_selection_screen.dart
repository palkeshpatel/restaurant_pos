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
            builder: (context) => DashboardScreen(onThemeChange: widget.onThemeChange),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
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
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
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
                padding: EdgeInsets.all(isMobile ? 12 : 20),
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
                                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile ? 1 : 2,
                                  mainAxisSpacing: isMobile ? 12 : 20,
                                  crossAxisSpacing: isMobile ? 12 : 20,
                                  childAspectRatio: isMobile ? 2.5 : 1.1,
                                ),
                                itemCount: floors.length,
                                itemBuilder: (context, index) {
                                  final floor = floors[index];
                                  final occupiedCount = floor.tables.where((t) => t.isOccupied).length;
                                  final availableCount = floor.tables.where((t) => t.isAvailable).length;
                                  return Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: InkWell(
                                      onTap: () => _selectFloor(floor),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                floor.icon,
                                                size: isMobile ? 32 : 48,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            SizedBox(width: isMobile ? 12 : 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    floor.name,
                                                    style: TextStyle(
                                                      fontSize: isMobile ? 16 : 18,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                    textAlign: TextAlign.left,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: isMobile ? 4 : 6),
                                                  Row(
                                                    children: [
                                                      _buildStatusChip(
                                                        'Available',
                                                        availableCount,
                                                        Colors.green,
                                                        isMobile,
                                                      ),
                                                      SizedBox(width: isMobile ? 6 : 8),
                                                      if (occupiedCount > 0)
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
                                          ],
                                        ),
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
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMobile ? 6 : 8,
            height: isMobile ? 6 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

