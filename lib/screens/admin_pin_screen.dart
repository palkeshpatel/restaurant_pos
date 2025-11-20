import 'package:flutter/material.dart';
import '../models/user.dart';
import 'admin_dashboard_screen.dart';
import 'settings_screen.dart';

class AdminPinScreen extends StatefulWidget {
  final User admin;
  final Function(ThemeData) onThemeChange;

  const AdminPinScreen({super.key, required this.admin, required this.onThemeChange});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen> {
  String pin = '';

  void _addDigit(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
      });
      if (pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(admin: widget.admin, onThemeChange: widget.onThemeChange),
            ),
          );
        });
      }
    }
  }

  void _removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
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
                      'Enter Admin PIN',
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
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Enter Admin PIN',
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Text(
                            'Welcome, ${widget.admin.name}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            width: isMobile ? 16 : 20,
                            height: isMobile ? 16 : 20,
                            margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10),
                            decoration: BoxDecoration(
                              color: index < pin.length
                                  ? Colors.indigo
                                  : const Color(0xFFFFCCBC),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: isMobile ? 20 : 30),
                      GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: isMobile ? 12 : 15,
                          crossAxisSpacing: isMobile ? 12 : 15,
                          childAspectRatio: 1,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          if (index == 9) {
                            return _buildPinButton(
                              icon: Icons.backspace,
                              onTap: _removeDigit,
                              isMobile: isMobile,
                            );
                          } else if (index == 11) {
                            return _buildPinButton(
                              icon: Icons.check,
                              onTap: () {
                                if (pin.length == 4) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminDashboardScreen(admin: widget.admin, onThemeChange: widget.onThemeChange),
                                    ),
                                  );
                                }
                              },
                              isMobile: isMobile,
                            );
                          } else {
                            final digit = index == 10 ? '0' : (index + 1).toString();
                            return _buildPinButton(
                              text: digit,
                              onTap: () => _addDigit(digit),
                              isMobile: isMobile,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinButton({String? text, IconData? icon, required VoidCallback onTap, required bool isMobile}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: const Color(0xFFFFCCBC)),
        ),
        child: Center(
          child: text != null
              ? Text(
                  text,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Icon(icon, size: isMobile ? 20 : 24, color: Colors.black),
        ),
      ),
    );
  }
}

