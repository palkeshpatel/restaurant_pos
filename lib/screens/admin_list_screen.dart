import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/employee.dart';
import 'admin_pin_screen.dart';
import 'settings_screen.dart';

class AdminListScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;
  final Role? role;

  const AdminListScreen({super.key, required this.onThemeChange, this.role});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  List<Employee> get employees {
    if (widget.role == null) return [];
    return widget.role!.employees.where((e) => e.isActive).toList();
  }

  void _selectEmployee(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminPinScreen(
          employee: employee,
          roleName: widget.role?.name ?? 'Admin',
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
                      widget.role?.name ?? 'Select Admin',
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
                          final initials = employee.firstName.isNotEmpty && employee.lastName.isNotEmpty
                              ? '${employee.firstName[0]}${employee.lastName[0]}'
                              : employee.firstName.isNotEmpty
                                  ? employee.firstName[0]
                                  : 'A';
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
                                  initials.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
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

