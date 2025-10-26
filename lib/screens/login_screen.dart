import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/background_painter.dart';
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
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: SettingsProvider.darkGradient,
        ),
        child: Stack(
          children: [
            // Background pattern
            if (settingsProvider.showBackgroundImages)
              Positioned.fill(
                child: CustomPaint(
                  painter: RestaurantBackgroundPainter(
                    opacity: 0.08,
                  ),
                ),
              ),

            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Logo/Title
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: SettingsProvider.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  SettingsProvider.primaryColor,
                                  SettingsProvider.primaryColor.withOpacity(0.7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: SettingsProvider.primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'GOURMET',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Restaurant POS System',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: SettingsProvider.primaryColor,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: SettingsProvider.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: SettingsProvider.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Enter 6-digit PIN to continue',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: SettingsProvider.primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              final isFilled = index < posProvider.currentPIN.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isFilled
                                      ? SettingsProvider.primaryColor
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: SettingsProvider.primaryColor,
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: SettingsProvider.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
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
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SettingsProvider.restaurantRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SettingsProvider.restaurantRed.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: SettingsProvider.restaurantRed,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: SettingsProvider.restaurantRed,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Login Button (only show if PIN is complete and no error)
                    Consumer<POSProvider>(
                      builder: (context, posProvider, child) {
                        final isPINComplete = posProvider.currentPIN.length == 6;
                        final shouldShowButton = isPINComplete && _errorMessage.isEmpty;

                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: shouldShowButton ? 1.0 : 0.0,
                          child: shouldShowButton
                              ? Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        SettingsProvider.primaryColor,
                                        SettingsProvider.primaryColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SettingsProvider.primaryColor.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _handleLogin(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.login, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Login',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
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

  Widget _buildNumberButton(BuildContext context, String number) {
    return Consumer<POSProvider>(
      builder: (context, posProvider, child) {
        final canAddDigit = posProvider.currentPIN.length < 6;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: canAddDigit ? () {
              posProvider.addDigitToPIN(number);
              // Auto-login when 6 digits are entered
              if (posProvider.currentPIN.length == 6) {
                _handleAutoLogin(context);
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAddDigit
                  ? SettingsProvider.primaryColor
                  : Theme.of(context).disabledColor,
              padding: const EdgeInsets.all(20),
              shape: const CircleBorder(),
              elevation: canAddDigit ? 6 : 2,
              shadowColor: canAddDigit
                  ? SettingsProvider.primaryColor.withOpacity(0.3)
                  : Colors.transparent,
            ),
            child: Text(
              number,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
        backgroundColor: text == 'Clear'
            ? SettingsProvider.restaurantOrange
            : SettingsProvider.restaurantRed,
        padding: const EdgeInsets.all(20),
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: (text == 'Clear'
            ? SettingsProvider.restaurantOrange
            : SettingsProvider.restaurantRed).withOpacity(0.3),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
