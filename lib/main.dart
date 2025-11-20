import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'themes/app_themes.dart';

void main() {
  runApp(const RestaurantPOSApp());
}

class RestaurantPOSApp extends StatefulWidget {
  const RestaurantPOSApp({super.key});

  @override
  State<RestaurantPOSApp> createState() => _RestaurantPOSAppState();
}

class _RestaurantPOSAppState extends State<RestaurantPOSApp> {
  ThemeData _currentTheme = AppThemes.redYellowTheme;

  void changeTheme(ThemeData newTheme) {
    setState(() {
      _currentTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant POS',
      theme: _currentTheme,
      home: LoginScreen(onThemeChange: changeTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}