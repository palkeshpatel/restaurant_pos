import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';
import 'pos_screen.dart';
import 'settings_screen.dart';

class KitchenStatusScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const KitchenStatusScreen({super.key, required this.onThemeChange});

  @override
  State<KitchenStatusScreen> createState() => _KitchenStatusScreenState();
}

class _KitchenStatusScreenState extends State<KitchenStatusScreen> {
  late List<OrderStatus> statuses;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initStatuses();
    _startTimer();
  }

  void _initStatuses() {
    statuses = [
      OrderStatus(
        name: 'Hold',
        icon: Icons.pause,
        color: Colors.orange,
        items: [
          OrderItem(name: 'Burger', price: 12.99, icon: Icons.lunch_dining, addedTime: DateTime.now().subtract(const Duration(minutes: 10))),
          OrderItem(name: 'Pizza', price: 14.99, icon: Icons.local_pizza, addedTime: DateTime.now().subtract(const Duration(minutes: 5))),
        ],
      ),
      OrderStatus(
        name: 'Fire',
        icon: Icons.local_fire_department,
        color: Colors.red,
        items: [
          OrderItem(name: 'Margherita Pizza', price: 12.99, icon: Icons.local_pizza, addedTime: DateTime.now().subtract(const Duration(minutes: 15))),
        ],
      ),
    ];
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _moveItem(OrderItem item, String fromStatus, String toStatus) {
    setState(() {
      // Remove from current status
      for (var status in statuses) {
        if (status.name == fromStatus) {
          status.items.remove(item);
        }
      }
      // Add to new status
      for (var status in statuses) {
        if (status.name == toStatus) {
          status.items.add(item);
          break;
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} moved to $toStatus'),
        duration: const Duration(seconds: 1),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _printBill() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Bill'),
        content: const Text('Bill printed successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment'),
        content: const Text('Payment processed successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => POSScreen(onThemeChange: widget.onThemeChange),
                      ),
                    ),
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                    iconSize: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 8 : 20),
                  Expanded(
                    child: Text(
                      'Kitchen Order Status',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (!isMobile) ...[
                  ElevatedButton.icon(
                    onPressed: _printBill,
                    icon: const Icon(Icons.print),
                    label: const Text('Print Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _processPayment,
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                IconButton(
                  onPressed: _showSettings,
                  icon: const Icon(Icons.settings),
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: isMobile ? 20 : 24,
                ),
              ],
            ),
          ),
          // Action buttons for mobile
          if (isMobile)
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _printBill,
                      icon: Icon(Icons.print, size: isMobile ? 18 : 24),
                      label: Text(
                        'Print Bill',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _processPayment,
                      icon: Icon(Icons.credit_card, size: isMobile ? 18 : 24),
                      label: Text(
                        'Payment',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Status columns
          Expanded(
            child: isMobile 
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  children: statuses.map((status) {
                    return SizedBox(
                      width: screenWidth * 0.85,
                      child: _buildStatusColumn(status, isMobile: isMobile),
                    );
                  }).toList(),
                )
              : Row(
                  children: statuses.map((status) {
                    return Expanded(
                      child: _buildStatusColumn(status, isMobile: false),
                    );
                  }).toList(),
                ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatusColumn(OrderStatus status, {required bool isMobile}) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(status.icon, color: status.color, size: isMobile ? 20 : 24),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status.name,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: status.color,
                        ),
                      ),
                      Text(
                        '${status.items.length} Products',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 15),
              child: status.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            status.icon,
                            size: isMobile ? 36 : 48,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Text(
                            'No items',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: status.items.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        setState(() {
                          final item = status.items.removeAt(oldIndex);
                          status.items.insert(newIndex, item);
                        });
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 8,
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final item = status.items[index];
                        return _buildDraggableOrderItem(item, status, isMobile: isMobile);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableOrderItem(OrderItem item, OrderStatus currentStatus, {required bool isMobile}) {
    final duration = DateTime.now().difference(item.addedTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return Card(
      key: ValueKey('${item.name}_${item.addedTime}'),
      elevation: 3,
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: currentStatus.color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Drag handle
            Container(
              width: isMobile ? 30 : 40,
              decoration: BoxDecoration(
                color: currentStatus.color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.drag_handle,
                  color: currentStatus.color,
                  size: isMobile ? 18 : 24,
                ),
              ),
            ),
            // Item content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 10 : 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: isMobile ? 18 : 24,
                                ),
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: isMobile ? 13 : 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.table_restaurant, size: isMobile ? 12 : 16, color: Colors.grey),
                              SizedBox(width: isMobile ? 2 : 4),
                              Text(
                                'Table 1',
                                style: TextStyle(color: Colors.grey, fontSize: isMobile ? 11 : 14),
                              ),
                              SizedBox(width: isMobile ? 8 : 16),
                              Icon(Icons.timer, size: isMobile ? 12 : 16, color: currentStatus.color),
                              SizedBox(width: isMobile ? 2 : 4),
                              Text(
                                '${minutes}m ${seconds}s',
                                style: TextStyle(
                                  color: currentStatus.color,
                                  fontSize: isMobile ? 11 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Status change buttons
            Container(
              width: isMobile ? 40 : 50,
              decoration: BoxDecoration(
                color: currentStatus.color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  if (statuses.indexOf(currentStatus) > 0)
                    Expanded(
                      child: IconButton(
                        onPressed: () => _moveItem(
                          item,
                          currentStatus.name,
                          statuses[statuses.indexOf(currentStatus) - 1].name,
                        ),
                        icon: Icon(Icons.arrow_upward, color: statuses[statuses.indexOf(currentStatus) - 1].color, size: isMobile ? 18 : 24),
                        padding: EdgeInsets.all(isMobile ? 4 : 8),
                      ),
                    ),
                  if (statuses.indexOf(currentStatus) < statuses.length - 1)
                    Expanded(
                      child: IconButton(
                        onPressed: () => _moveItem(
                          item,
                          currentStatus.name,
                          statuses[statuses.indexOf(currentStatus) + 1].name,
                        ),
                        icon: Icon(Icons.arrow_downward, color: statuses[statuses.indexOf(currentStatus) + 1].color, size: isMobile ? 18 : 24),
                        padding: EdgeInsets.all(isMobile ? 4 : 8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}