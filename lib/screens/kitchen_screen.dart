import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/table_model.dart';
import 'bill_screen.dart';
import 'dart:async';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a2a3a),
              Color(0xFF0d1b2a),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kitchen Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Live Orders',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Consumer<POSProvider>(
                          builder: (context, posProvider, child) {
                            return ElevatedButton.icon(
                              onPressed: () => _printServedOrders(posProvider),
                              icon: const Icon(Icons.print, color: Colors.white),
                              label: const Text('Print Order', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status Columns
              Expanded(
                child: Consumer<POSProvider>(
                  builder: (context, posProvider, child) {
                    return Row(
                      children: [
                        // Fire Orders (Drinks/Quick Items)
                        Expanded(
                          child: _buildStatusColumn(
                            'Fire',
                            ItemStatus.fire,
                            Colors.red,
                            posProvider,
                          ),
                        ),
                        
                        // Hold Orders (Main Course) - using hourglass icon
                        Expanded(
                          child: _buildStatusColumn(
                            'Hold',
                            ItemStatus.hold,
                            Colors.orange,
                            posProvider,
                          ),
                        ),
                        
                        // Served Orders
                        Expanded(
                          child: _buildStatusColumn(
                            'Served',
                            ItemStatus.served,
                            Colors.green,
                            posProvider,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusColumn(String title, ItemStatus status, Color color, POSProvider posProvider) {
    final items = _getItemsByStatus(status, posProvider);
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Column Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  status.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} items',
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Items List with Drag Target
          Expanded(
            child: DragTarget<OrderItem>(
              onWillAcceptWithDetails: (details) {
                // Allow dropping items from other statuses
                return details.data.status != status;
              },
              onAcceptWithDetails: (details) {
                // Move item to this status
                _moveItemToStatus(details.data, status, posProvider);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isHovering 
                        ? color.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isHovering 
                        ? Border.all(color: color, width: 2)
                        : null,
                  ),
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isHovering ? Icons.download_done : Icons.inbox_outlined,
                                color: isHovering ? color : Colors.white.withOpacity(0.3),
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isHovering ? 'Drop here!' : 'No items',
                                style: TextStyle(
                                  color: isHovering ? color : Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: items.length,
                          onReorder: (oldIndex, newIndex) {
                            _reorderItems(items, oldIndex, newIndex, posProvider);
                          },
                          itemBuilder: (context, index) {
                            final orderItem = items[index];
                            return _buildKitchenOrderCard(orderItem, posProvider, index);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenOrderCard(OrderItem orderItem, POSProvider posProvider, int index) {
    final timeElapsed = _getTimeElapsed(orderItem);
    
    return Draggable<OrderItem>(
      key: ValueKey('kitchen_order_${orderItem.id}'),
      data: orderItem,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                orderItem.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                orderItem.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Header
                Row(
                  children: [
                    Text(
                      orderItem.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        orderItem.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(orderItem.status).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        orderItem.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(orderItem.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Timer and Details
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeElapsed,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${orderItem.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF4caf50),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                // Progress Bar
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _getProgressValue(orderItem.status, timeElapsed),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(orderItem.status),
                  ),
                ),
                
                // Priority Indicator
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.priority_high,
                      color: Colors.white.withOpacity(0.6),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Priority: ${index + 1}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }

  List<OrderItem> _getItemsByStatus(ItemStatus status, POSProvider posProvider) {
    final allItems = <OrderItem>[];
    
    for (final table in posProvider.tables) {
      for (final customer in table.customers) {
        allItems.addAll(
          customer.orders.where((order) => order.status == status),
        );
      }
    }
    
    return allItems;
  }

  String _getTimeElapsed(OrderItem orderItem) {
    // Use real timestamp from the order item
    final now = DateTime.now();
    final elapsed = now.difference(orderItem.createdAt);
    
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    return '${minutes}m ${seconds}s';
  }

  double _getProgressValue(ItemStatus status, String timeElapsed) {
    // Calculate progress based on status and time
    switch (status) {
      case ItemStatus.fire:
        return 0.5;
      case ItemStatus.hold:
        return 0.7;
      case ItemStatus.served:
        return 1.0;
    }
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.fire:
        return Colors.red;
      case ItemStatus.hold:
        return Colors.orange;
      case ItemStatus.served:
        return Colors.green;
    }
  }

  void _moveItemToStatus(OrderItem item, ItemStatus newStatus, POSProvider posProvider) {
    // Find the item in the provider and update its status
    for (final table in posProvider.tables) {
      for (final customer in table.customers) {
        final itemIndex = customer.orders.indexWhere((order) => order.id == item.id);
        if (itemIndex != -1) {
          posProvider.updateOrderStatus(customer.id, item.id, newStatus);
          break;
        }
      }
    }
  }

  void _reorderItems(List<OrderItem> items, int oldIndex, int newIndex, POSProvider posProvider) {
    // Handle reordering logic
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    
    // Update the provider with new order
    posProvider.reorderItems(items);
  }

  void _printServedOrders(POSProvider posProvider) {
    // Get all served items
    final servedItems = <OrderItem>[];
    for (final table in posProvider.tables) {
      for (final customer in table.customers) {
        for (final order in customer.orders) {
          if (order.status == ItemStatus.served) {
            servedItems.add(order);
          }
        }
      }
    }

    if (servedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No served items to print'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to bill screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BillScreen(items: servedItems),
      ),
    );
  }
}
