import 'package:flutter/material.dart';
import '../models/user.dart';
import 'pin_screen.dart';
import 'settings_screen.dart';

class UserListScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const UserListScreen({super.key, required this.onThemeChange});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final List<User> users = [
    User(name: 'John', role: 'Waiter', avatar: 'J'),
    User(name: 'Sarah', role: 'Waiter', avatar: 'S'),
    User(name: 'Mike', role: 'Waiter', avatar: 'M'),
    User(name: 'Emma', role: 'Waiter', avatar: 'E'),
  ];

  void _selectUser(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinScreen(user: user, onThemeChange: widget.onThemeChange),
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
                      'Select User',
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
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.only(bottom: isMobile ? 10 : 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: isMobile ? 24 : 30,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user.avatar,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          user.role,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        onTap: () => _selectUser(user),
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