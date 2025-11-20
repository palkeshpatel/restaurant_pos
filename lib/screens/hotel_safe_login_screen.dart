import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'hotel_safe_screen.dart';
import 'hotel_safe_pin_screen.dart';
import '../models/role.dart';
import '../models/employee.dart';
import '../widgets/avatar_widget.dart';

class HotelSafeLoginScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;
  final Role? role;

  const HotelSafeLoginScreen({
    super.key,
    required this.onThemeChange,
    this.role,
  });

  @override
  State<HotelSafeLoginScreen> createState() => _HotelSafeLoginScreenState();
}

class _HotelSafeLoginScreenState extends State<HotelSafeLoginScreen> {
  List<Employee> get employees {
    if (widget.role == null) return [];
    return widget.role!.employees.where((e) => e.isActive).toList();
  }

  void _selectEmployee(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelSafePinScreen(
          employee: employee,
          roleName: widget.role?.name ?? 'Hotel Safe',
          onThemeChange: widget.onThemeChange,
        ),
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
                      widget.role?.name ?? 'Hotel Safe',
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
                child: employees.isEmpty
                    ? Center(
                        child: Text(
                          'No employees found',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          return Card(
                            elevation: 5,
                            margin: EdgeInsets.only(bottom: isMobile ? 10 : 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: AvatarWidget(
                                imageUrl: employee.avatar,
                                initials: employee.initials,
                                radius: isMobile ? 24 : 30,
                                backgroundColor: Colors.brown,
                              ),
                              title: Text(
                                employee.fullName,
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                employee.email,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: isMobile ? 13 : 14,
                                ),
                              ),
                              onTap: () => _selectEmployee(employee),
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

