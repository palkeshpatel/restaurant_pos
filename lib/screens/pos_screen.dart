import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/table_model.dart';
import '../models/menu_item.dart';
import 'bill_screen.dart';
import 'kitchen_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  MenuCategory _selectedCategory = MenuCategory.combos;
  String _searchQuery = '';

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
          child: Consumer<POSProvider>(
            builder: (context, posProvider, child) {
              print('POS Screen rebuilding with table: ${posProvider.selectedTable?.name}');
              print('Total bill items: ${posProvider.getBillItems().length}');
              if (posProvider.selectedTable == null) {
                return const Center(
                  child: Text(
                    'No table selected',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                );
              }

              return Row(
                children: [
                  // Left Panel - Table & Customers (35%)
                  Expanded(
                    flex: 35,
                    child: _buildTablePanel(posProvider),
                  ),
                  
                  // Middle Panel - Menu Items (50%)
                  Expanded(
                    flex: 50,
                    child: _buildMenuPanel(posProvider),
                  ),
                  
                  // Right Panel - Categories & Status (15%)
                  Expanded(
                    flex: 15,
                    child: _buildCategoryPanel(posProvider),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTablePanel(POSProvider posProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: const Border(
          right: BorderSide(color: Colors.white, width: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  posProvider.selectedTable!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4fc3f7),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Occupied',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Customers Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Show all customers
                  ...posProvider.selectedTable!.customers.map((customer) {
                    print('Customer ${customer.name} has ${customer.orders.length} orders in UI');
                    return _buildCustomerCard(customer, posProvider);
                  }).toList(),
                ],
              ),
            ),
          ),
          
          // Order Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: 0.1),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal:', posProvider.calculateSubtotal()),
                _buildSummaryRow('Tax (10%):', posProvider.calculateTax()),
                const Divider(color: Colors.white),
                _buildSummaryRow('Total:', posProvider.calculateTotal(), isTotal: true),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => posProvider.clearAllOrders(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _sendToKitchen(posProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 18),
                            SizedBox(width: 8),
                            Text('Send to Kitchen'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, POSProvider posProvider) {
    return Container(
      key: ValueKey('customer_${customer.id}'),
      margin: const EdgeInsets.only(bottom: 15),
      height: 120, // Fixed height for customer cards
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFbb86fc).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFbb86fc),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${customer.orders.length} items',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Drag Target Area
          Expanded(
            child: DragTarget<MenuItem>(
              key: ValueKey('drag_target_${customer.id}'),
              onWillAcceptWithDetails: (details) {
                print('Will accept item: ${details.data.name} on ${customer.name}');
                return true;
              },
              onAcceptWithDetails: (details) {
                print('Item dropped on ${customer.name}: ${details.data.name}');
                print('Customer ID: ${customer.id}');
                print('Table ID: ${posProvider.selectedTable?.id}');
                _addItemToCustomer(details.data, customer.id, posProvider);
              },
              onLeave: (data) {
                print('Item left ${customer.name}');
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                print('Building customer ${customer.name} with ${customer.orders.length} orders');
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isHovering 
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: isHovering 
                        ? Border.all(color: Colors.blue, width: 3)
                        : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: customer.orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isHovering ? Icons.download_done : Icons.add_circle_outline,
                                color: isHovering ? Colors.blue : Colors.white54,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isHovering ? 'Drop here!' : 'Drag items here',
                                style: TextStyle(
                                  color: isHovering ? Colors.blue : Colors.white54,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                  fontWeight: isHovering ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: customer.orders.length,
                          itemBuilder: (context, index) {
                            final order = customer.orders[index];
                            return _buildOrderItem(order, customer.id, posProvider);
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

  Widget _buildOrderItem(OrderItem order, int customerId, POSProvider posProvider) {
    return Container(
      key: ValueKey('order_item_${order.id}_${customerId}'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(order.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${order.status.emoji} ${order.status.displayName}',
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${order.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF4caf50),
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            key: ValueKey('remove_${order.id}_${customerId}'),
            onPressed: () => posProvider.removeOrderFromCustomer(customerId, order.id),
            icon: const Icon(Icons.close, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPanel(POSProvider posProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: const Border(
          right: BorderSide(color: Colors.white, width: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Menu Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4fc3f7),
                  ),
                ),
                Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search items...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white54),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items List (Scrollable for mobile/tablet)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _getFilteredItems(posProvider).length,
              itemBuilder: (context, index) {
                final item = _getFilteredItems(posProvider)[index];
                return _buildMenuItemCard(item, posProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item, POSProvider posProvider) {
    return Draggable<MenuItem>(
      key: ValueKey('draggable_item_${item.id}'),
      data: item,
      dragAnchorStrategy: (draggable, context, position) => Offset.zero,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        key: ValueKey('menu_item_${item.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    item.icon,
                    style: const TextStyle(fontSize: 32, color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white24,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: Colors.white12,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Dragging...',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      child: Container(
        key: ValueKey('menu_item_${item.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCustomerSelectionDialog(item, posProvider),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Item Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Price and Add Button
                  Column(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF4caf50),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        key: ValueKey('add_button_${item.id}'),
                        onPressed: () {
                          print('Add button pressed for item: ${item.name}');
                          try {
                            _showCustomerSelectionDialog(item, posProvider);
                          } catch (e, stackTrace) {
                            print('Error showing customer dialog: $e');
                            print('Stack trace: $stackTrace');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4fc3f7),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPanel(POSProvider posProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
      ),
      child: Column(
        children: [
          // Categories
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4fc3f7),
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: MenuCategory.values.length,
              itemBuilder: (context, index) {
                final category = MenuCategory.values[index];
                final isSelected = category == _selectedCategory;
                
                return Container(
                  key: ValueKey('category_${category.name}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        print('Category tapped: ${category.displayName}');
                        try {
                          setState(() {
                            _selectedCategory = category;
                            _searchQuery = '';
                          });
                          print('Category changed to: ${category.displayName}');
                        } catch (e, stackTrace) {
                          print('Error changing category: $e');
                          print('Stack trace: $stackTrace');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF2196f3).withOpacity(0.3)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2196f3) : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              category.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              category.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Status Counters
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Counters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4fc3f7),
                  ),
                ),
                const SizedBox(height: 10),
                ...ItemStatus.values.map((status) {
                  final count = posProvider.statusCounters[status] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(status.emoji),
                            const SizedBox(width: 8),
                            Text(
                              status.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          count.toString(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<MenuItem> _getFilteredItems(POSProvider posProvider) {
    var items = posProvider.menuItems
        .where((item) => item.category == _selectedCategory)
        .toList();
    
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    return items;
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

  void _showCustomerSelectionDialog(MenuItem item, POSProvider posProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${item.name} to Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: posProvider.selectedTable!.customers.map((customer) {
            return ListTile(
              title: Text(customer.name),
              onTap: () {
                _addItemToCustomer(item, customer.id, posProvider);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _addItemToCustomer(MenuItem item, int customerId, POSProvider posProvider) {
    try {
      print('Adding item: ${item.name} to customer: $customerId');
      print('Selected table: ${posProvider.selectedTable?.name}');
      print('Selected table ID: ${posProvider.selectedTable?.id}');
      
      if (posProvider.selectedTable == null) {
        print('ERROR: No table selected!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ERROR: No table selected! Please select a table first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      posProvider.addOrderToCustomer(customerId, item);
      print('Item added successfully');
      
      final customerName = posProvider.selectedTable!.customers.firstWhere((c) => c.id == customerId).name;
      final totalItems = posProvider.getBillItems().length;
      final totalAmount = posProvider.calculateTotal();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ ${item.name} added to $customerName'),
              const SizedBox(height: 4),
              Text('Total Items: $totalItems | Total: ₹${totalAmount.toStringAsFixed(0)}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      print('Error adding item: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding item: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _sendToKitchen(POSProvider posProvider) {
    final totalItems = posProvider.getBillItems().length;
    
    if (totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items to send to kitchen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Directly navigate to kitchen management without confirmation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const KitchenScreen(),
      ),
    );
  }
}
