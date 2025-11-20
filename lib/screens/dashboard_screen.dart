import 'package:flutter/material.dart';
import 'user_list_screen.dart';
import 'floor_selection_screen.dart';
import 'settings_screen.dart';
import 'admin_list_screen.dart';
import 'hotel_safe_login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const DashboardScreen({super.key, required this.onThemeChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsScreen(onThemeChange: widget.onThemeChange),
      backgroundColor: Colors.transparent,
    );
  }

  void _navigateToUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListScreen(onThemeChange: widget.onThemeChange),
      ),
    );
  }

  void _navigateToFloors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FloorSelectionScreen(onThemeChange: widget.onThemeChange),
      ),
    );
  }

  void _navigateToAdmins() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminListScreen(onThemeChange: widget.onThemeChange),
      ),
    );
  }

  void _navigateToHotelSafe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelSafeLoginScreen(onThemeChange: widget.onThemeChange),
      ),
    );
  }

  void _navigateToOwner() {
    // Navigate to owner screen (similar to admin for now)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminListScreen(onThemeChange: widget.onThemeChange),
      ),
    );
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
                  itemCount: _dashboardItems.length,
                  itemBuilder: (context, index) {
                    return _DashboardCard(
                      item: _dashboardItems[index],
                      onTap: () {
                        switch (_dashboardItems[index].route) {
                          case 'staff_waiter':
                            _navigateToUsers();
                            break;
                          case 'staff_safe':
                            _navigateToHotelSafe();
                            break;
                          case 'admin':
                            _navigateToAdmins();
                            break;
                          case 'owner':
                            _navigateToOwner();
                            break;
                        }
                      },
                      themeColor: Theme.of(context).colorScheme.primary,
                      isMobile: isMobile,
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

  final List<DashboardItem> _dashboardItems = [
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

class DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _DashboardCard extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;
  final Color themeColor;
  final bool isMobile;

  const _DashboardCard({
    required this.item,
    required this.onTap,
    required this.themeColor,
    required this.isMobile,
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
              colors: [
                item.color.withOpacity(0.1),
                item.color.withOpacity(0.05),
              ],
            ),
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
                    Text(
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
