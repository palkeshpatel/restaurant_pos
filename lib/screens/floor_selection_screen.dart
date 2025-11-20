import 'package:flutter/material.dart';
import '../models/floor.dart';
import 'table_selection_screen.dart';
import 'settings_screen.dart';

class FloorSelectionScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const FloorSelectionScreen({super.key, required this.onThemeChange});

  @override
  State<FloorSelectionScreen> createState() => _FloorSelectionScreenState();
}

class _FloorSelectionScreenState extends State<FloorSelectionScreen> {
  final List<Floor> floors = [
    Floor(name: 'Ground Floor', icon: Icons.home),
    Floor(name: 'First Floor', icon: Icons.stairs),
    Floor(name: 'Second Floor', icon: Icons.location_city),
    Floor(name: 'Outdoor', icon: Icons.deck),
  ];

  void _selectFloor(Floor floor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableSelectionScreen(
          floor: floor,
          onThemeChange: widget.onThemeChange,
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsScreen(onThemeChange: widget.onThemeChange),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                    iconSize: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 8 : 20),
                  Expanded(
                    child: Text(
                      'Select Floor',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showSettings,
                    icon: const Icon(Icons.settings),
                    color: Theme.of(context).colorScheme.primary,
                    iconSize: isMobile ? 20 : 24,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 2,
                    mainAxisSpacing: isMobile ? 12 : 20,
                    crossAxisSpacing: isMobile ? 12 : 20,
                    childAspectRatio: isMobile ? 2.5 : 1.1,
                  ),
                  itemCount: floors.length,
                  itemBuilder: (context, index) {
                    final floor = floors[index];
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        onTap: () => _selectFloor(floor),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  floor.icon,
                                  size: isMobile ? 32 : 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: isMobile ? 12 : 15),
                              Expanded(
                                child: Text(
                                  floor.name,
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.left,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
}

