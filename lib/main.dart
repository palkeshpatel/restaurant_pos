import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const RestaurantPOSApp());
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC2626),
          primary: const Color(0xFFDC2626),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RestaurantLoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDC2626),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant,
                size: 60,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Restaurant POS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Professional Point of Sale System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Restaurant Login Screen
class RestaurantLoginScreen extends StatefulWidget {
  const RestaurantLoginScreen({super.key});

  @override
  State<RestaurantLoginScreen> createState() => _RestaurantLoginScreenState();
}

class _RestaurantLoginScreenState extends State<RestaurantLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDC2626),
              Color(0xFFEF4444),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 50,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your restaurant code to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _restaurantCodeController,
                            decoration: InputDecoration(
                              labelText: 'Restaurant Code',
                              hintText: 'Enter 6-digit code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.store),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter restaurant code';
                              }
                              if (value.length != 6) {
                                return 'Code must be 6 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => UserSelectionScreen(
                                        restaurantCode: _restaurantCodeController.text,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

// User Selection Screen
class UserSelectionScreen extends StatelessWidget {
  final String restaurantCode;

  const UserSelectionScreen({super.key, required this.restaurantCode});

  // Mock data - replace with actual API call
  final List<Map<String, String>> users = const [
    {'name': 'John Smith', 'role': 'Manager', 'code': 'MGR'},
    {'name': 'Sarah Johnson', 'role': 'Waiter', 'code': 'WTR'},
    {'name': 'Mike Wilson', 'role': 'Waiter', 'code': 'WTR'},
    {'name': 'Emily Davis', 'role': 'Waiter', 'code': 'WTR'},
    {'name': 'David Brown', 'role': 'Owner', 'code': 'OWN'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Text(
              'Restaurant Code: $restaurantCode',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user['role']!),
                      child: Icon(
                        _getRoleIcon(user['role']!),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      user['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${user['role']} • ${user['code']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PinScreen(
                            user: user,
                            restaurantCode: restaurantCode,
                          ),
                        ),
                      );
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Manager':
        return Colors.purple;
      case 'Owner':
        return Colors.amber[700]!;
      case 'Waiter':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Manager':
        return Icons.manage_accounts;
      case 'Owner':
        return Icons.business;
      case 'Waiter':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }
}

// PIN Screen
class PinScreen extends StatefulWidget {
  final Map<String, String> user;
  final String restaurantCode;

  const PinScreen({super.key, required this.user, required this.restaurantCode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  final int _pinLength = 4;

  void _addDigit(String digit) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += digit;
      });

      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    // Mock PIN verification - replace with actual authentication
    if (_pin == '1234') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => POSScreen(
            user: widget.user,
            restaurantCode: widget.restaurantCode,
          ),
        ),
      );
    } else {
      setState(() {
        _pin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PIN. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.user['name']!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.user['role']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pinLength,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? const Color(0xFFDC2626)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index < 9) {
                    return _buildNumberButton((index + 1).toString());
                  } else if (index == 9) {
                    return const SizedBox.shrink();
                  } else if (index == 10) {
                    return _buildNumberButton('0');
                  } else {
                    return _buildBackspaceButton();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return ElevatedButton(
      onPressed: () => _addDigit(number),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDC2626)),
        ),
        elevation: 2,
      ),
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return ElevatedButton(
      onPressed: _removeDigit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: const Icon(Icons.backspace, size: 24),
    );
  }
}

// POS System Screen
class POSScreen extends StatefulWidget {
  final Map<String, String> user;
  final String restaurantCode;

  const POSScreen({super.key, required this.user, required this.restaurantCode});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final List<Map<String, dynamic>> _cart = [];
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Pizza', 'icon': Icons.local_pizza},
    {'name': 'Burgers', 'icon': Icons.fastfood},
    {'name': 'Drinks', 'icon': Icons.local_drink},
    {'name': 'Desserts', 'icon': Icons.cake},
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'name': 'Margherita Pizza', 'price': 12.99, 'category': 'Pizza'},
    {'name': 'Pepperoni Pizza', 'price': 14.99, 'category': 'Pizza'},
    {'name': 'Classic Burger', 'price': 9.99, 'category': 'Burgers'},
    {'name': 'Cheese Burger', 'price': 11.99, 'category': 'Burgers'},
    {'name': 'Coca Cola', 'price': 2.99, 'category': 'Drinks'},
    {'name': 'Orange Juice', 'price': 3.99, 'category': 'Drinks'},
    {'name': 'Chocolate Cake', 'price': 5.99, 'category': 'Desserts'},
    {'name': 'Ice Cream', 'price': 4.99, 'category': 'Desserts'},
  ];

  String _selectedCategory = 'Pizza';

  @override
  Widget build(BuildContext context) {
    double total = _cart.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

    return Scaffold(
      appBar: AppBar(
        title: Text('POS - ${widget.user['name']}'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showUserInfo(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Categories Sidebar
          Container(
            width: 100,
            color: Colors.grey[100],
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: Icon(
                      category['icon'],
                      color: _selectedCategory == category['name']
                          ? const Color(0xFFDC2626)
                          : Colors.grey,
                    ),
                    title: Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedCategory == category['name']
                            ? const Color(0xFFDC2626)
                            : Colors.grey,
                        fontWeight: _selectedCategory == category['name']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedCategory == category['name'],
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'];
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Menu Items
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _menuItems.where((item) => item['category'] == _selectedCategory).length,
              itemBuilder: (context, index) {
                final items = _menuItems.where((item) => item['category'] == _selectedCategory).toList();
                final item = items[index];

                return Card(
                  child: InkWell(
                    onTap: () => _addToCart(item),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${item['price'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

          // Cart
          Container(
            width: 300,
            color: Colors.grey[50],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFDC2626),
                  child: const Text(
                    'Order Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(
                          child: Text(
                            'Cart is empty\nAdd items from the menu',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return ListTile(
                              title: Text(item['name']),
                              subtitle: Text('\$${item['price'].toStringAsFixed(2)} × ${item['quantity']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _removeFromCart(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (_cart.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _clearCart(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _checkout(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                                child: const Text('Checkout'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingIndex = _cart.indexWhere((cartItem) => cartItem['name'] == item['name']);
      if (existingIndex >= 0) {
        _cart[existingIndex]['quantity']++;
      } else {
        _cart.add({...item, 'quantity': 1});
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index]['quantity'] > 1) {
        _cart[index]['quantity']--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  void _checkout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text('Total: \$${_cart.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])).toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order completed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.user['name']}'),
            Text('Role: ${widget.user['role']}'),
            Text('Restaurant: $widget.restaurantCode'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RestaurantLoginScreen()),
      (route) => false,
    );
  }
}