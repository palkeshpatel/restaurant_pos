# Complete Restaurant POS System Documentation

## Project Overview

This is a comprehensive Restaurant Point of Sale (POS) system built with Flutter, featuring a modern dark-themed UI, secure authentication, visual table management, drag-and-drop order management, real-time kitchen status tracking, and professional bill generation with PDF printing capabilities.

## Key Features

### 🔐 Authentication System

- 6-digit PIN authentication with visual feedback
- Number pad with clear and delete functions
- Demo PIN: `123456`
- Secure login system with immediate navigation

### 🍽️ Restaurant Floor Layout

- Visual table management with cartoon-style design
- Interactive table selection and joining functionality
- Canvas-based visualization for connected tables
- Responsive layout for mobile and desktop
- Real-time table status indicators (occupied/available)

### 📱 Modern POS Interface

- Intuitive drag-and-drop order management
- Customer-based order tracking (up to 4 customers per table)
- Category-based menu organization
- Real-time search functionality
- Responsive design for all screen sizes

### 🔥 Smart Status System

- **Fire Status** (🔥): Drinks, soda, tea - immediate preparation
- **Hold Status** (⏳): Main course items - preparation pending
- **Served Status** (✅): Completed items
- Real-time status counters with live updates
- Drag-and-drop status management in kitchen view

### 🧾 Professional Bill Management

- Complete bill preview with itemized listing
- Mark items for removal (strikethrough display)
- Automatic tax calculation (10%)
- PDF generation and printing functionality
- Professional bill formatting with restaurant branding

### 🖨️ Kitchen Management System

- Live order tracking with timer functionality
- Priority-based item organization
- Real-time status updates
- Progress indicators and visual feedback
- Print functionality for completed orders

## Technical Stack

### Core Technologies

- **Flutter**: Cross-platform mobile and desktop development
- **Dart**: Programming language
- **Provider**: State management
- **Material Design 3**: Modern UI components

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.1 # State management
  shared_preferences: ^2.2.2 # Local storage for settings
  printing: ^5.12.0 # PDF printing functionality
  pdf: ^3.10.7 # PDF document generation

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0 # Code linting
```

## Project Structure

```
restaurant_pos/
├── lib/
│   ├── main.dart                    # App entry point with provider setup
│   ├── models/
│   │   ├── menu_item.dart          # Menu item and category models
│   │   └── table_model.dart        # Table, customer, and order models
│   ├── providers/
│   │   ├── pos_provider.dart       # Main state management
│   │   └── settings_provider.dart  # Theme and layout settings
│   └── screens/
│       ├── login_screen.dart       # PIN authentication
│       ├── floor_layout_screen.dart # Restaurant floor layout
│       ├── pos_screen.dart         # Main POS interface
│       ├── bill_screen.dart        # Bill management and PDF generation
│       ├── kitchen_screen.dart     # Kitchen management system
│       └── settings_screen.dart    # App settings and preferences
├── android/                        # Android platform configuration
├── ios/                           # iOS platform configuration
├── web/                           # Web platform configuration
├── windows/                       # Windows desktop configuration
├── macos/                         # macOS desktop configuration
├── linux/                         # Linux desktop configuration
├── test/
│   └── widget_test.dart           # Basic widget tests
├── pubspec.yaml                   # Project dependencies and metadata
├── pubspec.lock                   # Dependency version lock file
├── analysis_options.yaml          # Code linting configuration
├── README.md                      # Project documentation
└── STEPS.md                       # Development steps and features
```

## Complete Implementation Details

### 1. Main Entry Point (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pos_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const RestaurantPOSApp());
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => POSProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Restaurant POS System',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4fc3f7),
                brightness: settingsProvider.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              useMaterial3: true,
            ),
            home: const LoginScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
```

### 2. Data Models

#### MenuItem Model (menu_item.dart)

```dart
class MenuItem {
  final int id;
  final String name;
  final double price;
  final String icon;
  final String description;
  final MenuCategory category;
  final bool isDrink; // Determines if item uses "fire" status

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    required this.category,
    this.isDrink = false,
  });
}

enum MenuCategory {
  combos, thali, soups, starters, maincourse,
  breads, rice, noodles, snacks, drinks
}
```

#### Table Model (table_model.dart)

```dart
class TableModel {
  final int id;
  final String name;
  final bool isOccupied;
  final List<Customer> customers;
  final bool isJoined;
  final List<int> joinedTables;

  TableModel({
    required this.id,
    required this.name,
    this.isOccupied = false,
    this.customers = const [],
    this.isJoined = false,
    this.joinedTables = const [],
  });
}

class Customer {
  final int id;
  final String name;
  final List<OrderItem> orders;

  Customer({
    required this.id,
    required this.name,
    this.orders = const [],
  });
}

class OrderItem {
  final int id;
  final String name;
  final double price;
  final String icon;
  final String description;
  final ItemStatus status;
  final int quantity;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    this.status = ItemStatus.hold,
    this.quantity = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

enum ItemStatus {
  fire, // For drinks, soda, tea
  hold, // For main course items (pending)
  served,
}
```

### 3. State Management (POS Provider)

The POSProvider handles all business logic including:

- PIN authentication (default: 123456)
- Table management and joining
- Order processing with drag-and-drop
- Status tracking and counters
- Bill calculations with 10% tax
- Menu item management (30+ items across 10 categories)

### 4. Authentication System (Login Screen)

Features:

- Gradient background with glassmorphism effects
- 6-digit PIN input with visual indicators
- Number pad with clear and delete functions
- Auto-login on complete PIN entry
- Error handling with user feedback

### 5. Floor Layout System (Floor Layout Screen)

Features:

- Responsive design for mobile and desktop
- Interactive table selection
- Table joining with visual connection lines
- Canvas-based custom painting for desktop view
- Grid layout for mobile devices
- Real-time table status updates

### 6. Main POS Interface (POS Screen)

Features:

- Three-panel responsive layout (Table, Menu, Categories)
- Drag-and-drop order management
- Customer-based order organization
- Real-time status counters
- Search functionality
- Category-based menu filtering

### 7. Kitchen Management (Kitchen Screen)

Features:

- Live order tracking with timers
- Drag-and-drop status management
- Priority-based item organization
- Progress indicators
- Status-based column layout
- Print functionality for served orders

### 8. Bill Management (Bill Screen)

Features:

- Professional PDF bill generation
- Item removal with strikethrough display
- Automatic tax calculation (10%)
- Print functionality
- Responsive layout for all devices

### 9. Settings System (Settings Screen)

Features:

- Theme selection (Dark/Light mode)
- Menu layout configuration (Top/Left/Right)
- Persistent settings with SharedPreferences
- Mobile-responsive navigation

## Menu Structure

The system includes 30+ menu items organized into 10 categories:

### Categories with Emojis:

- 🍱 **Combos**: Complete meal combinations
- 🍽️ **Thali**: Traditional Indian thali meals
- 🥣 **Soups & Salads**: Soups and fresh salads
- 🍢 **Starters**: Appetizers and starters
- 🍛 **Main Course**: Main dishes and curries
- 🫓 **Breads**: Indian breads and naan
- 🍚 **Rice & Biryani**: Rice dishes and biryani
- 🍜 **Fried Rice & Noodles**: Asian noodle dishes
- 🍿 **Snacks**: Light snacks and street food
- 🥤 **Drinks**: Beverages (marked as drinks for fire status)

## Platform Support

The project includes complete platform configurations for:

- **Android**: Full native Android support with Gradle builds
- **iOS**: Complete iOS configuration with Xcode project
- **Web**: Web deployment configuration with PWA support
- **Windows**: Windows desktop application support
- **macOS**: macOS desktop application support
- **Linux**: Linux desktop application support

## Configuration Files

### pubspec.yaml

```yaml
name: restaurant_pos
description: "A new Flutter project."
version: 1.0.0+1

environment:
  sdk: ^3.8.1

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  printing: ^5.12.0
  pdf: ^3.10.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Custom linting rules can be added here
```

## Build and Deployment

### Development Setup

1. Install Flutter SDK (3.8.1 or higher)
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start development

### Platform-Specific Builds

- **Android**: `flutter build apk` or `flutter build appbundle`
- **iOS**: `flutter build ios`
- **Web**: `flutter build web`
- **Desktop**: `flutter build windows/macos/linux`

## Testing

Basic widget test included:

```dart
void main() {
  testWidgets('Restaurant POS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantPOSApp());
    expect(find.text('Enter PIN'), findsOneWidget);
  });
}
```

## Usage Instructions

### 1. Initial Setup

- Launch the application
- Enter PIN: `123456` on the login screen
- Access the restaurant floor layout

### 2. Table Management

- Select tables by tapping on them
- Join tables by selecting multiple tables
- Tap "Enter Table" to start taking orders

### 3. Order Management

- Browse menu by category or search
- Drag items from menu to customer cards
- Or tap "Add" button and select customer
- Monitor real-time status counters

### 4. Kitchen Workflow

- Navigate to Kitchen screen
- View orders by status (Fire/Hold/Served)
- Drag items between status columns
- Mark items as completed

### 5. Bill Generation

- View complete bill with all items
- Mark items for removal if needed
- Print professional PDF bill
- Finalize transaction

## Customization Guide

### Adding New Menu Items

1. Open `lib/providers/pos_provider.dart`
2. Add new items to the `_initializeMenuItems()` method
3. Specify category, price, icon, and description
4. Set `isDrink: true` for beverages

### Modifying Table Layout

1. Open `lib/screens/floor_layout_screen.dart`
2. Adjust table positions in `_getTablePosition()` method
3. Modify responsive layout calculations
4. Update table count in POSProvider

### Theme Customization

1. Open `lib/main.dart` and modify the ColorScheme
2. Update gradient colors throughout the app
3. Adjust theme colors in individual screens

### Status System Modification

1. Update `ItemStatus` enum in `table_model.dart`
2. Modify status colors and icons in relevant screens
3. Update kitchen screen layout accordingly

## Performance Features

- **Responsive Design**: Adapts to all screen sizes (mobile to desktop)
- **Efficient State Management**: Provider pattern for optimal performance
- **Real-time Updates**: Live counters and status tracking
- **Drag & Drop**: Intuitive item management with visual feedback
- **PDF Generation**: Professional document creation and printing
- **Persistent Settings**: User preferences saved locally

## Security Features

- **PIN Authentication**: 6-digit secure login system
- **Session Management**: Automatic logout functionality
- **Input Validation**: Proper validation for all user inputs
- **Error Handling**: Comprehensive error handling throughout

## Future Enhancements

Potential improvements could include:

- Multi-language support with internationalization
- Payment integration (cards, digital wallets)
- Inventory management system
- Customer loyalty programs
- Advanced analytics and reporting
- Kitchen display system integration
- Employee management and permissions
- Online ordering integration
- Reservation system
- Multi-location support

## Technical Architecture

The application follows Flutter best practices:

- **MVVM Pattern**: Clear separation of concerns
- **Provider Pattern**: Efficient state management
- **Responsive Design**: Mobile-first approach
- **Material Design 3**: Modern UI components
- **Cross-platform**: Single codebase for all platforms

This comprehensive POS system provides a complete solution for restaurant order management with modern UI, intuitive workflows, and professional bill generation capabilities.
