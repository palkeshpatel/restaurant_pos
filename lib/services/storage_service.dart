import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/current_employee.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _baseUrlKey = 'base_url';
  static const String _currentEmployeeKey = 'current_employee';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
  }

  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? 'http://16.170.247.143';
  }

  static Future<void> saveCurrentEmployee(CurrentEmployee employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentEmployeeKey, jsonEncode(employee.toJson()));
    await saveToken(employee.token);
  }

  static Future<CurrentEmployee?> getCurrentEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeJson = prefs.getString(_currentEmployeeKey);
    if (employeeJson != null) {
      try {
        return CurrentEmployee.fromJson(jsonDecode(employeeJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> removeCurrentEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentEmployeeKey);
    await removeToken();
  }
}
