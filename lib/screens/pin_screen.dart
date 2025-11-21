import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/current_employee.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'floor_selection_screen.dart';
import 'settings_screen.dart';
import '../widgets/avatar_widget.dart';

class PinScreen extends StatefulWidget {
  final Employee? employee;
  final String roleName;
  final Function(ThemeData) onThemeChange;

  const PinScreen({
    super.key,
    this.employee,
    required this.roleName,
    required this.onThemeChange,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String pin = '';
  bool _isLoading = false;
  bool _pinComplete = false;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final currentEmployee = await StorageService.getCurrentEmployee();
    if (currentEmployee != null &&
        widget.employee != null &&
        currentEmployee.employee.id == widget.employee!.id) {
      // Same user already logged in, navigate directly
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FloorSelectionScreen(onThemeChange: widget.onThemeChange),
          ),
        );
      }
    }
  }

  void _addDigit(String digit) {
    if (pin.length < 4 && !_isLoading) {
      setState(() {
        pin += digit;
        _pinComplete = pin.length == 4;
      });
      if (pin.length == 4) {
        _verifyPin();
      }
    }
  }

  Future<void> _verifyPin() async {
    if (widget.employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee information is missing')),
      );
      setState(() {
        pin = '';
        _pinComplete = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.verifyPin(widget.employee!.id, pin);

      if (response.success && response.data != null) {
        // Save current employee
        final currentEmployee = CurrentEmployee(
          employee: response.data!.employee,
          token: response.data!.token,
          loginTime: DateTime.now(),
          roleName: widget.roleName,
        );
        await StorageService.saveCurrentEmployee(currentEmployee);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FloorSelectionScreen(onThemeChange: widget.onThemeChange),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
          setState(() {
            pin = '';
            _isLoading = false;
            _pinComplete = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          pin = '';
          _isLoading = false;
          _pinComplete = false;
        });
      }
    }
  }

  void _removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
        _pinComplete = false;
      });
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
    final theme = Theme.of(context);
    final primary = Colors.deepOrangeAccent;
    final avatarInitials = widget.employee?.initials ?? 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        Icon(Icons.arrow_back_ios_new_rounded, color: primary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _showSettings,
                    icon: const Icon(Icons.settings_outlined),
                    color: primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          offset: const Offset(-6, -6),
                          blurRadius: 16,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(10, 16),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarWidget(
                          imageUrl: widget.employee?.avatar,
                          initials: avatarInitials,
                          radius: 38,
                          backgroundColor: primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enter PIN',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.employee != null
                              ? 'Welcome back, ${widget.employee!.fullName}'
                              : 'Secure access to continue',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isFilled = index < pin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              width: isFilled ? 28 : 24,
                              height: isFilled ? 28 : 24,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isFilled
                                    ? (_pinComplete ? Colors.green : primary)
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                boxShadow: isFilled
                                    ? [
                                        BoxShadow(
                                          color: (_pinComplete
                                                  ? Colors.green
                                                  : primary)
                                              .withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 1,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            if (index == 9) {
                              return _buildPinButton(
                                icon: Icons.backspace_rounded,
                                onTap: _removeDigit,
                                primary: primary,
                              );
                            } else if (index == 11) {
                              return _buildPinButton(
                                icon: Icons.check_circle_rounded,
                                onTap: () {
                                  if (pin.length == 4 && !_isLoading) {
                                    _verifyPin();
                                  }
                                },
                                primary: primary,
                              );
                            } else {
                              final digit =
                                  index == 10 ? '0' : (index + 1).toString();
                              return _buildPinButton(
                                text: digit,
                                onTap: () => _addDigit(digit),
                                primary: primary,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinButton({
    String? text,
    IconData? icon,
    required VoidCallback onTap,
    required Color primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: primary.withOpacity(0.4), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: text != null
              ? Text(
                  text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                )
              : Icon(icon, size: 26, color: primary),
        ),
      ),
    );
  }
}
