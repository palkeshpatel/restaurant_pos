import 'package:flutter/material.dart';
import '../models/floor.dart';
import '../models/table.dart' as model;
import 'pos_screen.dart';
import 'settings_screen.dart';

class TableSelectionScreen extends StatefulWidget {
  final Floor floor;
  final Function(ThemeData) onThemeChange;

  const TableSelectionScreen({
    super.key,
    required this.floor,
    required this.onThemeChange,
  });

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final List<model.TableModel> tables = [
    model.TableModel(name: 'Table 1', icon: Icons.table_restaurant),
    model.TableModel(name: 'Table 2', icon: Icons.table_restaurant),
    model.TableModel(name: 'Table 3', icon: Icons.table_restaurant),
    model.TableModel(name: 'Table 4', icon: Icons.table_restaurant),
    model.TableModel(name: 'Table 5', icon: Icons.table_restaurant),
    model.TableModel(name: 'Table 6', icon: Icons.table_restaurant),
  ];

  void _selectTable(model.TableModel table) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => POSScreen(onThemeChange: widget.onThemeChange),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select Table',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.floor.name,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
                    crossAxisCount: isMobile ? 2 : 3,
                    mainAxisSpacing: isMobile ? 12 : 20,
                    crossAxisSpacing: isMobile ? 12 : 20,
                    childAspectRatio: isMobile ? 1.1 : 1,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => _selectTable(table),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 8 : 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  table.icon,
                                  size: isMobile ? 28 : 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              Flexible(
                                child: Text(
                                  table.name,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
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

