import 'package:flutter/material.dart';
import '../models/floor.dart';
import '../models/table.dart' as model;
import '../models/reserve_table_response.dart';
import '../models/current_employee.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
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
  late List<model.TableModel> tables;
  CurrentEmployee? _currentEmployee;

  @override
  void initState() {
    super.initState();
    tables = List<model.TableModel>.from(widget.floor.tables);
    _loadCurrentEmployee();
  }

  Future<void> _loadCurrentEmployee() async {
    final currentEmployee = await StorageService.getCurrentEmployee();
    if (mounted) {
      setState(() {
        _currentEmployee = currentEmployee;
      });
    }
  }

  bool _isTableAccessible(model.TableModel table) {
    if (table.isAvailable) return true;
    if (_currentEmployee == null) return false;
    return table.occupiedByEmployeeId == _currentEmployee!.employee.id;
  }

  Color _getTableColor(model.TableModel table) {
    switch (table.status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.orange;
      case 'reserved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTableStatusText(model.TableModel table) {
    switch (table.status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'occupied':
        return table.orderTicketTitle ?? 'Occupied';
      case 'reserved':
        return 'Reserved';
      default:
        return table.status;
    }
  }

  IconData _getTableIcon(model.TableModel table) {
    switch (table.status.toLowerCase()) {
      case 'available':
        return Icons.table_restaurant;
      case 'occupied':
        return Icons.table_restaurant;
      case 'reserved':
        return Icons.event_seat;
      default:
        return Icons.table_restaurant;
    }
  }

  Future<void> _selectTable(model.TableModel table) async {
    if (!_isTableAccessible(table)) {
      final statusLabel = table.isReserved ? 'reserved' : 'occupied';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Table is currently $statusLabel.')),
      );
      return;
    }

    if (!table.isAvailable) {
      // Table belongs to this employee, navigate directly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => POSScreen(
            onThemeChange: widget.onThemeChange,
            floor: widget.floor,
            table: table,
          ),
        ),
      );
      return;
    }

    final response = await showModalBottomSheet<ReserveTableResponse>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReservationBottomSheet(table: table),
    );

    if (response != null && mounted) {
      final index = tables.indexWhere((t) => t.id == table.id);
      if (index != -1) {
        final updatedTable = tables[index].copyWith(
          status: 'occupied',
          orderTicketId: response.orderTicketId,
          orderTicketTitle: response.orderTicketTitle,
          occupiedByEmployeeId: _currentEmployee?.employee.id,
          occupiedByEmployeeName: _currentEmployee?.employee.fullName,
          occupiedByEmployeeAvatar: _currentEmployee?.employee.avatar,
        );
        setState(() {
          tables[index] = updatedTable;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Table reserved successfully')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => POSScreen(
              onThemeChange: widget.onThemeChange,
              floor: widget.floor,
              table: updatedTable,
            ),
          ),
        );
      }
    }
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
                    final tableColor = _getTableColor(table);
                    final statusText = _getTableStatusText(table);
                    final isOccupied = table.isOccupied;
                    final isReserved = table.isReserved;
                    final isInUse = table.isInUse;
                    final isOwnedByCurrent =
                        _currentEmployee != null && table.occupiedByEmployeeId == _currentEmployee!.employee.id;
                    
                    return Card(
                      elevation: isInUse ? 12 : 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: tableColor.withOpacity(isInUse ? 0.5 : 0.3),
                          width: isInUse ? 2 : 1,
                        ),
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
                                tableColor.withOpacity(isInUse ? 0.2 : 0.1),
                                tableColor.withOpacity(isInUse ? 0.1 : 0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                                    decoration: BoxDecoration(
                                      color: tableColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getTableIcon(table),
                                      size: isMobile ? 28 : 40,
                                      color: tableColor,
                                    ),
                                  ),
                                  if (isOccupied || isReserved)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: Icon(
                                          isReserved ? Icons.event_busy : Icons.restaurant,
                                          size: isMobile ? 10 : 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      table.name,
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: tableColor,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isMobile ? 4 : 6),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 6 : 8,
                                        vertical: isMobile ? 2 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tableColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: tableColor.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: isMobile ? 10 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: tableColor,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!table.isAvailable &&
                                        (table.occupiedByEmployeeName?.isNotEmpty ?? false)) ...[
                                      SizedBox(height: isMobile ? 4 : 6),
                                      Text(
                                        'By ${table.occupiedByEmployeeName}',
                                        style: TextStyle(
                                          fontSize: isMobile ? 10 : 12,
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (isOwnedByCurrent && !table.isAvailable) ...[
                                      SizedBox(height: isMobile ? 4 : 6),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 6 : 8,
                                          vertical: isMobile ? 2 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.teal.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          'My Table',
                                          style: TextStyle(
                                            fontSize: isMobile ? 10 : 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (table.capacity > 0) ...[
                                      SizedBox(height: isMobile ? 4 : 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.people,
                                            size: isMobile ? 10 : 12,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: isMobile ? 2 : 4),
                                          Text(
                                            '${table.capacity}',
                                            style: TextStyle(
                                              fontSize: isMobile ? 10 : 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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

class ReservationBottomSheet extends StatefulWidget {
  final model.TableModel table;

  const ReservationBottomSheet({super.key, required this.table});

  @override
  State<ReservationBottomSheet> createState() => _ReservationBottomSheetState();
}

class _ReservationBottomSheetState extends State<ReservationBottomSheet> {
  bool _applyAutoGratuity = true;
  bool _applyManualGratuity = false;
  String _gratuityType = 'percentage';
  final TextEditingController _gratuityValueController = TextEditingController(text: '10');
  final TextEditingController _notesController = TextEditingController();
  int _selectedGuests = 2;
  bool _isSubmitting = false;

  List<int> get _guestOptions => List.generate(12, (index) => index + 1);

  @override
  void dispose() {
    _gratuityValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleAuto(bool value) {
    setState(() {
      _applyAutoGratuity = value;
      if (value) {
        _applyManualGratuity = false;
      }
    });
  }

  void _toggleManual(bool value) {
    setState(() {
      _applyManualGratuity = value;
      if (value) {
        _applyAutoGratuity = false;
      }
    });
  }

  Future<void> _submit() async {
    if (_applyManualGratuity) {
      final parsedValue = double.tryParse(_gratuityValueController.text);
      if (parsedValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid gratuity value.')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final gratuityType = _applyManualGratuity
        ? _gratuityType
        : _applyAutoGratuity
            ? 'auto'
            : 'none';
    final gratuityValue = _applyManualGratuity ? double.tryParse(_gratuityValueController.text) ?? 0 : null;
    final notes = _notesController.text.trim();

    final response = await ApiService.reserveTable(
      tableId: widget.table.id,
      gratuityType: gratuityType,
      gratuityValue: gratuityValue,
      guestCount: _selectedGuests,
      orderNotes: [
        'Guests: $_selectedGuests',
        if (notes.isNotEmpty) notes,
      ].join(notes.isNotEmpty ? ' - ' : ''),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (response.success && response.data != null) {
      Navigator.pop(context, response.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Select Number of Guests',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    title: 'Apply Auto Gratuity',
                    value: _applyAutoGratuity,
                    onChanged: _toggleAuto,
                  ),
                  _buildSwitchRow(
                    title: 'Apply Auto Gratuity Manually',
                    value: _applyManualGratuity,
                    onChanged: _toggleManual,
                  ),
                  if (_applyManualGratuity) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gratuityType,
                            decoration: const InputDecoration(
                              labelText: 'Gratuity Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Percentage'),
                              ),
                              DropdownMenuItem(
                                value: 'fixed_money',
                                child: Text('Fixed Money'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _gratuityType = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _gratuityValueController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Value',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Order Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildGuestGrid(theme),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) {
            if (_isSubmitting) return;
            onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildGuestGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _guestOptions.length,
      itemBuilder: (context, index) {
        final value = _guestOptions[index];
        final isSelected = value == _selectedGuests;
        return GestureDetector(
          onTap: () {
            if (_isSubmitting) return;
            setState(() {
              _selectedGuests = value;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}
