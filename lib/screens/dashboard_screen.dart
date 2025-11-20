import 'package:flutter/material.dart';
import 'user_list_screen.dart';
import 'floor_selection_screen.dart';
import 'settings_screen.dart';
import 'admin_list_screen.dart';
import 'hotel_safe_login_screen.dart';
import '../models/login_response.dart';
import '../models/role.dart';
import '../models/current_employee.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;
  final LoginResponse? loginResponse;

  const DashboardScreen({
    super.key,
    required this.onThemeChange,
    this.loginResponse,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CurrentEmployee? _currentEmployee;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployee();
  }

  Future<void> _loadCurrentEmployee() async {
    final currentEmployee = await StorageService.getCurrentEmployee();
    if (mounted) {
      setState(() {
        _currentEmployee = currentEmployee;
      });
    }
  }

  bool _isRoleActive(Role role) {
    if (_currentEmployee == null) return false;
    // Check if any employee in this role matches the logged-in employee
    return role.employees.any((emp) => emp.id == _currentEmployee!.employee.id);
  }
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsScreen(onThemeChange: widget.onThemeChange),
      backgroundColor: Colors.transparent,
    );
  }

  void _navigateToRole(Role role) {
    final roleName = role.name.toLowerCase();
    
    if (roleName.contains('waiter')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserListScreen(
            onThemeChange: widget.onThemeChange,
            role: role,
          ),
        ),
      );
    } else if (roleName.contains('hotel safe') || roleName.contains('safe')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelSafeLoginScreen(
            onThemeChange: widget.onThemeChange,
            role: role,
          ),
        ),
      );
    } else if (roleName.contains('admin')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminListScreen(
            onThemeChange: widget.onThemeChange,
            role: role,
          ),
        ),
      );
    } else if (roleName.contains('executive') || roleName.contains('manager') || roleName.contains('owner')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminListScreen(
            onThemeChange: widget.onThemeChange,
            role: role,
          ),
        ),
      );
    } else {
      // Default to user list screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserListScreen(
            onThemeChange: widget.onThemeChange,
            role: role,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  Expanded(
                    child: Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 28,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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
            // Dashboard Content
            Expanded(
              child: Container(
                color: const Color(0xFFFFF3E0),
                padding: EdgeInsets.all(isMobile ? 12 : 40),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 2,
                    crossAxisSpacing: isMobile ? 12 : 20,
                    mainAxisSpacing: isMobile ? 12 : 20,
                    childAspectRatio: isMobile 
                      ? (screenWidth < 400 ? 3.5 : 3.2)
                      : 1.6,
                  ),
                  itemCount: _getDashboardItems().length,
                  itemBuilder: (context, index) {
                    final item = _getDashboardItems()[index];
                    final isActive = item.role != null && _isRoleActive(item.role!);
                    final hasAnyLoggedIn = _currentEmployee != null;
                    return _DashboardCard(
                      item: item,
                      onTap: () {
                        if (item.role != null) {
                          _navigateToRole(item.role!);
                        }
                      },
                      themeColor: Theme.of(context).colorScheme.primary,
                      isMobile: isMobile,
                      isActive: isActive,
                      hasAnyLoggedIn: hasAnyLoggedIn,
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

  List<DashboardItem> _getDashboardItems() {
    if (widget.loginResponse == null || widget.loginResponse!.roles.isEmpty) {
      // Return default items if no login response
      return [
        DashboardItem(
          title: 'Waiter',
          subtitle: 'Access for Waiters & Service Staff',
          icon: Icons.people,
          color: Colors.blue,
          route: 'staff_waiter',
        ),
        DashboardItem(
          title: 'Hotel Safe',
          subtitle: 'Safe Access',
          icon: Icons.security,
          color: Colors.brown,
          route: 'staff_safe',
        ),
        DashboardItem(
          title: 'Administrator',
          subtitle: 'Full System Configuration Access',
          icon: Icons.admin_panel_settings,
          color: Colors.indigo,
          route: 'admin',
        ),
        DashboardItem(
          title: 'Owner / Executive',
          subtitle: 'Highest Level Financial & Reporting Access',
          icon: Icons.business,
          color: Colors.amber,
          route: 'owner',
        ),
      ];
    }

    // Map roles to dashboard items
    return widget.loginResponse!.roles.map((role) {
      final roleName = role.name.toLowerCase();
      String title = role.name;
      String subtitle = '';
      IconData icon = Icons.person;
      Color color = Colors.blue;

      if (roleName.contains('waiter')) {
        title = 'Waiter';
        subtitle = 'Access for Waiters & Service Staff';
        icon = Icons.people;
        color = Colors.blue;
      } else if (roleName.contains('hotel safe') || roleName.contains('safe')) {
        title = 'Hotel Safe';
        subtitle = 'Safe Access';
        icon = Icons.security;
        color = Colors.brown;
      } else if (roleName.contains('admin')) {
        title = 'Administrator';
        subtitle = 'Full System Configuration Access';
        icon = Icons.admin_panel_settings;
        color = Colors.indigo;
      } else if (roleName.contains('executive') || roleName.contains('manager') || roleName.contains('owner')) {
        title = 'Owner / Executive';
        subtitle = 'Highest Level Financial & Reporting Access';
        icon = Icons.business;
        color = Colors.amber;
      } else {
        subtitle = 'Access for ${role.name} Staff';
        icon = Icons.person;
        color = Colors.grey;
      }

      return DashboardItem(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        route: roleName,
        role: role,
      );
    }).toList();
  }
}

class DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final Role? role;

  DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.role,
  });
}

class _DashboardCard extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;
  final Color themeColor;
  final bool isMobile;
  final bool isActive;
  final bool hasAnyLoggedIn;

  const _DashboardCard({
    required this.item,
    required this.onTap,
    required this.themeColor,
    required this.isMobile,
    this.isActive = false,
    this.hasAnyLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isMobile ? 28.0 : 48.0;
    final padding = isMobile ? 10.0 : 24.0;
    final titleFontSize = isMobile ? 15.0 : 20.0;
    final subtitleFontSize = isMobile ? 11.0 : 14.0;
    final iconPadding = isMobile ? 8.0 : 16.0;
    final spacing = isMobile ? 8.0 : 16.0;
    
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasAnyLoggedIn
                  ? [
                      if (isActive)
                        Colors.green.withOpacity(0.1)
                      else
                        item.color.withOpacity(0.05),
                      if (isActive)
                        Colors.green.withOpacity(0.05)
                      else
                        item.color.withOpacity(0.02),
                    ]
                  : [
                      item.color.withOpacity(0.1),
                      item.color.withOpacity(0.05),
                    ],
            ),
            border: hasAnyLoggedIn && isActive
                ? Border.all(color: Colors.green, width: 2)
                : hasAnyLoggedIn && !isActive
                    ? Border.all(color: Colors.grey.shade300, width: 1)
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: iconSize,
                  color: item.color,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: themeColor,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasAnyLoggedIn)
                          Container(
                            padding: EdgeInsets.all(isMobile ? 4 : 6),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isActive ? Icons.check_circle : Icons.lock,
                              size: isMobile ? 16 : 20,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
}
