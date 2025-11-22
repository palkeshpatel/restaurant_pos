import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';

class HotelSafeScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChange;

  const HotelSafeScreen({super.key, required this.onThemeChange});

  @override
  State<HotelSafeScreen> createState() => _HotelSafeScreenState();
}

class _HotelSafeScreenState extends State<HotelSafeScreen> {
  Timer? _timer;
  List<OrderItem> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
    _startTimer();
  }

  void _loadAllOrders() {
    // Load all orders from all statuses (similar to kitchen status screen)
    _allOrders = [
      OrderItem(name: 'Burger', price: 12.99, icon: Icons.lunch_dining, addedTime: DateTime.now().subtract(const Duration(minutes: 10)), menuItemId: 1),
      OrderItem(name: 'Pizza', price: 14.99, icon: Icons.local_pizza, addedTime: DateTime.now().subtract(const Duration(minutes: 5)), menuItemId: 2),
      OrderItem(name: 'Margherita Pizza', price: 12.99, icon: Icons.local_pizza, addedTime: DateTime.now().subtract(const Duration(minutes: 15)), menuItemId: 3),
      OrderItem(name: 'Caesar Salad', price: 8.99, icon: Icons.eco, addedTime: DateTime.now().subtract(const Duration(minutes: 20)), menuItemId: 4),
      OrderItem(name: 'Chicken Wings', price: 9.99, icon: Icons.kebab_dining, addedTime: DateTime.now().subtract(const Duration(minutes: 8)), menuItemId: 5),
      OrderItem(name: 'Coke', price: 2.50, icon: Icons.local_drink, addedTime: DateTime.now().subtract(const Duration(minutes: 3)), menuItemId: 6),
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

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ApiService.logoutEmployee();
      await StorageService.removeCurrentEmployee();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(onThemeChange: widget.onThemeChange),
          ),
          (route) => false,
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
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.brown, size: isMobile ? 24 : 28),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: Text(
                            'Hotel Safe - All Orders',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 24,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    color: Colors.red,
                    iconSize: isMobile ? 20 : 24,
                    tooltip: 'Logout',
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
            // Orders List
            Expanded(
              child: Container(
                color: const Color(0xFFFFF3E0),
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: _allOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: isMobile ? 64 : 80,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _allOrders.length,
                        itemBuilder: (context, index) {
                          final item = _allOrders[index];
                          final duration = DateTime.now().difference(item.addedTime);
                          final minutes = duration.inMinutes;
                          final seconds = duration.inSeconds % 60;
                          
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: isMobile ? 24 : 32,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: isMobile ? 16 : 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: isMobile ? 4 : 8),
                                        Row(
                                          children: [
                                            Icon(Icons.table_restaurant, size: isMobile ? 14 : 16, color: Colors.grey),
                                            SizedBox(width: isMobile ? 4 : 8),
                                            Text(
                                              'Table ${(index % 6) + 1}',
                                              style: TextStyle(
                                                fontSize: isMobile ? 12 : 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            SizedBox(width: isMobile ? 12 : 16),
                                            Icon(Icons.timer, size: isMobile ? 14 : 16, color: Colors.orange),
                                            SizedBox(width: isMobile ? 4 : 8),
                                            Text(
                                              '${minutes}m ${seconds}s',
                                              style: TextStyle(
                                                fontSize: isMobile ? 12 : 14,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${item.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: isMobile ? 18 : 20,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(height: isMobile ? 4 : 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 2 : 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'In Kitchen',
                                          style: TextStyle(
                                            fontSize: isMobile ? 10 : 12,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            // Summary Footer
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Orders',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${_allOrders.length}',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Value',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${_allOrders.fold(0.0, (sum, item) => sum + item.price).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
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

