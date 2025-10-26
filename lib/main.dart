import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pos_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const RestaurantPOSApp());
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => POSProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Gourmet Restaurant POS',
            theme: _buildTheme(settingsProvider),
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            // Enhanced app configuration
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(SettingsProvider settingsProvider) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      // fontFamily: 'Poppins', // Using system fonts for now
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SettingsProvider.primaryColor,
        brightness: Brightness.dark,
        primary: SettingsProvider.primaryColor,
        secondary: SettingsProvider.secondaryColor,
        tertiary: SettingsProvider.accentColor,
        background: SettingsProvider.backgroundColor,
        surface: SettingsProvider.surfaceColor,
      ),
      // Enhanced text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      // Enhanced card theme
      cardTheme: const CardThemeData(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.all(8),
      ),
      // Enhanced elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: SettingsProvider.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      // Enhanced input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SettingsProvider.surfaceColor.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: SettingsProvider.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: SettingsProvider.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      // Enhanced app bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: SettingsProvider.backgroundColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
    );

    // Add custom gradients and colors
    return baseTheme.copyWith(
      extensions: [
        RestaurantThemeExtension(
          restaurantGradient: SettingsProvider.darkGradient,
          statusColors: const {
            'fire': Color(0xFFE53E3E),
            'hold': Color(0xFFFFA500),
            'served': Color(0xFF48BB78),
          },
        ),
      ],
    );
  }
}

class RestaurantThemeExtension extends ThemeExtension<RestaurantThemeExtension> {
  final LinearGradient restaurantGradient;
  final Map<String, Color> statusColors;

  RestaurantThemeExtension({
    required this.restaurantGradient,
    required this.statusColors,
  });

  @override
  RestaurantThemeExtension copyWith({
    LinearGradient? restaurantGradient,
    Map<String, Color>? statusColors,
  }) {
    return RestaurantThemeExtension(
      restaurantGradient: restaurantGradient ?? this.restaurantGradient,
      statusColors: statusColors ?? this.statusColors,
    );
  }

  @override
  RestaurantThemeExtension lerp(RestaurantThemeExtension? other, double t) {
    if (other == null) return this;
    return RestaurantThemeExtension(
      restaurantGradient: restaurantGradient,
      statusColors: statusColors,
    );
  }
}