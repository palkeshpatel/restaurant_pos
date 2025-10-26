import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'pos_screen.dart';
import 'kitchen_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  MenuLayout _selectedLayout = MenuLayout.top;

  @override
  void initState() {
    super.initState();
    final settingsProvider = context.read<SettingsProvider>();
    _isDarkMode = settingsProvider.isDarkMode;
    _selectedLayout = settingsProvider.menuLayout;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a2a3a),
      body: SafeArea(
        child: Column(
          children: [
            // Mobile Top Navigation Bar
            if (isMobile) _buildMobileTopNav(),
            
            // Settings Content
            Expanded(
              child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu Layout Section
                _buildSection(
                  title: '🧭 Menu Layout',
                  description: 'Choose where the main navigation bar appears.',
                  child: Column(
                    children: [
                      _buildRadioButton(
                        'Top',
                        MenuLayout.top,
                        _selectedLayout,
                        (value) {
                          setState(() {
                            _selectedLayout = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildRadioButton(
                        'Left',
                        MenuLayout.left,
                        _selectedLayout,
                        (value) {
                          setState(() {
                            _selectedLayout = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildRadioButton(
                        'Right',
                        MenuLayout.right,
                        _selectedLayout,
                        (value) {
                          setState(() {
                            _selectedLayout = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Theme Section
                _buildSection(
                  title: '🌗 Theme',
                  description: 'Choose your preferred color theme.',
                  child: Column(
                    children: [
                      _buildRadioButton(
                        'Dark Mode',
                        true,
                        _isDarkMode,
                        (value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                        isTheme: true,
                      ),
                      const SizedBox(height: 12),
                      _buildRadioButton(
                        'Light Mode',
                        false,
                        _isDarkMode,
                        (value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                        isTheme: true,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await settingsProvider.setMenuLayout(_selectedLayout);
                      await settingsProvider.setTheme(_isDarkMode);
                      await settingsProvider.saveSettings();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Settings saved successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196f3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '💾 Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMobileTopNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1a2a3a),
        border: Border(
          bottom: BorderSide(color: Colors.white, width: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavButton(
              icon: Icons.description_outlined,
              label: 'Orders',
              isActive: false,
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const POSScreen()),
              ),
            ),
          ),
          Expanded(
            child: _buildNavButton(
              icon: Icons.restaurant_menu,
              label: 'Menu',
              isActive: false,
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const POSScreen()),
              ),
            ),
          ),
          Expanded(
            child: _buildNavButton(
              icon: Icons.grid_view,
              label: 'Categories',
              isActive: false,
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const POSScreen()),
              ),
            ),
          ),
          Expanded(
            child: _buildNavButton(
              icon: Icons.room_service,
              label: 'Kitchen',
              isActive: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const KitchenScreen()),
              ),
            ),
          ),
          Expanded(
            child: _buildNavButton(
              icon: Icons.settings,
              label: 'Setting',
              isActive: true,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2196f3) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4fc3f7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioButton<T>(
    String label,
    T value,
    T groupValue,
    ValueChanged<T> onChanged, {
    bool isTheme = false,
  }) {
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196f3).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196f3)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2196f3)
                      : Colors.white70,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.radio_button_checked,
                        color: Color(0xFF2196f3),
                        size: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
