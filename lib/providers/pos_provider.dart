import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../models/menu_item.dart';

class POSProvider extends ChangeNotifier {
  // PIN Authentication
  String _currentPIN = '';
  bool _isAuthenticated = false;

  // Tables and Orders
  List<TableModel> _tables = [];
  TableModel? _selectedTable;
  List<MenuItem> _menuItems = [];

  // Status Counters
  Map<ItemStatus, int> _statusCounters = {
    ItemStatus.fire: 0,
    ItemStatus.hold: 0,
    ItemStatus.served: 0,
  };

  // Getters
  String get currentPIN => _currentPIN;
  bool get isAuthenticated => _isAuthenticated;
  List<TableModel> get tables => _tables;
  TableModel? get selectedTable => _selectedTable;
  List<MenuItem> get menuItems => _menuItems;
  Map<ItemStatus, int> get statusCounters => _statusCounters;

  POSProvider() {
    _initializeTables();
    _initializeMenuItems();
  }

  void _initializeTables() {
    _tables = List.generate(12, (index) {
      return TableModel(
        id: index + 1,
        name: 'Table ${index + 1}',
        isOccupied: index == 0, // Table 1 is occupied for demo
        customers: [
          Customer(id: 1, name: 'Customer 1'),
          Customer(id: 2, name: 'Customer 2'),
          Customer(id: 3, name: 'Customer 3'),
          Customer(id: 4, name: 'Customer 4'),
        ],
      );
    });
  }

  void _initializeMenuItems() {
    _menuItems = [
      // Combos
      MenuItem(id: 1, name: 'Punjabi Meal', price: 499, icon: '🍛', description: 'Paneer Butter Masala + Dal Fry + Butter Naan 1 piece + Rice', category: MenuCategory.combos),
      MenuItem(id: 2, name: 'Veg Meal', price: 499, icon: '🥗', description: 'Veg Kadhai + Butter Kulcha 2 pieces + Cucumber Salad', category: MenuCategory.combos),
      MenuItem(id: 3, name: 'Cheese Blast Combo', price: 499, icon: '🧀', description: 'Cheese Corn Capsicum + Garlic Naan (2 pieces)', category: MenuCategory.combos),
      
      // Thali
      MenuItem(id: 4, name: 'Fixed Punjabi Thali', price: 255, icon: '🍽️', description: '1 Paneer Sabji + 1 Veg Sabji + 3 Roti + Jeera Rice + Dal Fry + Salad + Papad + 1 Buttermilk', category: MenuCategory.thali),
      
      // Soups & Salads
      MenuItem(id: 5, name: 'Tomato Soup', price: 150, icon: '🍅', description: 'Fresh tomato soup with herbs', category: MenuCategory.soups),
      MenuItem(id: 6, name: 'Hot and Sour Soup', price: 140, icon: '🌶️', description: 'Spicy and tangy soup', category: MenuCategory.soups),
      MenuItem(id: 7, name: 'Manchow Soup', price: 150, icon: '🥣', description: 'Veg preparation', category: MenuCategory.soups),
      MenuItem(id: 8, name: 'Cucumber Salad', price: 85, icon: '🥒', description: 'Fresh cucumber salad', category: MenuCategory.soups),
      MenuItem(id: 9, name: 'Tomato Salad', price: 90, icon: '🍅', description: 'Fresh tomato salad', category: MenuCategory.soups),
      
      // Starters
      MenuItem(id: 10, name: 'Veg Manchurian Dry', price: 195, icon: '🍡', description: 'Crispy vegetable balls in manchurian sauce', category: MenuCategory.starters),
      
      // Main Course
      MenuItem(id: 11, name: 'Veg Manchurian Gravy', price: 190, icon: '🍛', description: 'Vegetable balls in savory gravy', category: MenuCategory.maincourse),
      MenuItem(id: 12, name: 'Paneer Chilli Gravy', price: 230, icon: '🧀', description: 'Spicy paneer in gravy', category: MenuCategory.maincourse),
      MenuItem(id: 13, name: 'Veg Kadhai', price: 200, icon: '🥘', description: 'Mixed vegetables in kadhai masala', category: MenuCategory.maincourse),
      MenuItem(id: 14, name: 'Paneer Butter Masala', price: 240, icon: '🧈', description: 'Paneer in rich buttery gravy', category: MenuCategory.maincourse),
      MenuItem(id: 15, name: 'Dal Fry', price: 150, icon: '🥘', description: 'Tempered lentil preparation', category: MenuCategory.maincourse),
      MenuItem(id: 16, name: 'Dal Tadka', price: 165, icon: '🥘', description: 'Lentils with tempering', category: MenuCategory.maincourse),
      
      // Breads
      MenuItem(id: 17, name: 'Roti', price: 20, icon: '🫓', description: 'Whole wheat flatbread', category: MenuCategory.breads),
      MenuItem(id: 18, name: 'Butter Naan', price: 45, icon: '🫓', description: 'Leavened bread with butter', category: MenuCategory.breads),
      MenuItem(id: 19, name: 'Garlic Naan', price: 90, icon: '🧄', description: 'Naan with garlic flavor', category: MenuCategory.breads),
      MenuItem(id: 20, name: 'Butter Kulcha', price: 50, icon: '🫓', description: 'Soft leavened bread with butter', category: MenuCategory.breads),
      
      // Rice & Biryani
      MenuItem(id: 21, name: 'Plain Rice', price: 140, icon: '🍚', description: 'Steamed basmati rice', category: MenuCategory.rice),
      MenuItem(id: 22, name: 'Jeera Rice', price: 150, icon: '🍚', description: 'Rice with cumin seeds', category: MenuCategory.rice),
      MenuItem(id: 23, name: 'Veg Biryani', price: 200, icon: '🍛', description: 'Basmati rice with vegetables', category: MenuCategory.rice),
      MenuItem(id: 24, name: 'Cheese Dum Biryani', price: 220, icon: '🧀', description: 'Basmati rice with cheese', category: MenuCategory.rice),
      
      // Noodles
      MenuItem(id: 25, name: 'Veg Fried Rice', price: 165, icon: '🍚', description: 'Stir-fried rice with vegetables', category: MenuCategory.noodles),
      MenuItem(id: 26, name: 'Hakka Noodles', price: 165, icon: '🍜', description: 'Stir-fried noodles', category: MenuCategory.noodles),
      MenuItem(id: 27, name: 'Schezwan Noodles', price: 180, icon: '🌶️', description: 'Spicy schezwan noodles', category: MenuCategory.noodles),
      
      // Snacks
      MenuItem(id: 28, name: 'Chinese Bhel', price: 195, icon: '🍿', description: 'Crispy noodles with sauces', category: MenuCategory.snacks),
      MenuItem(id: 29, name: 'Pav Bhaji', price: 150, icon: '🍞', description: 'Spicy vegetable curry with bread', category: MenuCategory.snacks),
      
      // Drinks (marked as drinks for "fire" status)
      MenuItem(id: 30, name: 'Buttermilk', price: 30, icon: '🥛', description: 'Refreshing spiced buttermilk', category: MenuCategory.drinks, isDrink: true),
    ];
  }

  // PIN Authentication Methods
  void addDigitToPIN(String digit) {
    if (_currentPIN.length < 6) {
      _currentPIN += digit;
      notifyListeners();
    }
  }

  void removeLastDigit() {
    if (_currentPIN.isNotEmpty) {
      _currentPIN = _currentPIN.substring(0, _currentPIN.length - 1);
      notifyListeners();
    }
  }

  void clearPIN() {
    _currentPIN = '';
    notifyListeners();
  }

  bool authenticatePIN(String pin) {
    // Default PIN is 123456 for demo
    if (pin == '123456' && pin.length == 6) {
      _isAuthenticated = true;
      _currentPIN = '';
      notifyListeners();
      return true;
    }
    _currentPIN = '';
    notifyListeners();
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _currentPIN = '';
    _selectedTable = null;
    notifyListeners();
  }

  // Table Management Methods
  void selectTable(TableModel table) {
    _selectedTable = table;
    notifyListeners();
  }

  void joinTables(int tableId1, int tableId2) {
    final table1Index = _tables.indexWhere((t) => t.id == tableId1);
    final table2Index = _tables.indexWhere((t) => t.id == tableId2);
    
    if (table1Index != -1 && table2Index != -1) {
      _tables[table1Index] = _tables[table1Index].copyWith(
        isJoined: true,
        joinedTables: [..._tables[table1Index].joinedTables, tableId2],
      );
      _tables[table2Index] = _tables[table2Index].copyWith(
        isJoined: true,
        joinedTables: [..._tables[table2Index].joinedTables, tableId1],
      );
      notifyListeners();
    }
  }

  void unjoinTables(int tableId1, int tableId2) {
    final table1Index = _tables.indexWhere((t) => t.id == tableId1);
    final table2Index = _tables.indexWhere((t) => t.id == tableId2);

    if (table1Index != -1 && table2Index != -1) {
      final updatedTable1JoinedTables = _tables[table1Index].joinedTables.where((id) => id != tableId2).toList();
      final updatedTable2JoinedTables = _tables[table2Index].joinedTables.where((id) => id != tableId1).toList();

      _tables[table1Index] = _tables[table1Index].copyWith(
        isJoined: updatedTable1JoinedTables.isNotEmpty,
        joinedTables: updatedTable1JoinedTables,
      );
      _tables[table2Index] = _tables[table2Index].copyWith(
        isJoined: updatedTable2JoinedTables.isNotEmpty,
        joinedTables: updatedTable2JoinedTables,
      );
      notifyListeners();
    }
  }

  // Order Management Methods
  void addOrderToCustomer(int customerId, MenuItem menuItem) {
    if (_selectedTable == null) {
      return;
    }

    final tableIndex = _tables.indexWhere((t) => t.id == _selectedTable!.id);
    if (tableIndex == -1) {
      return;
    }

    final customerIndex = _tables[tableIndex].customers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) {
      return;
    }
    
    final orderItem = OrderItem(
      id: menuItem.id,
      name: menuItem.name,
      price: menuItem.price,
      icon: menuItem.icon,
      description: menuItem.description,
      status: menuItem.isDrink ? ItemStatus.fire : ItemStatus.hold,
    );
    
    final updatedCustomers = List<Customer>.from(_tables[tableIndex].customers);
    updatedCustomers[customerIndex] = updatedCustomers[customerIndex].copyWith(
      orders: [...updatedCustomers[customerIndex].orders, orderItem],
    );
    
    _tables[tableIndex] = _tables[tableIndex].copyWith(customers: updatedCustomers);

    // CRITICAL: Update the selected table reference to point to the updated table
    _selectedTable = _tables[tableIndex];

    _updateStatusCounters();
    notifyListeners();
  }

  void removeOrderFromCustomer(int customerId, int orderItemId) {
    if (_selectedTable == null) return;
    
    final tableIndex = _tables.indexWhere((t) => t.id == _selectedTable!.id);
    if (tableIndex == -1) return;
    
    final customerIndex = _tables[tableIndex].customers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) return;
    
    final updatedCustomers = List<Customer>.from(_tables[tableIndex].customers);
    updatedCustomers[customerIndex] = updatedCustomers[customerIndex].copyWith(
      orders: updatedCustomers[customerIndex].orders.where((o) => o.id != orderItemId).toList(),
    );
    
    _tables[tableIndex] = _tables[tableIndex].copyWith(customers: updatedCustomers);
    _updateStatusCounters();
    notifyListeners();
  }

  void updateOrderStatus(int customerId, int orderItemId, ItemStatus newStatus) {
    if (_selectedTable == null) return;
    
    final tableIndex = _tables.indexWhere((t) => t.id == _selectedTable!.id);
    if (tableIndex == -1) return;
    
    final customerIndex = _tables[tableIndex].customers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) return;
    
    final updatedCustomers = List<Customer>.from(_tables[tableIndex].customers);
    final customer = updatedCustomers[customerIndex];
    
    final updatedOrders = customer.orders.map((order) {
      if (order.id == orderItemId) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();
    
    updatedCustomers[customerIndex] = customer.copyWith(orders: updatedOrders);
    _tables[tableIndex] = _tables[tableIndex].copyWith(customers: updatedCustomers);
    _updateStatusCounters();
    notifyListeners();
  }



  void reorderItems(List<OrderItem> reorderedItems) {
    // This method would handle reordering items within the same status
    // For now, we'll just notify listeners to refresh the UI
    notifyListeners();
  }

  void _updateStatusCounters() {
    _statusCounters = {
      ItemStatus.fire: 0,
      ItemStatus.hold: 0,
      ItemStatus.served: 0,
    };
    
    for (final table in _tables) {
      for (final customer in table.customers) {
        for (final order in customer.orders) {
          _statusCounters[order.status] = (_statusCounters[order.status] ?? 0) + 1;
        }
      }
    }
  }

  // Bill Management Methods
  List<OrderItem> getBillItems() {
    if (_selectedTable == null) return [];

    final billItems = <OrderItem>[];
    for (final customer in _selectedTable!.customers) {
      billItems.addAll(customer.orders);
    }
    return billItems;
  }

  double calculateTotal() {
    final billItems = getBillItems();
    final subtotal = billItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final tax = subtotal * 0.1; // 10% tax
    return subtotal + tax;
  }

  double calculateSubtotal() {
    final billItems = getBillItems();
    return billItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double calculateTax() {
    return calculateSubtotal() * 0.1;
  }

  void markItemForRemoval(int customerId, int orderItemId) {
    // This will be used for the bill preview where items can be marked for removal
    // Implementation depends on your specific requirements
    notifyListeners();
  }

  void clearAllOrders() {
    if (_selectedTable == null) return;
    
    final tableIndex = _tables.indexWhere((t) => t.id == _selectedTable!.id);
    if (tableIndex == -1) return;
    
    final updatedCustomers = _tables[tableIndex].customers.map((customer) {
      return customer.copyWith(orders: []);
    }).toList();
    
    _tables[tableIndex] = _tables[tableIndex].copyWith(customers: updatedCustomers);
    _updateStatusCounters();
    notifyListeners();
  }
}
