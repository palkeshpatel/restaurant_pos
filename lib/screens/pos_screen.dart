import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';
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
    _startTimer();
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

  final List<MenuItem> menuItems = [
    MenuItem(name: 'Bruschetta', price: 6.99, icon: Icons.bakery_dining, category: 'Appetizers'),
    MenuItem(name: 'Garlic Bread', price: 4.99, icon: Icons.bakery_dining, category: 'Appetizers'),
    MenuItem(name: 'Mozzarella Sticks', price: 7.99, icon: Icons.lunch_dining, category: 'Appetizers'),
    MenuItem(name: 'Chicken Wings', price: 9.99, icon: Icons.kebab_dining, category: 'Appetizers'),
    MenuItem(name: 'Nachos', price: 8.99, icon: Icons.dining, category: 'Appetizers'),
    MenuItem(name: 'Spring Rolls', price: 6.99, icon: Icons.egg, category: 'Appetizers'),
  ];

  final List<OrderItem> orderItems = [
    OrderItem(name: 'Margherita Pizza', price: 12.99, icon: Icons.local_pizza, addedTime: DateTime.now()),
    OrderItem(name: 'Caesar Salad', price: 8.99, icon: Icons.eco, addedTime: DateTime.now()),
    OrderItem(name: 'Coke', price: 2.50, icon: Icons.local_drink, addedTime: DateTime.now()),
  ];

  String selectedCategory = 'Appetizers';
  int holdCount = 2;
  int kitchenCount = 1;
  int servedCount = 0;

  double get subtotal => orderItems.fold(0, (sum, item) => sum + item.price);
  double get tax => subtotal * 0.1;
  double get total => subtotal + tax;

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

  void _addToOrder(MenuItem item) {
    setState(() {
      orderItems.add(OrderItem(
        name: item.name,
        price: item.price,
        icon: item.icon,
        addedTime: DateTime.now(),
      ));
    });
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to order'),
        duration: const Duration(seconds: 1),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
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
                          Container(
                            padding: EdgeInsets.all(isMobile ? 15 : 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCategory,
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 24,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
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
                    Expanded(
                      child: _buildMenuSection(),
                    ),
                    _buildCategorySection(),
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
          // Selected Table Info - Combined Header
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_restaurant, 
                  size: isMobile ? 28 : 32, 
                  color: Theme.of(context).colorScheme.primary
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Table 1',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ground Floor',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Order Items
          Expanded(
            child: Container(
              color: const Color(0xFFFFF3E0),
              padding: EdgeInsets.all(isMobile ? 10 : 15),
              child: orderItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items in order',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: orderItems.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = orderItems.removeAt(oldIndex);
                          orderItems.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        final duration = DateTime.now().difference(item.addedTime);
                        final minutes = duration.inMinutes;
                        final seconds = duration.inSeconds % 60;
                        final isCriticalTime = minutes >= 5;
                        
                        return Card(
                          key: ValueKey('${item.name}_$index'),
                          elevation: 3,
                          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.lightBlue.shade50,
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey.shade400,
                                  size: isMobile ? 20 : 24,
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                Icon(item.icon, 
                                     color: Theme.of(context).colorScheme.primary,
                                     size: isMobile ? 24 : 32),
                                SizedBox(width: isMobile ? 8 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: isMobile ? 4 : 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${item.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: isMobile ? 16 : 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.timer,
                                                size: isMobile ? 12 : 14,
                                                color: isCriticalTime ? Colors.orange : Colors.grey.shade600,
                                              ),
                                              SizedBox(width: isMobile ? 2 : 4),
                                              Text(
                                                '${minutes}m ${seconds}s',
                                                style: TextStyle(
                                                  fontSize: isMobile ? 10 : 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isCriticalTime ? Colors.orange : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: isMobile ? 18 : 20),
                                  color: Colors.red.shade400,
                                  onPressed: () {
                                    setState(() {
                                      orderItems.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          // Order Total
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTotalRow('Subtotal:', subtotal, isMobile: isMobile),
                _buildTotalRow('Tax Rate (10%):', tax, isMobile: isMobile),
                Divider(
                  thickness: 2,
                  color: Colors.grey.shade300,
                ),
                _buildTotalRow('Total:', total, isTotal: true, isMobile: isMobile),
                SizedBox(height: isMobile ? 10 : 15),
                Row(
                  children: [
                    if (!isMobile) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: orderItems.isEmpty ? null : () {
                            // Save as draft functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order saved as draft')),
                            );
                          },
                          icon: Icon(Icons.save_outlined, size: isMobile ? 16 : 20),
                          label: Text(
                            'Save Draft',
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: isMobile ? 1 : 2,
                      child: ElevatedButton.icon(
                        onPressed: orderItems.isEmpty ? null : _sendToKitchen,
                        icon: Icon(Icons.arrow_forward, size: isMobile ? 18 : 24),
                        label: Text(
                          'Send to Kitchen',
                          style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
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
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : 20,
          mainAxisSpacing: isMobile ? 12 : 20,
          childAspectRatio: isMobile ? 0.75 : 0.85,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return Card(
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
          // Categories
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return InkWell(
                  onTap: () => _selectCategory(category.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 16,
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
            kitchenCount: kitchenCount,
            servedCount: servedCount,
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