import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/employee.dart';
import '../models/current_employee.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/avatar_widget.dart';
import 'pin_screen.dart';
import 'floor_selection_screen.dart';
import 'settings_screen.dart';

class UserListScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;
  final Role? role;

  const UserListScreen({super.key, required this.onThemeChange, this.role});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  CurrentEmployee? _currentEmployee;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployee();
  }

  Future<void> _loadCurrentEmployee() async {
    final currentEmployee = await StorageService.getCurrentEmployee();
    setState(() {
      _currentEmployee = currentEmployee;
    });
  }

  List<Employee> get employees {
    if (widget.role == null) return [];
    return widget.role!.employees.where((e) => e.isActive).toList();
  }

  bool _isEmployeeLoggedIn(Employee employee) {
    return _currentEmployee != null &&
        _currentEmployee!.employee.id == employee.id;
  }

  Future<void> _selectEmployee(Employee employee) async {
    // Check if this employee is already logged in
    if (_currentEmployee != null &&
        _currentEmployee!.employee.id == employee.id) {
      // Same user already logged in, go directly to floor selection
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FloorSelectionScreen(
              onThemeChange: widget.onThemeChange,
            ),
          ),
        );
      }
      return;
    }

    // Check if there's a different logged-in employee
    if (_currentEmployee != null &&
        _currentEmployee!.employee.id != employee.id) {
      // Show popup to logout previous user
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('User Already Logged In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${_currentEmployee!.employee.fullName} is currently logged in.'),
              const SizedBox(height: 8),
              const Text('Do you want to logout and login as this user?'),
            ],
          ),
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
              child: const Text('Logout & Continue'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Logout previous user
        await ApiService.logoutEmployee();
        await StorageService.removeCurrentEmployee();
        setState(() {
          _currentEmployee = null;
        });

        // Navigate to PIN screen for new employee
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PinScreen(
                employee: employee,
                roleName: widget.role?.name ?? 'Waiter',
                onThemeChange: widget.onThemeChange,
              ),
            ),
          );
        }
      }
    } else {
      // No user logged in, go to PIN screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(
            employee: employee,
            roleName: widget.role?.name ?? 'Waiter',
            onThemeChange: widget.onThemeChange,
          ),
        ),
      );
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
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
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
                      widget.role?.name ?? 'Select User',
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
                          final isLoggedIn = _isEmployeeLoggedIn(employee);
                          return Container(
                            margin: EdgeInsets.only(bottom: isMobile ? 12 : 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFF5EC),
                                  Colors.white,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ListTile(
                              onTap: () => _selectEmployee(employee),
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AvatarWidget(
                                    imageUrl: employee.avatar,
                                    initials: employee.initials,
                                    radius: isMobile ? 28 : 34,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  if (isLoggedIn)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: isMobile ? 12 : 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                employee.fullName,
                                style: TextStyle(
                                  fontSize: isMobile ? 17 : 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.email,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: isMobile ? 13 : 14,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    _StatusBadge(
                                      label: isLoggedIn
                                          ? 'Active session'
                                          : (employee.isActive
                                              ? 'Active'
                                              : 'Offline'),
                                      isActive: isLoggedIn || employee.isActive,
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade500,
                                size: isMobile ? 22 : 26,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 14 : 22,
                                vertical: isMobile ? 12 : 18,
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
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StatusBadge({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
