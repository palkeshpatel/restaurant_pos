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
import 'payment_screen.dart';
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
  bool _isOrderPaid = false; // Track if order is paid

  @override
  void initState() {
    super.initState();
    // Initialize with default 1 customer, will be updated when order is loaded
    _initializeCustomers(1);
    _orderStartTime = DateTime.now();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _startTimer();
    _loadOrderId();
    // Load menu first, then load existing order items
    _loadMenu().then((_) {
      // Wait a bit for menu to fully load, then load order items
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadExistingOrderItems();
      });
    });
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

  Future<void> _loadExistingOrderItems() async {
    // Only load if we have an order_ticket_id (resuming existing order)
    final orderTicketId = _orderTicketId ?? widget.table?.orderTicketId;
    
    if (orderTicketId == null || orderTicketId.isEmpty) {
      print('_loadExistingOrderItems: No order_ticket_id, skipping load');
      return;
    }

    // Verify we're using ID format (starts with "ORD-"), not title format
    if (!orderTicketId.startsWith('ORD-')) {
      print('_loadExistingOrderItems: orderTicketId does not start with "ORD-", skipping');
      return;
    }

    print('========================================');
    print('_loadExistingOrderItems: Loading order items');
    print('order_ticket_id: $orderTicketId');
    print('========================================');

    try {
      final response = await ApiService.resumeOrder(orderTicketId: orderTicketId);

      if (!mounted) return;

      print('_loadExistingOrderItems: API Response - success: ${response.success}');
      print('_loadExistingOrderItems: API Response - message: ${response.message}');
      print('_loadExistingOrderItems: response.data is null: ${response.data == null}');
      
      if (response.data != null) {
        print('_loadExistingOrderItems: response.data keys: ${response.data!.toJson().keys}');
        print('_loadExistingOrderItems: Full response.data: ${response.data!.toJson()}');
      }

      if (response.success && response.data != null) {
        final orderData = response.data!.order;
        
        // Also try getting order directly from response.data if it's nested differently
        if (orderData == null && response.data!.toJson().containsKey('order')) {
          final rawData = response.data!.toJson();
          print('_loadExistingOrderItems: Trying to get order from raw data');
          // The order might be in the response.data map directly
        }
        
        print('_loadExistingOrderItems: orderData is null: ${orderData == null}');
        if (orderData != null) {
          // Get customer count from order data and initialize customers dynamically
          final customerCount = orderData['customer'] as int? ?? 1;
          print('_loadExistingOrderItems: Customer count from order: $customerCount');
          if (mounted) {
            setState(() {
              _initializeCustomers(customerCount);
            });
          }
          
          print('_loadExistingOrderItems: orderData keys: ${orderData.keys}');
          print('_loadExistingOrderItems: orderData has checks: ${orderData.containsKey('checks')}');
          
          // Extract order items from checks array
          List<dynamic> allOrderItems = [];
          
          if (orderData['checks'] != null) {
            final checks = orderData['checks'] as List<dynamic>? ?? [];
            print('_loadExistingOrderItems: Found ${checks.length} checks');
            
            for (var check in checks) {
              if (check is! Map) continue;
              
              print('_loadExistingOrderItems: Check keys: ${check.keys}');
              // The API returns 'order_items' in snake_case
              final orderItems = check['order_items'];
              
              if (orderItems != null && orderItems is List) {
                print('_loadExistingOrderItems: Found ${orderItems.length} items in check');
                allOrderItems.addAll(orderItems);
              } else {
                print('_loadExistingOrderItems: No order_items found in check or not a list');
              }
            }
          } else {
            print('_loadExistingOrderItems: No checks found in order data');
          }
          
          print('_loadExistingOrderItems: Total items found: ${allOrderItems.length}');
          
          // Always clear existing items, even if no items found
          if (mounted) {
            setState(() {
              for (var customer in customers) {
                customer.items.clear();
              }
            });
          }
          
          if (allOrderItems.isNotEmpty) {

            // Load menu to get item names and prices
            final menuResponse = await ApiService.getMenu();
            Map<int, MenuItem> menuItemsMap = {};
            
            if (menuResponse.success && menuResponse.data != null) {
              for (var menu in menuResponse.data!.menus) {
                for (var category in menu.categories) {
                  for (var item in category.menuItems) {
                    menuItemsMap[item.id] = item;
                  }
                }
              }
            }

            print('_loadExistingOrderItems: Loaded ${menuItemsMap.length} menu items');

            // Process ALL order items (both sent and pending) - user wants to see all previous orders
            int loadedCount = 0;
            int sentCount = 0;
            for (var orderItemData in allOrderItems) {
              print('_loadExistingOrderItems: Processing item: $orderItemData');
              
              final menuItemId = orderItemData['menu_item_id'] as int?;
              final customerNo = orderItemData['customer_no'] as int? ?? 1;
              final qty = orderItemData['qty'] as int? ?? 1;
              
              // Handle unit_price as both string and number
              double unitPrice = 0.0;
              final unitPriceValue = orderItemData['unit_price'];
              if (unitPriceValue is num) {
                unitPrice = unitPriceValue.toDouble();
              } else if (unitPriceValue is String) {
                unitPrice = double.tryParse(unitPriceValue) ?? 0.0;
              }
              
              final instructions = orderItemData['instructions'] as String?;
              
              // Get the unique ID from database - if it exists, item is saved
              final orderItemId = orderItemData['id'] as int?;
              
              // Get fire_status from API response (0 = hold, 1 = fire)
              bool fireStatus = false;
              final fireStatusValue = orderItemData['fire_status'];
              if (fireStatusValue != null) {
                if (fireStatusValue is bool) {
                  fireStatus = fireStatusValue;
                } else if (fireStatusValue is int) {
                  fireStatus = fireStatusValue == 1;
                } else if (fireStatusValue is String) {
                  fireStatus = fireStatusValue == '1' || fireStatusValue.toLowerCase() == 'true';
                }
              }
              
              // Get sequence for priority ordering
              int sequence = 0;
              final sequenceValue = orderItemData['sequence'];
              if (sequenceValue != null) {
                if (sequenceValue is int) {
                  sequence = sequenceValue;
                } else if (sequenceValue is String) {
                  sequence = int.tryParse(sequenceValue) ?? 0;
                }
              }
              
              // Get created_at timestamp
              DateTime? createdAt;
              final createdAtValue = orderItemData['created_at'];
              if (createdAtValue != null) {
                if (createdAtValue is String) {
                  createdAt = DateTime.tryParse(createdAtValue);
                }
              }
              
              if (orderItemId != null) {
                sentCount++; // Count saved items
              }
              
              print('_loadExistingOrderItems: menu_item_id: $menuItemId, customer_no: $customerNo, qty: $qty, unit_price: $unitPrice, orderItemId: $orderItemId, fireStatus: $fireStatus');
              
              if (menuItemId == null) {
                print('_loadExistingOrderItems: Skipping item - no menu_item_id');
                continue;
              }
              
              // Get menu item details - prioritize getting name from API response
              String itemName = '';
              double itemPrice = unitPrice;
              
              // First, try to get name from order_item's menu_item relationship (if API includes it)
              if (orderItemData['menu_item'] != null) {
                final menuItemData = orderItemData['menu_item'] as Map<String, dynamic>?;
                itemName = menuItemData?['name'] as String? ?? '';
              }
              
              // If not found in API response, try from loaded menu map
              if (itemName.isEmpty) {
                final menuItem = menuItemsMap[menuItemId];
                if (menuItem != null) {
                  itemName = menuItem.name;
                  // Use unit_price from order_item if available, otherwise use menu item price
                  if (unitPrice <= 0) {
                    itemPrice = menuItem.price;
                  }
                }
              }
              
              // If still no name found, reload menu and try again, or use a descriptive fallback
              if (itemName.isEmpty) {
                print('_loadExistingOrderItems: Menu item name not found for id: $menuItemId, reloading menu...');
                // Reload menu to ensure we have latest data
                final menuResponseRetry = await ApiService.getMenu();
                if (menuResponseRetry.success && menuResponseRetry.data != null) {
                  for (var menu in menuResponseRetry.data!.menus) {
                    for (var category in menu.categories) {
                      for (var item in category.menuItems) {
                        if (item.id == menuItemId) {
                          itemName = item.name;
                          if (unitPrice <= 0) {
                            itemPrice = item.price;
                          }
                          break;
                        }
                      }
                    }
                  }
                }
                
                // Last resort: use menu_item_id as fallback (but this should rarely happen)
                if (itemName.isEmpty) {
                  itemName = 'Menu Item #$menuItemId';
                  print('_loadExistingOrderItems: WARNING - Using fallback name for menu_item_id: $menuItemId');
                }
              }
              
              // If unit_price is 0 and we still don't have a price, skip this item
              if (unitPrice <= 0 && itemPrice <= 0) {
                print('_loadExistingOrderItems: Skipping item - no price available');
                continue;
              }
              
              if (customerNo >= 1 && customerNo <= customers.length) {
                // Add to the appropriate customer (customer_no is 1-based)
                final customerIndex = customerNo - 1;
                final customer = customers[customerIndex];
                
                // Check if item already exists (same menu_item_id)
                final existingIndex = customer.items.indexWhere(
                  (item) => item.menuItemId == menuItemId,
                );
                
                if (existingIndex >= 0) {
                  // Update quantity if exists
                  customer.items[existingIndex].quantity += qty;
                  print('_loadExistingOrderItems: Updated quantity for existing item: $itemName');
                } else {
                  // Add new item - store the unique ID from database
                  final dbOrderItemId = orderItemData['id'] as int?;
                  customer.items.add(OrderItem(
                    name: itemName,
                    price: itemPrice,
                    icon: Icons.restaurant_menu,
                    addedTime: createdAt ?? DateTime.now(),
                    menuItemId: menuItemId,
                    quantity: qty,
                    instructions: instructions,
                    orderItemId: dbOrderItemId, // Store unique ID from database (null = not saved yet)
                    fireStatus: fireStatus, // Store fire_status from database
                    sequence: sequence, // Store sequence for priority
                    createdAt: createdAt, // Store created_at timestamp
                  ));
                  loadedCount++;
                  print('_loadExistingOrderItems: Added item: $itemName (₹$itemPrice x $qty) to customer $customerNo - OrderItemID: $dbOrderItemId, FireStatus: ${fireStatus ? "Fire" : "Hold"}');
                }
              } else {
                print('_loadExistingOrderItems: Invalid customer_no: $customerNo (must be 1-${customers.length})');
              }
            }

            print('_loadExistingOrderItems: Successfully loaded $loadedCount items ($sentCount already sent, ${loadedCount - sentCount} pending)');

            if (mounted) {
              setState(() {
                // Update order ID if not already set
                _orderId = orderData['id'] as int? ?? _orderId;
                // Check if order is paid/completed
                final orderStatus = orderData['status'] as String?;
                _isOrderPaid = orderStatus == 'completed' || orderStatus == 'paid';
              });
              
              if (sentCount > 0) {
                print('_loadExistingOrderItems: Note: $sentCount items were already sent to kitchen (shown for reference)');
              }
              print('_loadExistingOrderItems: State updated, total items loaded');
            }
          } else {
            print('_loadExistingOrderItems: No order items found in response');
          }
        } else {
          print('_loadExistingOrderItems: orderData is null');
        }
      } else {
        print('_loadExistingOrderItems: Failed to load order - ${response.message}');
      }
    } catch (e, stackTrace) {
      print('_loadExistingOrderItems: Error loading order items - $e');
      print('_loadExistingOrderItems: Stack trace - $stackTrace');
    }
    print('========================================');
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


  // Multiple customers - dynamically created based on order.customer
  late List<Customer> customers;
  
  void _initializeCustomers(int customerCount) {
    customers = List.generate(
      customerCount,
      (index) => Customer(id: '${index + 1}', name: 'Cust ${index + 1}'),
    );
  }
  
  int selectedCustomerIndex = 0;
  
  Customer get selectedCustomer => customers[selectedCustomerIndex];
  
  // Legacy single order items (for backward compatibility)
  List<OrderItem> get orderItems => selectedCustomer.items;
  
  // Calculate hold and fire counts dynamically from all order items
  int get holdCount {
    int count = 0;
    for (var customer in customers) {
      for (var item in customer.items) {
        // Only count saved items (items that have been sent to kitchen)
        if (item.isSaved && item.isOnHold) {
          count += item.quantity; // Count by quantity, not just items
        }
      }
    }
    return count;
  }
  
  int get fireCount {
    int count = 0;
    for (var customer in customers) {
      for (var item in customer.items) {
        // Only count saved items (items that have been sent to kitchen)
        if (item.isSaved && item.isFired) {
          count += item.quantity; // Count by quantity, not just items
        }
      }
    }
    return count;
  }

  List<OrderItem> _getHoldItems() {
    List<OrderItem> items = [];
    for (var customer in customers) {
      for (var item in customer.items) {
        // Debug: Check item status
        print('_getHoldItems: Checking item "${item.name}" - isSaved: ${item.isSaved}, fireStatus: ${item.fireStatus}, orderItemId: ${item.orderItemId}');
        if (item.isSaved && item.isOnHold) {
          items.add(item);
          print('_getHoldItems: Added item "${item.name}" to hold list');
        }
      }
    }
    // Sort by sequence (lower sequence = higher priority)
    items.sort((a, b) => a.sequence.compareTo(b.sequence));
    print('_getHoldItems: Total hold items: ${items.length}');
    return items;
  }

  List<OrderItem> _getFireItems() {
    List<OrderItem> items = [];
    for (var customer in customers) {
      for (var item in customer.items) {
        // Debug: Check item status
        print('_getFireItems: Checking item "${item.name}" - isSaved: ${item.isSaved}, fireStatus: ${item.fireStatus}, orderItemId: ${item.orderItemId}');
        if (item.isSaved && item.isFired) {
          items.add(item);
          print('_getFireItems: Added item "${item.name}" to fire list');
        }
      }
    }
    // Sort by sequence (lower sequence = higher priority)
    items.sort((a, b) => a.sequence.compareTo(b.sequence));
    print('_getFireItems: Total fire items: ${items.length}');
    return items;
  }
  
  Future<void> _updateItemSequence(OrderItem item, int newSequence) async {
    if (item.orderItemId == null) return;
    
    final orderTicketId = _orderTicketId ?? widget.table?.orderTicketId;
    if (orderTicketId == null || !orderTicketId.startsWith('ORD-')) {
      return;
    }
    
    try {
      // Call API to update sequence
      await ApiService.updateItemSequence(
        orderTicketId: orderTicketId,
        orderItemId: item.orderItemId!,
        sequence: newSequence,
      );
    } catch (e) {
      print('Error updating sequence: $e');
    }
  }

  Widget _buildStatusSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    // Use a timer to refresh the elapsed time display every second
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        // Get fresh items and create mutable lists for reordering
        final holdItemsList = List<OrderItem>.from(_getHoldItems());
        final fireItemsList = List<OrderItem>.from(_getFireItems());
        
        // Debug: Print item counts
        print('_buildStatusSection: Hold items: ${holdItemsList.length}, Fire items: ${fireItemsList.length}');
        print('_buildStatusSection: Total customers: ${customers.length}');
        for (var i = 0; i < customers.length; i++) {
          print('_buildStatusSection: Customer $i has ${customers[i].items.length} items');
          for (var item in customers[i].items) {
            print('  - Item: ${item.name}, isSaved: ${item.isSaved}, fireStatus: ${item.fireStatus}, orderItemId: ${item.orderItemId}');
          }
        }
        
        // Force rebuild to update timers
        return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Status',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  // Reload order items when refresh is clicked
                  _loadExistingOrderItems();
                },
                tooltip: 'Refresh status',
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Expanded(
            child: Row(
              children: [
                // Hold Box
                Expanded(
                  child: _buildStatusBox(
                    'Hold',
                    Colors.orange.shade600,
                    Icons.pause_circle_outline,
                    holdItemsList,
                    holdCount,
                    isMobile: isMobile,
                    isHold: true,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                // Fire Box
                Expanded(
                  child: _buildStatusBox(
                    'Fire',
                    Colors.red.shade600,
                    Icons.local_fire_department,
                    fireItemsList,
                    fireCount,
                    isMobile: isMobile,
                    isHold: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildStatusBox(
    String title,
    Color color,
    IconData icon,
    List<OrderItem> items,
    int count, {
    required bool isMobile,
    required bool isHold,
  }) {
    return DragTarget<OrderItem>(
      onAccept: (draggedItem) {
        if (!isHold) {
          // Item dropped on Fire - trigger explosion and call API
          _triggerFireAnimation();
          _fireItems();
        }
      },
      onWillAccept: (data) => !isHold, // Only accept drops on Fire box
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: candidateData.isNotEmpty && !isHold
                  ? color.withOpacity(0.8)
                  : color.withOpacity(0.3),
              width: candidateData.isNotEmpty && !isHold ? 3 : 2,
            ),
            boxShadow: candidateData.isNotEmpty && !isHold
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: isMobile ? 24 : 28),
                    SizedBox(width: isMobile ? 8 : 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: isMobile ? 28 : 36,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Items List
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: isMobile ? 48 : 64,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              Text(
                                candidateData.isNotEmpty && !isHold
                                    ? 'Drop here!'
                                    : 'No items',
                                style: TextStyle(
                                  color: candidateData.isNotEmpty && !isHold
                                      ? color
                                      : Colors.grey,
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: candidateData.isNotEmpty && !isHold
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          itemCount: items.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            setState(() {
                              final item = items.removeAt(oldIndex);
                              items.insert(newIndex, item);
                              
                              // Update sequences for all items in the list
                              for (int i = 0; i < items.length; i++) {
                                items[i].sequence = i;
                                // Update sequence via API for each item
                                _updateItemSequence(items[i], i);
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            final item = items[index];
                            // Use a unique key for each item
                            final uniqueKey = item.orderItemId != null 
                                ? '${item.orderItemId}_${item.sequence}_${index}'
                                : 'temp_${item.menuItemId}_${index}';
                            return _buildDraggableStatusItem(
                              item,
                              color,
                              isMobile: isMobile,
                              isHold: isHold,
                              index: index,
                              key: ValueKey(uniqueKey),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableStatusItem(
    OrderItem item,
    Color color, {
    required bool isMobile,
    required bool isHold,
    required int index,
    required Key key,
  }) {
    return Draggable<OrderItem>(
      key: key, // Key must be on the Draggable widget for ReorderableListView
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: isMobile ? 18 : 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(
          margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.drag_handle, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 8 : 10),
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Name - Full width, larger text
            Row(
              children: [
                Icon(Icons.drag_handle, color: color, size: isMobile ? 16 : 18),
                SizedBox(width: isMobile ? 6 : 8),
                Icon(item.icon, color: color, size: isMobile ? 20 : 22),
                SizedBox(width: isMobile ? 8 : 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 10),
            // Details Row: Quantity, Priority Number, Timer
            Row(
              children: [
                // Quantity
                if (item.quantity > 1)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.quantity > 1) SizedBox(width: isMobile ? 6 : 8),
                // Priority Number (without "Priority" text)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10,
                    vertical: isMobile ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.priority}',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                Spacer(),
                // Timer
                Icon(Icons.timer, size: isMobile ? 14 : 16, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(
                  item.elapsedTimeString,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Progress bar based on elapsed time (visual indicator)
            SizedBox(height: isMobile ? 4 : 6),
            LinearProgressIndicator(
              value: (item.elapsedTime.inSeconds / 300).clamp(0.0, 1.0), // 5 minutes max
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _triggerFireAnimation() {
    // This will be handled by the explosion animation in the widget
    // For now, we can show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.white),
            SizedBox(width: 8),
            Text('Item fired! 🔥'),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
    // Prevent adding items if order is paid
    if (_isOrderPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add items. Order is already paid.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final targetIndex = customerIndex == -1 ? selectedCustomerIndex : customerIndex;
    
    setState(() {
      // Check if there's a TEMPORARY item (no orderItemId = not saved yet) with the same menu_item_id
      // We only merge with temporary items, not with saved items (they have orderItemId)
      final existingTemporaryItemIndex = customers[targetIndex].items.indexWhere(
        (orderItem) => orderItem.menuItemId == item.id && orderItem.isTemporary,
      );
      
      if (existingTemporaryItemIndex >= 0) {
        // Increase quantity if temporary item exists (not saved yet)
        customers[targetIndex].items[existingTemporaryItemIndex].quantity++;
        print('_addToOrder: Increased quantity for temporary item: ${item.name} (now ${customers[targetIndex].items[existingTemporaryItemIndex].quantity})');
      } else {
        // Add new temporary item (no orderItemId = not saved in database yet)
        // This allows adding more of the same item even if it was already sent before
        // MenuItem.price is already a double, use it directly
        customers[targetIndex].items.add(OrderItem(
          name: item.name,
          price: item.price, // Already a double from MenuItem
          icon: Icons.restaurant_menu,
          addedTime: DateTime.now(),
          menuItemId: item.id,
          quantity: 1,
          orderItemId: null, // New items have no ID (temporary)
          fireStatus: false, // New items default to hold (not fired)
        ));
        print('_addToOrder: Added new temporary item: ${item.name} (price: ${item.price} (${item.price.runtimeType}), total items in customer: ${customers[targetIndex].items.length})');
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
    final item = customers[customerIndex].items[itemIndex];
    
    // Only allow deleting temporary items (not saved in database)
    if (item.isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete item that is already saved. This item was sent to kitchen.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
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

  void _openPaymentScreen() {
    // Check if we have order_ticket_id
    final orderTicketId = _orderTicketId ?? widget.table?.orderTicketId;
    
    if (orderTicketId == null || orderTicketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order Ticket ID not found. Please ensure the table is reserved.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Collect all order items from all customers
    final List<Map<String, dynamic>> orderItems = [];
    for (var customer in customers) {
      for (var item in customer.items) {
        orderItems.add({
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'menu_item_id': item.menuItemId,
        });
      }
    }

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items in order to generate bill'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: allCustomersTotal * 1.1, // Total with tax
          orderTicketId: orderTicketId,
          tableName: widget.table?.name,
          orderTicketTitle: widget.table?.orderTicketTitle,
          orderStartTime: _orderStartTime,
          orderItems: orderItems,
        ),
      ),
    ).then((result) {
      // Handle payment result if needed
      if (result != null && result['success'] == true && result['paid'] == true) {
        setState(() {
          _isOrderPaid = true; // Mark order as paid
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment processed successfully: ${result['type'] ?? result['payment_method']}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Optionally navigate back or show message
      }
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

    // Collect all items from all customers - ONLY items that haven't been sent yet
    // Also track which OrderItem objects correspond to each item we're sending
    final List<Map<String, dynamic>> itemsToSend = [];
    final List<OrderItem> sentOrderItems = []; // Track the actual OrderItem objects
    
    for (var customerIndex = 0; customerIndex < customers.length; customerIndex++) {
      final customer = customers[customerIndex];
      final customerNo = customerIndex + 1; // Customer numbers are 1-based
      
      for (final orderItem in customer.items) {
        // Only send temporary items (not saved in database yet - no orderItemId)
        // Items with orderItemId are already saved/sent
        if (orderItem.isSaved) {
          print('_sendToKitchen: Skipping item "${orderItem.name}" - already saved (ID: ${orderItem.orderItemId})');
          continue;
        }
        
        // Convert each order item to API format
        // Ensure price is definitely a number - convert to double explicitly
        final unitPrice = orderItem.price is double 
            ? orderItem.price 
            : (orderItem.price is num 
                ? orderItem.price.toDouble() 
                : double.tryParse(orderItem.price.toString()) ?? 0.0);
        
        final itemData = <String, dynamic>{
          'menu_item_id': orderItem.menuItemId,
          'qty': orderItem.quantity,
          'unit_price': unitPrice, // Explicitly converted to double
          'customer_no': customerNo,
          if (orderItem.instructions != null && orderItem.instructions!.isNotEmpty)
            'instructions': orderItem.instructions,
          if (orderItem.decisionIds != null && orderItem.decisionIds!.isNotEmpty)
            'decisions': orderItem.decisionIds!.map((id) => {'decision_id': id}).toList(),
          if (orderItem.modifiers != null && orderItem.modifiers!.isNotEmpty)
            'modifiers': orderItem.modifiers!.map((modifier) {
              // Ensure modifier prices are numbers
              dynamic modPrice = modifier['price'];
              double modPriceDouble = modPrice is num 
                  ? modPrice.toDouble() 
                  : double.tryParse(modPrice.toString()) ?? 0.0;
              
              return <String, dynamic>{
                'modifier_id': modifier['modifier_id'] as int,
                'qty': modifier['qty'] as int,
                'price': modPriceDouble,
              };
            }).toList(),
        };
        itemsToSend.add(itemData);
        sentOrderItems.add(orderItem); // Track which OrderItem this corresponds to
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

    // Final safety check: Ensure all prices are numbers (not strings) before encoding
    for (var item in itemsToSend) {
      final unitPrice = item['unit_price'];
      if (unitPrice is String) {
        print('_sendToKitchen: FIXING - unit_price is String: $unitPrice');
        item['unit_price'] = double.tryParse(unitPrice) ?? 0.0;
      } else if (unitPrice is! num) {
        print('_sendToKitchen: FIXING - unit_price is not a number: $unitPrice (${unitPrice.runtimeType})');
        item['unit_price'] = double.tryParse(unitPrice.toString()) ?? 0.0;
      }
      
      // Also check modifiers
      if (item['modifiers'] != null) {
        final modifiers = item['modifiers'] as List;
        for (var mod in modifiers) {
          final modPrice = mod['price'];
          if (modPrice is String) {
            print('_sendToKitchen: FIXING - modifier price is String: $modPrice');
            mod['price'] = double.tryParse(modPrice) ?? 0.0;
          } else if (modPrice is! num) {
            mod['price'] = double.tryParse(modPrice.toString()) ?? 0.0;
          }
        }
      }
    }

    try {
      // Create formatted request body for debugging
      // Ensure all numeric values are properly typed before encoding
      final requestBody = {
        'order_ticket_id': orderTicketId, // MUST be ORD-20251121-XJROYU, NOT 20251121-01T1
        'order_id': _orderId,
        'items': itemsToSend,
      };
      
      // Print formatted JSON for debugging - wrap in try-catch to handle any type errors
      String formattedJson;
      String rawJson;
      try {
        formattedJson = const JsonEncoder.withIndent('  ').convert(requestBody);
        rawJson = jsonEncode(requestBody);
      } catch (e) {
        print('ERROR encoding JSON: $e');
        print('Request body types:');
        for (var item in itemsToSend) {
          print('  unit_price: ${item['unit_price']} (${item['unit_price'].runtimeType})');
        }
        rethrow; // Re-throw to be caught by outer catch
      }
      
      print('========================================');
      print('📤 PREPARING REQUEST TO: /api/pos/send-to-kitchen');
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
        
        // Update items with their returned IDs from database
        // This marks them as "saved" so they won't be sent again (duplicate prevention)
        if (newItemsCount > 0) {
          final newItems = data?['new_items'] as List<dynamic>? ?? [];
          
          print('_sendToKitchen: Received ${newItems.length} new items from API');
          print('_sendToKitchen: Sent ${sentOrderItems.length} items');
          
          // Match sent items with returned items by index (they should be in the same order)
          // This is more reliable than matching by properties
          bool updatedAny = false;
          for (var i = 0; i < sentOrderItems.length && i < newItems.length; i++) {
            final sentItem = sentOrderItems[i];
            final returnedItem = newItems[i];
            
            // Verify it's the same item (safety check)
            final returnedMenuItemId = returnedItem['menu_item_id'] as int?;
            final returnedId = returnedItem['id'] as int?;
            
            // Get fire_status from API response
            bool returnedFireStatus = false;
            final fireStatusValue = returnedItem['fire_status'];
            if (fireStatusValue != null) {
              if (fireStatusValue is bool) {
                returnedFireStatus = fireStatusValue;
              } else if (fireStatusValue is int) {
                returnedFireStatus = fireStatusValue == 1;
              } else if (fireStatusValue is String) {
                returnedFireStatus = fireStatusValue == '1' || fireStatusValue.toLowerCase() == 'true';
              }
            }
            
            // Get sequence from API response
            int returnedSequence = 0;
            final sequenceValue = returnedItem['sequence'];
            if (sequenceValue != null) {
              if (sequenceValue is int) {
                returnedSequence = sequenceValue;
              } else if (sequenceValue is String) {
                returnedSequence = int.tryParse(sequenceValue) ?? 0;
              }
            }
            
            // Get created_at from API response
            DateTime? returnedCreatedAt;
            final createdAtValue = returnedItem['created_at'];
            if (createdAtValue != null && createdAtValue is String) {
              returnedCreatedAt = DateTime.tryParse(createdAtValue);
            }
            
            if (returnedMenuItemId == sentItem.menuItemId && returnedId != null) {
              // Update item with its database ID - this marks it as saved
              sentItem.orderItemId = returnedId;
              // Update fire_status from API response
              sentItem.fireStatus = returnedFireStatus;
              // Update sequence from API response
              sentItem.sequence = returnedSequence;
              // Update created_at from API response
              if (returnedCreatedAt != null) {
                sentItem.createdAt = returnedCreatedAt;
              }
              updatedAny = true;
              print('_sendToKitchen: Updated item "${sentItem.name}" (menu_item_id: $returnedMenuItemId) with orderItemId: $returnedId, fireStatus: $returnedFireStatus, sequence: $returnedSequence (now marked as saved)');
            } else {
              print('_sendToKitchen: WARNING - Mismatch at index $i: sent menu_item_id=${sentItem.menuItemId}, returned menu_item_id=$returnedMenuItemId');
            }
          }
          
          // If index matching didn't work, fall back to property matching
          if (!updatedAny && newItems.isNotEmpty) {
            print('_sendToKitchen: Index matching failed, trying property matching...');
            for (var sentItem in sentOrderItems) {
              if (sentItem.isSaved) continue; // Already updated
              
              for (var returnedItem in newItems) {
                final returnedMenuItemId = returnedItem['menu_item_id'] as int?;
                final returnedCustomerNo = returnedItem['customer_no'] as int? ?? 1;
                final returnedQty = returnedItem['qty'] as int?;
                final returnedId = returnedItem['id'] as int?;
                
                // Find which customer this sentItem belongs to
                int sentItemCustomerNo = 1;
                for (var i = 0; i < customers.length; i++) {
                  if (customers[i].items.contains(sentItem)) {
                    sentItemCustomerNo = i + 1;
                    break;
                  }
                }
                
                // Get fire_status from API response
                bool returnedFireStatus = false;
                final fireStatusValue = returnedItem['fire_status'];
                if (fireStatusValue != null) {
                  if (fireStatusValue is bool) {
                    returnedFireStatus = fireStatusValue;
                  } else if (fireStatusValue is int) {
                    returnedFireStatus = fireStatusValue == 1;
                  } else if (fireStatusValue is String) {
                    returnedFireStatus = fireStatusValue == '1' || fireStatusValue.toLowerCase() == 'true';
                  }
                }
                
                // Get sequence from API response
                int returnedSequence = 0;
                final sequenceValue = returnedItem['sequence'];
                if (sequenceValue != null) {
                  if (sequenceValue is int) {
                    returnedSequence = sequenceValue;
                  } else if (sequenceValue is String) {
                    returnedSequence = int.tryParse(sequenceValue) ?? 0;
                  }
                }
                
                // Get created_at from API response
                DateTime? returnedCreatedAt;
                final createdAtValue = returnedItem['created_at'];
                if (createdAtValue != null && createdAtValue is String) {
                  returnedCreatedAt = DateTime.tryParse(createdAtValue);
                }
                
                // Match by menu_item_id, customer_no, and qty
                if (returnedMenuItemId == sentItem.menuItemId &&
                    returnedCustomerNo == sentItemCustomerNo &&
                    returnedQty == sentItem.quantity &&
                    returnedId != null) {
                  sentItem.orderItemId = returnedId;
                  // Update fire_status from API response
                  sentItem.fireStatus = returnedFireStatus;
                  // Update sequence from API response
                  sentItem.sequence = returnedSequence;
                  // Update created_at from API response
                  if (returnedCreatedAt != null) {
                    sentItem.createdAt = returnedCreatedAt;
                  }
                  updatedAny = true;
                  print('_sendToKitchen: Updated item "${sentItem.name}" with ID: $returnedId, fireStatus: $returnedFireStatus, sequence: $returnedSequence (property match)');
                  break;
                }
              }
            }
          }
          
          // Update UI to reflect saved items
          if (updatedAny && mounted) {
            setState(() {
              // State updated - items now have orderItemId and are marked as saved
            });
            print('_sendToKitchen: Updated ${sentOrderItems.where((item) => item.isSaved).length} items as saved');
          } else {
            print('_sendToKitchen: WARNING - No items were marked as saved! This will cause duplicates.');
          }
        }
        
        // Note: newItemsCount should always be > 0 if we have items to send
        // because frontend only sends items without orderItemId (new/temporary items)
        if (newItemsCount == 0) {
          // This should rarely happen, but handle it gracefully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('No new items to send. All items are already saved.'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Show beautiful success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Submitted Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${newItemsCount} item(s) sent to kitchen',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
            ),
          );

          // Don't navigate away - user stays on POS screen
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

  Future<void> _fireItems({List<int>? specificItemIds, List<Map<String, dynamic>>? itemsSequence}) async {
    // Check if we have order_ticket_id
    final orderTicketId = _orderTicketId ?? widget.table?.orderTicketId;
    
    if (orderTicketId == null || orderTicketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order Ticket ID not found. Please ensure the table is reserved.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verify we're using ID format (starts with "ORD-"), not title format
    if (!orderTicketId.startsWith('ORD-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid order ticket ID format. Expected format: ORD-20251121-XXXXX\nGot: $orderTicketId'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Check if there are any items on hold (if not firing specific items)
    if (specificItemIds == null && holdCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items on hold to fire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final response = await ApiService.fireItem(
        orderTicketId: orderTicketId,
        orderItemIds: specificItemIds,
        itemsSequence: itemsSequence,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data!;
        final updatedItemsCount = data['updated_items_count'] as int? ?? 0;
        final orderItems = data['order_items'] as List<dynamic>? ?? [];

        // Update fire_status and sequence for all order items in the response
        if (orderItems.isNotEmpty) {
          // Create maps of orderItemId -> fire_status and sequence from API response
          final Map<int, bool> fireStatusMap = {};
          final Map<int, int> sequenceMap = {};
          final Map<int, DateTime?> createdAtMap = {};
          
          for (var item in orderItems) {
            final orderItemId = item['id'] as int?;
            if (orderItemId != null) {
              // Get fire_status
              final fireStatusValue = item['fire_status'];
              bool fireStatus = false;
              if (fireStatusValue != null) {
                if (fireStatusValue is bool) {
                  fireStatus = fireStatusValue;
                } else if (fireStatusValue is int) {
                  fireStatus = fireStatusValue == 1;
                } else if (fireStatusValue is String) {
                  fireStatus = fireStatusValue == '1' || fireStatusValue.toLowerCase() == 'true';
                }
              }
              fireStatusMap[orderItemId] = fireStatus;
              
              // Get sequence
              final sequenceValue = item['sequence'];
              int sequence = 0;
              if (sequenceValue != null) {
                if (sequenceValue is int) {
                  sequence = sequenceValue;
                } else if (sequenceValue is String) {
                  sequence = int.tryParse(sequenceValue) ?? 0;
                }
              }
              sequenceMap[orderItemId] = sequence;
              
              // Get created_at
              final createdAtValue = item['created_at'];
              DateTime? createdAt;
              if (createdAtValue != null && createdAtValue is String) {
                createdAt = DateTime.tryParse(createdAtValue);
              }
              if (createdAt != null) {
                createdAtMap[orderItemId] = createdAt;
              }
            }
          }

          // Update all order items in all customers
          for (var customer in customers) {
            for (var item in customer.items) {
              if (item.orderItemId != null) {
                if (fireStatusMap.containsKey(item.orderItemId)) {
                  item.fireStatus = fireStatusMap[item.orderItemId]!;
                }
                if (sequenceMap.containsKey(item.orderItemId)) {
                  item.sequence = sequenceMap[item.orderItemId]!;
                }
                if (createdAtMap.containsKey(item.orderItemId)) {
                  item.createdAt = createdAtMap[item.orderItemId];
                }
              }
            }
          }

          setState(() {}); // Refresh UI to show updated counts and timers
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items Fired Successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$updatedItemsCount item(s) fired',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
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
          content: Text('Error firing items: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
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
      length: 3,
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
                Tab(text: 'Status'),
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
                // Status Tab
                _buildStatusSection(),
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
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            item.name,
                                                            style: TextStyle(
                                                              fontSize: isMobile ? 14 : 16,
                                                              fontWeight: FontWeight.w500,
                                                              color: item.isSaved 
                                                                  ? Colors.grey.shade600 
                                                                  : Colors.black87,
                                                              decoration: item.isSaved 
                                                                  ? TextDecoration.lineThrough 
                                                                  : null,
                                                            ),
                                                          ),
                                                        ),
                                                        if (item.isSaved)
                                                          Padding(
                                                            padding: EdgeInsets.only(left: 8),
                                                            child: Container(
                                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.green.shade100,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child:                                                               Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    item.fireStatus ? Icons.local_fire_department : Icons.pause_circle,
                                                                    size: 12,
                                                                    color: item.fireStatus ? Colors.orange.shade700 : Colors.blue.shade700,
                                                                  ),
                                                                  SizedBox(width: 4),
                                                                  Text(
                                                                    item.fireStatus ? 'Fire' : 'Hold',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: item.fireStatus ? Colors.orange.shade700 : Colors.blue.shade700,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                      if (item.quantity > 1)
                                                        Text(
                                                          'Qty: ${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                                                          style: TextStyle(
                                                            fontSize: isMobile ? 11 : 12,
                                                            color: item.isSaved 
                                                                ? Colors.grey.shade500 
                                                                : Colors.grey.shade600,
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
                                              // Only show delete button for temporary items (not saved)
                                              if (!item.isSaved) ...[
                                                SizedBox(width: 4),
                                                IconButton(
                                                  icon: Icon(Icons.close, size: isMobile ? 18 : 20),
                                                  color: Colors.red.shade400,
                                                  padding: EdgeInsets.all(isMobile ? 4 : 6),
                                                  constraints: BoxConstraints(),
                                                  onPressed: () => _removeItem(index, itemIndex),
                                                  tooltip: 'Remove item',
                                                ),
                                              ],
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
                      child: ElevatedButton.icon(
                        onPressed: (allCustomersTotal == 0 || _isOrderPaid) ? null : _openPaymentScreen,
                        icon: Icon(
                          Icons.receipt_long,
                          size: isMobile ? 18 : 20,
                        ),
                        label: Text(
                          'Bill',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (allCustomersTotal == 0 || _isSendingToKitchen || _isOrderPaid) ? null : _sendToKitchen,
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
            holdItems: _getHoldItems(),
            fireItems: _getFireItems(),
            onItemMovedToFire: (item) {
              // Call API to fire the item
              _fireItems();
            },
            onHoldLongPress: () {
              // Long press on Hold box - fire all hold items
              if (holdCount > 0) {
                _fireItems();
              }
            },
          ),
          // Status Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Show status in a bottom sheet (works for both mobile and desktop)
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.assessment,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Order Status',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          // Status content
                          Expanded(
                            child: _buildStatusSection(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.assessment,
                  size: 20,
                ),
                label: Text(
                  'Status',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
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