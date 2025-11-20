import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData redYellowTheme = ThemeData(
    primaryColor: const Color(0xFFFF5722),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF5722),
      secondary: Color(0xFFFF9800),
      background: Color(0xFFFFF9C4),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Color(0xFF333333),
      onSurface: Color(0xFF333333),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF9C4),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF5722),
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFFF5722),
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Color(0xFF333333),
      ),
    ),
  );

  static final ThemeData blueTealTheme = ThemeData(
    primaryColor: const Color(0xFF2196F3),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF009688),
      background: Color(0xFFE3F2FD),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Color(0xFF333333),
      onSurface: Color(0xFF333333),
    ),
    scaffoldBackgroundColor: const Color(0xFFE3F2FD),
    cardColor: Colors.white,
  );

  static final ThemeData purplePinkTheme = ThemeData(
    primaryColor: const Color(0xFF9C27B0),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF9C27B0),
      secondary: Color(0xFFE91E63),
      background: Color(0xFFF3E5F5),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Color(0xFF333333),
      onSurface: Color(0xFF333333),
    ),
    scaffoldBackgroundColor: const Color(0xFFF3E5F5),
    cardColor: Colors.white,
  );

  static final ThemeData greenLimeTheme = ThemeData(
    primaryColor: const Color(0xFF4CAF50),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4CAF50),
      secondary: Color(0xFFCDDC39),
      background: Color(0xFFF1F8E9),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Color(0xFF333333),
      onSurface: Color(0xFF333333),
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F8E9),
    cardColor: Colors.white,
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFFFF5722),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF5722),
      secondary: Color(0xFFFF9800),
      background: Color(0xFF424242),
      surface: Color(0xFF212121),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF424242),
    cardColor: const Color(0xFF212121),
  );
}