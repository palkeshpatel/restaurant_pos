import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import 'floor_layout_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a2a3a),
              Color(0xFF0d1b2a),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Logo/Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Color(0xFF4fc3f7),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Restaurant POS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter 6-digit PIN to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha:0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // PIN Display
                Consumer<POSProvider>(
                  builder: (context, posProvider, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4fc3f7),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final isFilled = index < posProvider.currentPIN.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isFilled ? const Color(0xFF4fc3f7) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4fc3f7),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Number Pad
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton(context, '1'),
                          _buildNumberButton(context, '2'),
                          _buildNumberButton(context, '3'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton(context, '4'),
                          _buildNumberButton(context, '5'),
                          _buildNumberButton(context, '6'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton(context, '7'),
                          _buildNumberButton(context, '8'),
                          _buildNumberButton(context, '9'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(context, 'Clear', () {
                            context.read<POSProvider>().clearPIN();
                            setState(() {
                              _errorMessage = '';
                            });
                          }),
                          _buildNumberButton(context, '0'),
                          _buildActionButton(context, 'Del', () {
                            context.read<POSProvider>().removeLastDigit();
                            setState(() {
                              _errorMessage = '';
                            });
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Error Message Display
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Login Button (only show if PIN is complete and no error)
                Consumer<POSProvider>(
                  builder: (context, posProvider, child) {
                    final isPINComplete = posProvider.currentPIN.length == 6;
                    final shouldShowButton = isPINComplete && _errorMessage.isEmpty;
                    
                    return shouldShowButton ? ElevatedButton(
                      onPressed: () => _handleLogin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4fc3f7),
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ) : const SizedBox.shrink();
                  },
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return Consumer<POSProvider>(
      builder: (context, posProvider, child) {
        final canAddDigit = posProvider.currentPIN.length < 6;
        
        return ElevatedButton(
          onPressed: canAddDigit ? () {
            posProvider.addDigitToPIN(number);
            // Auto-login when 6 digits are entered
            if (posProvider.currentPIN.length == 6) {
              _handleAutoLogin(context);
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAddDigit ? const Color(0xFF4fc3f7) : Colors.grey,
            padding: const EdgeInsets.all(16),
            shape: const CircleBorder(),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.all(16),
        shape: const CircleBorder(),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _handleAutoLogin(BuildContext context) {
    final posProvider = context.read<POSProvider>();
    final enteredPIN = posProvider.currentPIN;
    final isAuthenticated = posProvider.authenticatePIN(enteredPIN);
    
    if (isAuthenticated) {
      // Quick login - navigate immediately
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const FloorLayoutScreen(),
        ),
      );
    } else {
      // Show error message without login button
      setState(() {
        _errorMessage = 'Wrong password. Please try again.';
      });
      posProvider.clearPIN();
    }
  }

  void _handleLogin(BuildContext context) {
    final posProvider = context.read<POSProvider>();
    final enteredPIN = posProvider.currentPIN;
    final isAuthenticated = posProvider.authenticatePIN(enteredPIN);
    
    if (isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const FloorLayoutScreen(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Wrong password. Please try again.';
      });
      posProvider.clearPIN();
    }
  }
}
