import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const SettingsScreen({super.key, required this.onThemeChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String currentTheme;

  final Map<String, Map<String, dynamic>> themes = {
    'red-yellow': {
      'name': 'Red & Yellow',
      'theme': AppThemes.redYellowTheme,
      'colors': [const Color(0xFFFF5722), const Color(0xFFFF9800)],
    },
    'blue-teal': {
      'name': 'Blue & Teal',
      'theme': AppThemes.blueTealTheme,
      'colors': [const Color(0xFF2196F3), const Color(0xFF009688)],
    },
    'purple-pink': {
      'name': 'Purple & Pink',
      'theme': AppThemes.purplePinkTheme,
      'colors': [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
    },
    'green-lime': {
      'name': 'Green & Lime',
      'theme': AppThemes.greenLimeTheme,
      'colors': [const Color(0xFF4CAF50), const Color(0xFFCDDC39)],
    },
    'dark': {
      'name': 'Dark Theme',
      'theme': AppThemes.darkTheme,
      'colors': [const Color(0xFF424242), const Color(0xFF212121)],
    },
  };

  @override
  void initState() {
    super.initState();
    currentTheme = 'red-yellow'; // Default theme
  }

  void _switchTheme(String themeKey) {
    setState(() {
      currentTheme = themeKey;
    });
    // Apply theme immediately
    widget.onThemeChange(themes[themeKey]!['theme'] as ThemeData);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Theme Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Theme list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: themes.length,
                  itemBuilder: (context, index) {
                    final themeKey = themes.keys.elementAt(index);
                    final theme = themes[themeKey]!;
                    final isSelected = currentTheme == themeKey;
                    
                    return Card(
                      elevation: isSelected ? 8 : 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _switchTheme(themeKey),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Color preview
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: theme['colors'] as List<Color>,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Theme name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      theme['name'] as String,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isSelected ? 'Currently Active' : 'Tap to activate',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected 
                                            ? Theme.of(context).colorScheme.primary 
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Switch/Check indicator
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary 
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary 
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}