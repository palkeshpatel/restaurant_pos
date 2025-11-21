import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import '../models/login_response.dart';

class LoginScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const LoginScreen({super.key, required this.onThemeChange});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _PrimaryGradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final bool isMobile;

  const _PrimaryGradientButton({
    required this.isLoading,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [
        Color(0xFFFF8A00),
        Color(0xFFFF3D00),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: isLoading ? null : onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        height: isMobile ? 20 : 24,
                        width: isMobile ? 20 : 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showForgotPasswordMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Please contact your administrator to reset your password.'),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.success && response.data != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                onThemeChange: widget.onThemeChange,
                loginResponse: response.data!,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1528605248644-14dd04022da1?auto=format&fit=crop&w=1600&q=80',
              ),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
            ),
          ),
          child: Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Restaurant POS',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Text(
                            'Sign in to access the system',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'your@email.com',
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.3,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(
                                top: isMobile ? 12 : 16,
                                bottom: isMobile ? 6 : 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 16 : 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.3,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(
                                top: isMobile ? 12 : 16,
                                bottom: isMobile ? 6 : 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordMessage,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.zero,
                            textStyle: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _PrimaryGradientButton(
                        isLoading: _isLoading,
                        onTap: _login,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
