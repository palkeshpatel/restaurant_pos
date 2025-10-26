import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  bool _showBackgroundImages = true;
  double _animationSpeed = 1.0;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get showBackgroundImages => _showBackgroundImages;
  double get animationSpeed => _animationSpeed;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _showBackgroundImages = prefs.getBool('showBackgroundImages') ?? true;
    _animationSpeed = prefs.getDouble('animationSpeed') ?? 1.0;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('showBackgroundImages', _showBackgroundImages);
    await prefs.setDouble('animationSpeed', _animationSpeed);
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }

  void toggleBackgroundImages() {
    _showBackgroundImages = !_showBackgroundImages;
    _saveSettings();
    notifyListeners();
  }

  void setAnimationSpeed(double speed) {
    _animationSpeed = speed;
    _saveSettings();
    notifyListeners();
  }

  // Theme colors
  static const Color primaryColor = Color(0xFF4fc3f7);
  static const Color secondaryColor = Color(0xFFbb86fc);
  static const Color accentColor = Color(0xFF03dac6);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  // Dark theme gradient
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1a2a3a),
      Color(0xFF0d1b2a),
      Color(0xFF0a1420),
    ],
  );

  // Restaurant theme colors
  static const Color restaurantRed = Color(0xFFE53E3E);
  static const Color restaurantOrange = Color(0xFFFFA500);
  static const Color restaurantGreen = Color(0xFF48BB78);
  static const Color restaurantBlue = Color(0xFF3182CE);
}
