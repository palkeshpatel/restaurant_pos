import 'package:flutter/material.dart';
import '../models/employee.dart';
import 'settings_screen.dart';
import 'admin_employees_screen.dart';
import 'admin_items_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Employee? employee;
  final String roleName;
  final Function(ThemeData) onThemeChange;

  const AdminDashboardScreen({
    super.key,
    this.employee,
    required this.roleName,
    required this.onThemeChange,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedMenuIndex = 0;
  final List<MenuOption> _menuOptions = [
    MenuOption(title: 'Dashboard', icon: Icons.dashboard),
    MenuOption(title: 'Employees', icon: Icons.people),
    MenuOption(title: 'Items', icon: Icons.restaurant_menu),
  ];

  // Mock data for stats
  int todayOrders = 45;
  int liveOrders = 12;
  int totalRevenue = 1250;
  int activeTables = 8;

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsScreen(onThemeChange: widget.onThemeChange),
      backgroundColor: Colors.transparent,
    );
  }

  void _navigateToEmployees() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEmployeesScreen(onThemeChange: widget.onThemeChange),
      ),
    );
  }

  void _navigateToItems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminItemsScreen(onThemeChange: widget.onThemeChange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar Menu
            if (!isMobile)
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(2, 0),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child: Text(
                              widget.employee != null
                                  ? '${widget.employee!.firstName[0]}${widget.employee!.lastName[0]}'
                                  : 'A',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.employee != null
                                      ? widget.employee!.fullName
                                      : 'Admin',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.roleName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _menuOptions.length,
                        itemBuilder: (context, index) {
                          final option = _menuOptions[index];
                          final isSelected = _selectedMenuIndex == index;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedMenuIndex = index;
                              });
                              if (index == 1) {
                                _navigateToEmployees();
                              } else if (index == 2) {
                                _navigateToItems();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    option.icon,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    option.title,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Main Content
            Expanded(
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
                        if (isMobile)
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                          ),
                        Expanded(
                          child: Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 28,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        if (isMobile)
                          PopupMenuButton(
                            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.primary),
                            itemBuilder: (context) => _menuOptions.map((option) {
                              return PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(option.icon),
                                    const SizedBox(width: 12),
                                    Text(option.title),
                                  ],
                                ),
                                onTap: () {
                                  if (option.title == 'Employees') {
                                    _navigateToEmployees();
                                  } else if (option.title == 'Items') {
                                    _navigateToItems();
                                  }
                                },
                              );
                            }).toList(),
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
                  // Stats Boxes
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFFF3E0),
                      padding: EdgeInsets.all(isMobile ? 12 : 30),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          crossAxisSpacing: isMobile ? 12 : 20,
                          mainAxisSpacing: isMobile ? 12 : 20,
                          childAspectRatio: isMobile ? 2.8 : 1.6,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return _buildStatBox(index, isMobile);
                        },
                      ),
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

  Widget _buildStatBox(int index, bool isMobile) {
    final stats = [
      _StatData('Today Orders', todayOrders.toString(), Icons.receipt_long, Colors.orange),
      _StatData('Live Orders', liveOrders.toString(), Icons.restaurant, Colors.red),
      _StatData('Total Revenue', '\$$totalRevenue', Icons.attach_money, Colors.green),
      _StatData('Active Tables', activeTables.toString(), Icons.table_restaurant, Colors.blue),
    ];
    
    final stat = stats[index];
    
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              stat.color.withOpacity(0.1),
              stat.color.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: stat.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                stat.icon,
                size: isMobile ? 32 : 48,
                color: stat.color,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stat.value,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    stat.title,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class MenuOption {
  final String title;
  final IconData icon;

  MenuOption({required this.title, required this.icon});
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatData(this.title, this.value, this.icon, this.color);
}

