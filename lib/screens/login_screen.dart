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
        Color(0xFF0E7CFF),
        Color(0xFF4C9DFF),
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
              color: const Color(0xFF0E7CFF).withOpacity(0.35),
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

  void _showCreateAccountInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Please contact your administrator to create an account.'),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0F63FF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: isMobile ? -30 : -10,
              left: -60,
              child: _Blob(
                size: isMobile ? 180 : 260,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            Positioned(
              top: screenHeight * 0.15,
              right: -40,
              child: _Blob(
                size: isMobile ? 140 : 200,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            const SizedBox.shrink(),
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipPath(
                clipper: _WaveClipper(),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.55,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 24 : 48,
                    isMobile ? 28 : 48,
                    isMobile ? 24 : 48,
                    isMobile ? 32 : 48,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: isMobile ? 12 : 18),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 28),
                        _buildInputLabel('Email'),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'name@restaurant.com',
                          icon: Icons.email_outlined,
                        ),
                        SizedBox(height: isMobile ? 18 : 22),
                        _buildInputLabel('Password'),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordMessage,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0F63FF),
                              padding: EdgeInsets.zero,
                              textStyle: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        _PrimaryGradientButton(
                          isLoading: _isLoading,
                          onTap: _login,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 18 : 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            TextButton(
                              onPressed: _showCreateAccountInfo,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0F63FF),
                              ),
                              child: const Text('Create one'),
                            ),
                          ],
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0F63FF), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.08);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.02,
      size.width * 0.5,
      size.height * 0.06,
    );
    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.1,
      size.width,
      size.height * 0.04,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
