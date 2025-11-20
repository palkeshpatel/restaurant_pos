import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';
import '../models/customer.dart';
import 'kitchen_status_screen.dart';
import 'settings_screen.dart';
import '../widgets/status_count_widget.dart';

class POSScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const POSScreen({super.key, required this.onThemeChange});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  late List<Category> categories;
  Timer? _timer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    categories = [
      Category(name: 'Appetizers', icon: Icons.restaurant, isActive: true),
      Category(name: 'Main Courses', icon: Icons.restaurant_menu),
      Category(name: 'Desserts', icon: Icons.icecream),
      Category(name: 'Drinks', icon: Icons.local_drink),
      Category(name: 'Specials', icon: Icons.star),
    ];
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _startTimer();
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


  final List<MenuItem> menuItems = [
    MenuItem(name: 'Bruschetta', price: 6.99, icon: Icons.bakery_dining, category: 'Appetizers'),
    MenuItem(name: 'Garlic Bread', price: 4.99, icon: Icons.bakery_dining, category: 'Appetizers'),
    MenuItem(name: 'Mozzarella Sticks', price: 7.99, icon: Icons.lunch_dining, category: 'Appetizers'),
    MenuItem(name: 'Chicken Wings', price: 9.99, icon: Icons.kebab_dining, category: 'Appetizers'),
    MenuItem(name: 'Nachos', price: 8.99, icon: Icons.dining, category: 'Appetizers'),
    MenuItem(name: 'Spring Rolls', price: 6.99, icon: Icons.egg, category: 'Appetizers'),
  ];

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
  
  String selectedCategory = 'Appetizers';
  int holdCount = 2;
  int fireCount = 1;

  double get subtotal => selectedCustomer.subtotal;
  double get tax => selectedCustomer.tax;
  double get total => selectedCustomer.total;
  
  // Get total for all customers combined
  double get allCustomersTotal => customers.fold(0.0, (sum, cust) => sum + cust.total);

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
      // Update active state
      categories = categories.map((cat) {
        return Category(
          name: cat.name,
          icon: cat.icon,
          isActive: cat.name == category,
        );
      }).toList();
    });
  }

  void _addToOrder(MenuItem item, {int customerIndex = -1}) {
    final targetIndex = customerIndex == -1 ? selectedCustomerIndex : customerIndex;
    
    setState(() {
      // Check if item already exists in customer's order
      final existingItemIndex = customers[targetIndex].items.indexWhere(
        (orderItem) => orderItem.name == item.name,
      );
      
      if (existingItemIndex >= 0) {
        // Increase quantity if item exists
        customers[targetIndex].items[existingItemIndex].quantity++;
      } else {
        // Add new item
        customers[targetIndex].items.add(OrderItem(
          name: item.name,
          price: item.price,
          icon: item.icon,
          addedTime: DateTime.now(),
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

  void _sendToKitchen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KitchenStatusScreen(onThemeChange: widget.onThemeChange),
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
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
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
                  child: Text(
                    'Table 1: New Order',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 24,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
                                  selectedCategory,
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
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FilterChip(
                              selected: category.isActive,
                              label: Text(category.name),
                              avatar: Icon(
                                category.icon,
                                size: 18,
                                color: category.isActive 
                                    ? Colors.white 
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              selectedColor: Theme.of(context).colorScheme.primary,
                              onSelected: (selected) {
                                if (selected) {
                                  _selectCategory(category.name);
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
                Text(
                  'Table 1',
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
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Occupied',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
                        onPressed: allCustomersTotal == 0 ? null : _sendToKitchen,
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
                        child: Text(
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
    
    // Filter menu items by selected category and search query
    var filteredItems = menuItems.where((item) => item.category == selectedCategory).toList();
    
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) => 
        item.name.toLowerCase().contains(_searchQuery)
      ).toList();
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
                    'No items in this category',
                    style: TextStyle(
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
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
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
                          item.icon,
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
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
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
                            item.icon,
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
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
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
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return InkWell(
                  onTap: () => _selectCategory(category.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: category.isActive ? Theme.of(context).colorScheme.primary : null,
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
                          category.icon,
                          color: category.isActive ? Colors.white : Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: category.isActive ? FontWeight.w600 : FontWeight.w400,
                              color: category.isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
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