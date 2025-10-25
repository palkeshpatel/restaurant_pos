import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../providers/settings_provider.dart';
import '../models/table_model.dart';
import '../models/menu_item.dart';
import 'kitchen_screen.dart';
import 'settings_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  MenuCategory _selectedCategory = MenuCategory.combos;
  String _searchQuery = '';
  
  // Responsive layout state
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _isMobile = false;
    _showLeftPanel = true;
    _showRightPanel = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkScreenSize();
  }

  void _checkScreenSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    if (_isMobile != isMobile) {
      setState(() {
        _isMobile = isMobile;
        if (_isMobile) {
          _showLeftPanel = false;
          _showRightPanel = false;
        } else {
          _showLeftPanel = true;
          _showRightPanel = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have the correct screen size detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScreenSize();
    });
    
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

              return _buildResponsiveLayout(posProvider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(POSProvider posProvider) {
    if (_isMobile) {
      return _buildMobileLayout(posProvider);
    } else {
      return _buildDesktopLayout(posProvider);
    }
  }

  Widget _buildMobileLayout(POSProvider posProvider) {
    return Column(
                children: [
        // Mobile Header with Navigation
        _buildMobileHeader(),
        
        // Main Content Area
                  Expanded(
          child: _showLeftPanel 
              ? _buildTablePanel(posProvider)
              : _showRightPanel 
                  ? _buildCategoryPanel(posProvider)
                  : _buildMenuPanel(posProvider),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(POSProvider posProvider) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final layout = settingsProvider.menuLayout;
        
        return Row(
          children: [
            // Left Panel - Table & Customers
            if (_showLeftPanel)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: _buildTablePanel(posProvider),
              ),
                  
            // Middle Panel - Menu Items
            Expanded(
              child: _buildMenuPanel(posProvider),
            ),
                  
            // Right Panel - Categories & Status
            if (_showRightPanel)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.15,
                child: _buildCategoryPanel(posProvider),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMobileHeader() {
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
          // Navigation Buttons
          Expanded(
            child: Row(
              children: [
                _buildMobileNavButton(
                  icon: Icons.description_outlined,
                  label: 'Orders',
                  isActive: _showLeftPanel,
                  onTap: () => _toggleLeftPanel(),
                ),
                _buildMobileNavButton(
                  icon: Icons.restaurant_menu,
                  label: 'Menu',
                  isActive: !_showLeftPanel && !_showRightPanel,
                  onTap: () => _showMenuPanel(),
                ),
                _buildMobileNavButton(
                  icon: Icons.grid_view,
                  label: 'Categories',
                  isActive: _showRightPanel,
                  onTap: () => _toggleRightPanel(),
                ),
                _buildMobileNavButton(
                  icon: Icons.room_service,
                  label: 'Kitchen',
                  isActive: false,
                  onTap: () => _navigateToKitchen(),
                ),
                _buildMobileNavButton(
                  icon: Icons.settings,
                  label: 'Setting',
                  isActive: false,
                  onTap: () => _showSettings(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
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
      ),
    );
  }

  Widget _buildStatusChip(String emoji, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLeftPanel() {
    setState(() {
      _showLeftPanel = !_showLeftPanel;
      if (_showLeftPanel) {
        _showRightPanel = false;
      }
    });
  }

  void _toggleRightPanel() {
    setState(() {
      _showRightPanel = !_showRightPanel;
      if (_showRightPanel) {
        _showLeftPanel = false;
      }
    });
  }

  void _showMenuPanel() {
    setState(() {
      _showLeftPanel = false;
      _showRightPanel = false;
    });
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
                        onPressed: () => _mergeTable(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4fc3f7),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_restaurant, size: 18),
                            SizedBox(width: 8),
                            Text('Merge Table'),
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
        border: _isMobile ? null : const Border(
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
                // Category Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MenuCategory>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2a3a4a),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: MenuCategory.values.map((category) {
                          return DropdownMenuItem<MenuCategory>(
                            value: category,
                            child: Row(
                              children: [
                                Text(category.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category.displayName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (MenuCategory? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                              _searchQuery = '';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    // Desktop Panel Toggle Buttons
                    if (!_isMobile) ...[
                      IconButton(
                        onPressed: () => setState(() => _showLeftPanel = !_showLeftPanel),
                        icon: Icon(
                          _showLeftPanel ? Icons.chevron_left : Icons.chevron_right,
                          color: Colors.white54,
                        ),
                        tooltip: _showLeftPanel ? 'Hide Orders Panel' : 'Show Orders Panel',
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showRightPanel = !_showRightPanel),
                        icon: Icon(
                          _showRightPanel ? Icons.chevron_right : Icons.chevron_left,
                          color: Colors.white54,
                        ),
                        tooltip: _showRightPanel ? 'Hide Categories Panel' : 'Show Categories Panel',
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Search Bar
                    Container(
                      width: _isMobile ? 150 : 200,
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
              ],
            ),
          ),
          
          // Menu Items List (Scrollable for mobile/tablet)
          Expanded(
            child: _isMobile 
                ? _buildMobileMenuGrid(posProvider)
                : ListView.builder(
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
        border: _isMobile ? null : const Border(
          left: BorderSide(color: Colors.white, width: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Categories Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4fc3f7),
              ),
                ),
                if (_isMobile)
                  IconButton(
                    onPressed: () => _showMenuPanel(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                    tooltip: 'Close Categories',
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: _isMobile 
                ? _buildMobileCategoryGrid()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: MenuCategory.values.length,
              itemBuilder: (context, index) {
                final category = MenuCategory.values[index];
                      return _buildCategoryItem(category);
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

  Widget _buildMobileMenuGrid(POSProvider posProvider) {
    final items = _getFilteredItems(posProvider);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMobileMenuItemCard(item, posProvider);
      },
    );
  }

  Widget _buildMobileMenuItemCard(MenuItem item, POSProvider posProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCustomerSelectionDialog(item, posProvider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Icon
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Item Name
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Item Description
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                
                // Price and Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF4caf50),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showCustomerSelectionDialog(item, posProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4fc3f7),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCategoryGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Dropdown for Mobile
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MenuCategory>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2a3a4a),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: MenuCategory.values.map((category) {
                        return DropdownMenuItem<MenuCategory>(
                          value: category,
                          child: Row(
                            children: [
                              Text(category.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.displayName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (MenuCategory? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                            _searchQuery = '';
                          });
                          // Switch to menu panel after selecting category
                          _showMenuPanel();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Category Grid (keep for visual reference)
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: MenuCategory.values.length,
              itemBuilder: (context, index) {
                final category = MenuCategory.values[index];
                return _buildCategoryItem(category, isMobile: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(MenuCategory category, {bool isMobile = false}) {
    final isSelected = category == _selectedCategory;
    
    return Container(
      key: ValueKey('category_${category.name}'),
      margin: isMobile ? null : const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          print('Category tapped: ${category.displayName}');
          try {
            setState(() {
              _selectedCategory = category;
              _searchQuery = '';
            });
            print('Category changed to: ${category.displayName}');
            
            // On mobile, switch to menu panel after selecting category
            if (_isMobile) {
              _showMenuPanel();
            }
          } catch (e, stackTrace) {
            print('Error changing category: $e');
            print('Stack trace: $stackTrace');
          }
        },
        child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 12),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Category Icon with better styling
                Container(
                  width: isMobile ? 50 : 40,
                  height: isMobile ? 50 : 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 25 : 20),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category.emoji,
                      style: TextStyle(fontSize: isMobile ? 24 : 18),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 5),
                Text(
                  category.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: isMobile ? 12 : 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
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

  void _mergeTable() {
    // Navigate back to floor layout to select another table
    Navigator.of(context).pop();
  }

  void _navigateToKitchen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const KitchenScreen(),
      ),
    );
  }

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
