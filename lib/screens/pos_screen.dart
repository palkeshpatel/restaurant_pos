import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import '../models/order_item.dart';
import '../models/customer.dart';
import '../models/floor.dart';
import '../models/table.dart' as table_model;
import '../services/api_service.dart';
import 'kitchen_status_screen.dart';
import 'settings_screen.dart';
import '../widgets/status_count_widget.dart';

class POSScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;
  final Floor? floor;
  final table_model.TableModel? table;
  final int? orderId; // Order ID from reserve_table response
  final String? orderTicketId; // Order Ticket ID from reserve_table response

  const POSScreen({
    super.key,
    required this.onThemeChange,
    this.floor,
    this.table,
    this.orderId,
    this.orderTicketId,
  });

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  Timer? _timer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final DateTime _orderStartTime;
  bool _isMenuLoading = true;
  String? _menuError;
  List<MenuCategory> _allCategories = [];
  MenuCategory? _selectedCategory;
  int? _orderId; // Store order_id from reserve_table response
  String? _orderTicketId; // Store order_ticket_id from reserve_table response
  bool _isSendingToKitchen = false;

  @override
  void initState() {
    super.initState();
    _orderStartTime = DateTime.now();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _startTimer();
    _loadMenu();
    _loadOrderId();
  }

  void _loadOrderId() {
    // Get order_id and order_ticket_id from widget if passed
    // IMPORTANT: Always prefer widget.orderTicketId (from reserve_table API response)
    // This ensures we use order_ticket_id (ORD-20251121-XJROYU), NOT order_ticket_title (20251121-01T1)
    setState(() {
      // Get orderId from widget parameter or from table model (from get-tables API)
      _orderId = widget.orderId ?? widget.table?.orderId;
      // Use widget.orderTicketId first (directly from API response), 
      // only fallback to table.orderTicketId if not provided
      _orderTicketId = widget.orderTicketId ?? widget.table?.orderTicketId;
      
      // Debug log
      print('_loadOrderId: widget.orderId = ${widget.orderId}');
      print('_loadOrderId: widget.table?.orderId = ${widget.table?.orderId}');
      print('_loadOrderId: widget.orderTicketId = ${widget.orderTicketId}');
      print('_loadOrderId: widget.table?.orderTicketId = ${widget.table?.orderTicketId}');
      print('_loadOrderId: widget.table?.orderTicketTitle = ${widget.table?.orderTicketTitle}');
      print('_loadOrderId: Final _orderId = $_orderId');
      print('_loadOrderId: Final _orderTicketId = $_orderTicketId');
    });
  }

  String _formatOrderStart(DateTime dateTime) {
    String two(int n) => n.toString().padLeft(2, '0');
    final date =
        '${two(dateTime.day)}-${two(dateTime.month)}-${dateTime.year} ${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
    return date;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.blueGrey;
      case 'occupied':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isMenuLoading = true;
      _menuError = null;
    });

    final response = await ApiService.getMenu();

    if (!mounted) return;

    if (response.success && response.data != null && response.data!.menus.isNotEmpty) {
      final flattenedCategories = _flattenCategories(
        response.data!.menus.expand((menu) => menu.categories).toList(),
      );

      setState(() {
        _allCategories = flattenedCategories;
        _selectedCategory = flattenedCategories.isNotEmpty ? flattenedCategories.first : null;
        _isMenuLoading = false;
      });
    } else {
      setState(() {
        _menuError = response.message;
        _isMenuLoading = false;
      });
    }
  }

  List<MenuCategory> _flattenCategories(List<MenuCategory> categories) {
    final List<MenuCategory> result = [];
    for (final category in categories) {
      if (category.menuItems.isNotEmpty) {
        result.add(category);
      }
      result.addAll(_flattenCategories(category.children));
    }
    return result;
  }


  // Multiple customers
  List<Customer> customers = [
    Customer(id: '1', name: 'Cust 1'),
    Customer(id: '2', name: 'Cust 2'),
    Customer(id: '3', name: 'Cust 3'),
  ];
  
  int selectedCustomerIndex = 0;
  
  Customer get selectedCustomer => customers[selectedCustomerIndex];
  
  // Legacy single order items (for backward compatibility)
  List<OrderItem> get orderItems => selectedCustomer.items;
  
  int holdCount = 2;
  int fireCount = 1;

  double get subtotal => selectedCustomer.subtotal;
  double get tax => selectedCustomer.tax;
  double get total => selectedCustomer.total;
  
  // Get total for all customers combined
  double get allCustomersTotal => customers.fold(0.0, (sum, cust) => sum + cust.total);

  void _selectCategory(MenuCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _addToOrder(MenuItem item, {int customerIndex = -1}) {
    final targetIndex = customerIndex == -1 ? selectedCustomerIndex : customerIndex;
    
    setState(() {
      // Check if item already exists in customer's order (with same menu_item_id)
      final existingItemIndex = customers[targetIndex].items.indexWhere(
        (orderItem) => orderItem.menuItemId == item.id,
      );
      
      if (existingItemIndex >= 0) {
        // Increase quantity if item exists
        customers[targetIndex].items[existingItemIndex].quantity++;
      } else {
        // Add new item with menu_item_id
        customers[targetIndex].items.add(OrderItem(
          name: item.name,
          price: item.price,
          icon: Icons.restaurant_menu,
          addedTime: DateTime.now(),
          menuItemId: item.id,
          quantity: 1,
        ));
      }
    });
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to ${customers[targetIndex].name}'),
        duration: const Duration(seconds: 1),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  void _removeItem(int customerIndex, int itemIndex) {
    setState(() {
      customers[customerIndex].items.removeAt(itemIndex);
    });
  }
  
  void _updateQuantity(int customerIndex, int itemIndex, int delta) {
    setState(() {
      final item = customers[customerIndex].items[itemIndex];
      item.quantity = (item.quantity + delta).clamp(1, 999);
    });
  }

  Future<void> _sendToKitchen() async {
    // Check if we have order_id and order_ticket_id
    // IMPORTANT: Use order_ticket_id (ORD-20251121-XJROYU), NOT order_ticket_title (20251121-01T1)
    // _orderTicketId should contain the actual ID from reserve_table response
    // widget.table?.orderTicketId should also contain the ID (not title)
    
    // CRITICAL: Use _orderTicketId which comes from reserve_table API response
    // This should be "ORD-20251121-XJROYU" (the ID), NOT "20251121-01T1" (the title)
    final orderTicketId = _orderTicketId ?? widget.table?.orderTicketId;
    final orderTicketTitle = widget.table?.orderTicketTitle;
    
    // Debug: Log what we have
    print('========================================');
    print('DEBUG: Order Ticket Values:');
    print('_orderTicketId (from widget param - SHOULD BE ID like ORD-20251121-XJROYU): $_orderTicketId');
    print('widget.table?.orderTicketId (from table - SHOULD BE ID): ${widget.table?.orderTicketId}');
    print('widget.table?.orderTicketTitle (TITLE - DO NOT USE IN API - for display only): $orderTicketTitle');
    print('Final orderTicketId being used for API: $orderTicketId');
    
    // CRITICAL CHECK: Verify we're using ID format (starts with "ORD-"), not title format
    if (orderTicketId != null && !orderTicketId.startsWith('ORD-')) {
      print('❌ ERROR: orderTicketId does not start with "ORD-" - this looks like a TITLE!');
      print('Expected format: ORD-20251121-XJROYU (the ID)');
      print('Got: $orderTicketId (this looks like the title: $orderTicketTitle)');
      print('You MUST use order_ticket_id (ORD-20251121-XJROYU), NOT order_ticket_title (20251121-01T1)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ERROR: Invalid order ticket ID format. Expected format: ORD-20251121-XXXXX\nGot: $orderTicketId'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // Verify we're not accidentally using the title
    if (orderTicketId == orderTicketTitle) {
      print('❌ WARNING: orderTicketId matches orderTicketTitle - this is WRONG!');
      print('You are using the TITLE instead of the ID!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ERROR: Using order ticket title instead of ID. The ID should start with "ORD-".'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    print('========================================');
    
    if (orderTicketId == null || orderTicketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order Ticket ID not found. Please ensure the table is reserved.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID not found. Please ensure the table is reserved.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Collect all items from all customers
    final List<Map<String, dynamic>> itemsToSend = [];
    
    for (final customer in customers) {
      for (final orderItem in customer.items) {
        // Convert each order item to API format
        final itemData = {
          'menu_item_id': orderItem.menuItemId,
          'qty': orderItem.quantity,
          'unit_price': orderItem.price,
          if (orderItem.instructions != null && orderItem.instructions!.isNotEmpty)
            'instructions': orderItem.instructions,
          if (orderItem.decisionIds != null && orderItem.decisionIds!.isNotEmpty)
            'decisions': orderItem.decisionIds!.map((id) => {'decision_id': id}).toList(),
          if (orderItem.modifiers != null && orderItem.modifiers!.isNotEmpty)
            'modifiers': orderItem.modifiers,
        };
        itemsToSend.add(itemData);
      }
    }

    if (itemsToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items to send to kitchen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSendingToKitchen = true;
    });

    // Debug: Print items being sent
    print('========================================');
    print('Sending to Kitchen - Items Summary:');
    print('✅ Order Ticket ID (should be like ORD-20251121-XJROYU): $orderTicketId');
    print('❌ Order Ticket TITLE (NOT USED - just for display): ${widget.table?.orderTicketTitle}');
    print('Order ID: $_orderId');
    print('Total Items: ${itemsToSend.length}');
    for (var i = 0; i < itemsToSend.length; i++) {
      print('Item ${i + 1}: ${itemsToSend[i]}');
    }
    print('========================================');

    // Verify we're using ID, not title
    if (orderTicketId == widget.table?.orderTicketTitle) {
      print('⚠️ ERROR: Using TITLE instead of ID! This is WRONG!');
      print('You must use order_ticket_id (ORD-20251121-XJROYU), not order_ticket_title (20251121-01T1)');
    }

    try {
      // Create formatted request body for debugging
      final requestBody = {
        'order_ticket_id': orderTicketId, // MUST be ORD-20251121-XJROYU, NOT 20251121-01T1
        'order_id': _orderId,
        'items': itemsToSend,
      };
      
      // Print formatted JSON for debugging
      final formattedJson = const JsonEncoder.withIndent('  ').convert(requestBody);
      final rawJson = jsonEncode(requestBody);
      
      print('========================================');
      print('📤 PREPARING REQUEST TO: /api/pos/order/send');
      print('========================================');
      print('📋 REQUEST DETAILS:');
      print('   order_ticket_id: $orderTicketId');
      print('   order_id: $_orderId');
      print('   items count: ${itemsToSend.length}');
      print('');
      print('📦 FULL REQUEST BODY (Formatted):');
      print(formattedJson);
      print('');
      print('📦 FULL REQUEST BODY (Raw JSON - for copy/paste to Postman):');
      print(rawJson);
      print('');
      print('⚠️ VERIFY: order_ticket_id should be like "ORD-20251121-XJROYU"');
      print('⚠️ VERIFY: order_ticket_id should NOT be like "20251121-01T1" (that is the title!)');
      print('========================================');
      print('');

      final response = await ApiService.sendOrder(
        orderTicketId: orderTicketId,
        orderId: _orderId!,
        items: itemsToSend,
      );

      if (!mounted) return;
      
      // Log response
      print('========================================');
      print('RESPONSE STATUS: ${response.success ? "SUCCESS" : "FAILED"}');
      print('RESPONSE MESSAGE: ${response.message}');
      if (response.data != null) {
        print('RESPONSE DATA: ${const JsonEncoder.withIndent('  ').convert(response.data)}');
      }
      print('========================================');

      if (response.success) {
        final data = response.data;
        final newItemsCount = data?['new_items_count'] ?? 0;
        
        if (newItemsCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All items already sent to kitchen'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully sent ${newItemsCount} item(s) to kitchen'),
              backgroundColor: Colors.green,
            ),
          );

          // Optionally navigate to kitchen status screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KitchenStatusScreen(onThemeChange: widget.onThemeChange),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending order: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingToKitchen = false;
        });
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
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final tokenLabel = widget.table?.orderTicketTitle ?? widget.table?.orderTicketId;
    
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
                        '${widget.table?.name ?? 'Table'}: ${widget.table?.orderTicketTitle ?? 'New Order'}',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Order start on ${_formatOrderStart(_orderStartTime)}${tokenLabel != null ? '  #Order/Token: $tokenLabel' : ''}',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showSettings,
                  icon: const Icon(Icons.settings),
                  color: Colors.grey.shade700,
                  iconSize: isMobile ? 20 : 24,
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: isMobile 
              ? _buildMobileLayout()
              : Row(
                  children: [
                    // Order Section (300px or 25%)
                    SizedBox(
                      width: isTablet ? 300 : screenWidth * 0.25,
                      child: _buildOrderSection(),
                    ),
                    // Menu Section (remaining space)
                    Expanded(
                      child: Column(
                        children: [
                          // Category Title
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _selectedCategory?.name ?? 'Menu',
                                  style: TextStyle(
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search Bar
                          Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search items...',
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildMenuSection(),
                          ),
                        ],
                      ),
                    ),
                    // Category Section (200px or 20%)
                    SizedBox(
                      width: isTablet ? 200 : screenWidth * 0.2,
                      child: _buildCategorySection(),
                    ),
                  ],
                ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Menu'),
                Tab(text: 'Order'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Menu Tab
                Column(
                  children: [
                    // Category filter bar for mobile
                    Container(
                      height: 60,
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _isMenuLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _allCategories.length,
                              itemBuilder: (context, index) {
                                final category = _allCategories[index];
                                final isActive = _selectedCategory?.id == category.id;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: FilterChip(
                                    selected: isActive,
                                    label: Text(category.name),
                                    avatar: Icon(
                                      Icons.restaurant_menu,
                                      size: 18,
                                      color: isActive
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                    selectedColor: Theme.of(context).colorScheme.primary,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _selectCategory(category);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    Expanded(
                      child: _buildMenuSection(),
                    ),
                  ],
                ),
                // Order Tab
                _buildOrderSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    final tokenLabel = widget.table?.orderTicketTitle ?? widget.table?.orderTicketId;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(5, 0),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header with Status Badge
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.table?.name ?? 'Table',
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.table?.status ?? 'new'),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (widget.table?.status ?? 'new').toUpperCase(),
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (tokenLabel != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            tokenLabel,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 6),
                      Text(
                        'Order start on ${_formatOrderStart(_orderStartTime)}',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Customer Sections with Orders
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 10 : 15),
              child: Column(
                children: customers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final customer = entry.value;
                  final customerTotal = customer.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
                  
                  return DragTarget<MenuItem>(
                    onAccept: (menuItem) {
                      setState(() {
                        selectedCustomerIndex = index;
                      });
                      _addToOrder(menuItem, customerIndex: index);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: candidateData.isNotEmpty ? Colors.green.shade50 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer Header
                            Container(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: Colors.purple.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    customer.name,
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  if (customer.items.isNotEmpty) ...[
                                    Spacer(),
                                    Text(
                                      '\$${customerTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Customer Items
                            customer.items.isEmpty
                                ? Container(
                                    padding: EdgeInsets.all(isMobile ? 20 : 30),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Drag items here',
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          color: Colors.grey.shade500,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: customer.items.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = customer.items[itemIndex];
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 12 : 16,
                                            vertical: isMobile ? 8 : 10,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: TextStyle(
                                                        fontSize: isMobile ? 14 : 16,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    if (item.quantity > 1)
                                                      Text(
                                                        'Qty: ${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontSize: isMobile ? 11 : 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              // Quantity Controls
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.remove_circle_outline, size: isMobile ? 18 : 20),
                                                    color: Colors.grey.shade600,
                                                    padding: EdgeInsets.all(4),
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _updateQuantity(index, itemIndex, -1),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                                    child: Text(
                                                      '${item.quantity}x',
                                                      style: TextStyle(
                                                        fontSize: isMobile ? 13 : 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.add_circle_outline, size: isMobile ? 18 : 20),
                                                    color: Theme.of(context).colorScheme.primary,
                                                    padding: EdgeInsets.all(4),
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _updateQuantity(index, itemIndex, 1),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: isMobile ? 14 : 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              IconButton(
                                                icon: Icon(Icons.close, size: isMobile ? 18 : 20),
                                                color: Colors.red.shade400,
                                                padding: EdgeInsets.all(isMobile ? 4 : 6),
                                                constraints: BoxConstraints(),
                                                onPressed: () => _removeItem(index, itemIndex),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          // Order Summary
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTotalRow('Subtotal:', allCustomersTotal, isMobile: isMobile),
                _buildTotalRow('Tax (10%):', allCustomersTotal * 0.1, isMobile: isMobile),
                SizedBox(height: 8),
                _buildTotalRow('Total:', allCustomersTotal * 1.1, isTotal: true, isMobile: isMobile),
                SizedBox(height: isMobile ? 12 : 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: allCustomersTotal == 0 ? null : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Clear All Orders?'),
                              content: Text('Are you sure you want to clear all customer orders?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      for (var customer in customers) {
                                        customer.items.clear();
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text('Clear All'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Clear All',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (allCustomersTotal == 0 || _isSendingToKitchen) ? null : _sendToKitchen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: _isSendingToKitchen
                            ? SizedBox(
                                height: isMobile ? 18 : 20,
                                width: isMobile ? 18 : 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Send Kitchen',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
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

  Widget _buildMenuSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (_isMenuLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_menuError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _menuError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMenu,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_selectedCategory == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No menu categories available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    var filteredItems = List<MenuItem>.from(_selectedCategory!.menuItems);

    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) => item.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 2;
    } else if (isTablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Container(
      color: const Color(0xFFFFF3E0),
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: filteredItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items in ${_selectedCategory!.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isMobile ? 12 : 20,
                mainAxisSpacing: isMobile ? 12 : 20,
                childAspectRatio: isMobile ? 0.75 : 0.85,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Draggable<MenuItem>(
                  data: item,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 120,
                      height: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItemVisual(item, 50, context),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.grey.shade200,
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 6 : 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: isMobile ? 28 : 36,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            Flexible(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: isMobile ? 4 : 8),
                            Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _addToOrder(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 6 : 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: isMobile ? 28 : 36,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              Flexible(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: isMobile ? 4 : 8),
                              Text(
                                '₹${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(-5, 0),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          // Categories Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Categories List
          Expanded(
            child: _isMenuLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : ListView.builder(
                    itemCount: _allCategories.length,
                    itemBuilder: (context, index) {
                      final category = _allCategories[index];
                      final isActive = _selectedCategory?.id == category.id;
                      return InkWell(
                        onTap: () => _selectCategory(category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isActive ? Theme.of(context).colorScheme.primary : null,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                color: isActive ? Colors.white : Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                    color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Status Counts
          StatusCountWidget(
            holdCount: holdCount,
            fireCount: fireCount,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemVisual(MenuItem item, double size, BuildContext context) {
    if (item.image != null && item.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.image!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.restaurant_menu,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Icon(
      Icons.restaurant_menu,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 6 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? (isMobile ? 16 : 18) : (isMobile ? 12 : 14),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? (isMobile ? 22 : 26) : (isMobile ? 14 : 16),
              fontWeight: FontWeight.w700,
              color: isTotal ? Theme.of(context).colorScheme.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}