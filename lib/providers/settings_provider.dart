import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MenuLayout {
  top,
  left,
  right,
}

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  MenuLayout _menuLayout = MenuLayout.top;
  
  bool get isDarkMode => _isDarkMode;
  MenuLayout get menuLayout => _menuLayout;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    final layoutIndex = prefs.getInt('menuLayout') ?? 0;
    _menuLayout = MenuLayout.values[layoutIndex];
    notifyListeners();
  }
  
  Future<void> setTheme(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }
  
  Future<void> setMenuLayout(MenuLayout layout) async {
    _menuLayout = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('menuLayout', layout.index);
    notifyListeners();
  }
  
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setInt('menuLayout', _menuLayout.index);
    notifyListeners();
  }
}
