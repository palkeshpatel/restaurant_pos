import 'package:flutter/material.dart';
import '../models/user.dart';
import 'admin_pin_screen.dart';
import 'settings_screen.dart';

class AdminListScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const AdminListScreen({super.key, required this.onThemeChange});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  final List<User> admins = [
    User(name: 'Admin 1', role: 'Administrator', avatar: 'A1'),
    User(name: 'Admin 2', role: 'Administrator', avatar: 'A2'),
    User(name: 'Admin 3', role: 'Administrator', avatar: 'A3'),
    User(name: 'Super Admin', role: 'Super Administrator', avatar: 'SA'),
  ];

  void _selectAdmin(User admin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminPinScreen(admin: admin, onThemeChange: widget.onThemeChange),
      ),
    );
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
                      'Select Admin',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w600,
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
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: ListView.builder(
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.only(bottom: isMobile ? 10 : 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: isMobile ? 24 : 30,
                          backgroundColor: Colors.indigo,
                          child: Text(
                            admin.avatar,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          admin.name,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          admin.role,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        onTap: () => _selectAdmin(admin),
                        contentPadding: EdgeInsets.all(isMobile ? 12 : 20),
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
}

