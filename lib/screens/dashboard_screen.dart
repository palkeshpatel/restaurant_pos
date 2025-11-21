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
    } else if (roleName.contains('executive') ||
        roleName.contains('manager') ||
        roleName.contains('owner')) {
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
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 18 : 32,
                isMobile ? 16 : 28,
                isMobile ? 18 : 32,
                isMobile ? 10 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Your Role',
                          style: TextStyle(
                            fontSize: isMobile ? 26 : 34,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showSettings,
                        icon: const Icon(Icons.settings_outlined),
                        color: Theme.of(context).colorScheme.primary,
                        iconSize: isMobile ? 20 : 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 6 : 10),
                  Text(
                    'Choose the workspace you want to dive into.',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Dashboard Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 32,
                  isMobile ? 8 : 24,
                  isMobile ? 16 : 32,
                  isMobile ? 16 : 32,
                ),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 2,
                    crossAxisSpacing: isMobile ? 12 : 20,
                    mainAxisSpacing: isMobile ? 12 : 20,
                    childAspectRatio:
                        isMobile ? (screenWidth < 400 ? 3.5 : 3.2) : 1.6,
                  ),
                  itemCount: _getDashboardItems().length,
                  itemBuilder: (context, index) {
                    final item = _getDashboardItems()[index];
                    final isActive =
                        item.role != null && _isRoleActive(item.role!);
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
      } else if (roleName.contains('executive') ||
          roleName.contains('manager') ||
          roleName.contains('owner')) {
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
    final padding = isMobile ? 16.0 : 24.0;
    final titleFontSize = isMobile ? 16.0 : 20.0;
    final subtitleFontSize = isMobile ? 12.0 : 14.0;
    final iconContainerSize = isMobile ? 58.0 : 72.0;
    final spacing = isMobile ? 14.0 : 20.0;

    final gradientColors = [
      item.color.withOpacity(0.18),
      item.color.withOpacity(0.08),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              offset: const Offset(-6, -6),
              blurRadius: 14,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(8, 10),
              blurRadius: 24,
            ),
            if (hasAnyLoggedIn && isActive)
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                offset: const Offset(0, 6),
                blurRadius: 20,
              ),
          ],
          border: Border.all(
            color: hasAnyLoggedIn && isActive
                ? Colors.green.withOpacity(0.6)
                : Colors.white.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color,
                    item.color.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                item.icon,
                size: iconSize,
                color: Colors.white,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.grey.shade700,
                        size: isMobile ? 18 : 22,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 6 : 10),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: isMobile ? 10 : 14),
                  if (hasAnyLoggedIn)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 14,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: (isActive ? Colors.green : Colors.grey)
                            .withOpacity(0.15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.lock,
                            size: isMobile ? 14 : 16,
                            color:
                                isActive ? Colors.green : Colors.grey.shade600,
                          ),
                          SizedBox(width: 6),
                          Text(
                            isActive ? 'Currently active' : 'Locked',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.green
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
