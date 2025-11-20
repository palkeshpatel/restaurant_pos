# Restaurant POS System - Flutter App

## Project Overview

This is a complete Restaurant Point of Sale (POS) system built with Flutter, featuring a modern UI with dark theme and comprehensive functionality for restaurant operations.

## Features Implemented

1)Login secren (restorent login)
email
passwrd

2)after login you get user LIST that user is emaploy of restorent show we show list of empaly in mobile with name,in bracket role,

3)if user select witer role the he show 4 dights Pin Password sccreen

### 1. Authentication System

- **6-digit PIN Login**: Secure authentication with PIN entry
- **Demo PIN**: `123456` for testing
- **PIN Display**: Visual feedback with circular indicators
- **Number Pad**: Interactive number pad with clear and delete functions

### 2. Restaurant Floor Layout

- **Cartoon Table Design**: Visual representation of restaurant tables
- **Table Management**: Each table supports up to 4 customers
- **Table Joining**: Canvas-based visualization for joining tables
- **Interactive Selection**: Tap to select tables, visual feedback for selections
- **Status Indicators**: Shows occupied/available status

### 3. POS System with Fire/Hold Status

- **Menu Categories**: Organized menu with categories (Combos, Thali, Soups, etc.)
- **Item Management**: Add items to customer orders
- **Status System**:
  - **Fire Status**: For drinks, soda, tea (immediate preparation)
  - **Hold Status**: For main course items (preparation on hold)
  - **Served Status**: Completed items
  - **Pending Status**: Newly added items

### 4. Status Counters

- **Real-time Counters**: Shows count of items in each status
- **Visual Indicators**: Color-coded status with emojis
- **Live Updates**: Counters update automatically when status changes

### 5. Bill Management System

- **Bill Preview**: Complete bill with itemized list
- **Remove Items**: Mark items for removal (shows strikethrough)
- **Bill Calculation**: Automatic calculation of subtotal, tax (10%), and total
- **Print Functionality**: Generate and print PDF bills
- **Finalize Bill**: Complete the transaction and clear orders

## Project Structure

```
lib/
├── main.dart                 # App entry point with provider setup
├── models/
│   ├── table_model.dart     # Table and customer data models
│   └── menu_item.dart       # Menu item and category models
├── providers/
│   └── pos_provider.dart    # State management with ChangeNotifier
└── screens/
    ├── login_screen.dart    # PIN authentication screen
    ├── floor_layout_screen.dart # Restaurant floor layout
    ├── pos_screen.dart      # Main POS interface
    └── bill_screen.dart     # Bill preview and print
```

## Dependencies Used

- **provider**: State management
- **shared_preferences**: Local storage
- **printing**: PDF generation and printing
- **pdf**: PDF document creation

## Key Components

### POSProvider

Central state management class handling:

- PIN authentication
- Table management
- Order processing
- Status tracking
- Bill calculations

### Table Model

- Table information with customer support
- Order items with status tracking
- Table joining functionality

### Menu System

- Comprehensive menu with 30+ items
- Category-based organization
- Status-based preparation workflow

## Usage Instructions

### 1. Login

- Enter the 6-digit PIN: `123456`
- Use the number pad to input PIN
- Tap "Login" to authenticate

### 2. Select Table

- View restaurant floor layout
- Tap on a table to select it
- Optionally join tables by selecting multiple tables
- Tap "Enter Table" to start taking orders

### 3. Take Orders

- Browse menu categories on the right panel
- Search for specific items
- Tap on menu items to add to customer orders
- Select which customer to add the item to

### 4. Manage Orders

- View order status with color-coded indicators
- Remove items from orders
- Monitor status counters in real-time

### 5. Generate Bill

- Tap "Bill" button to view complete bill
- Mark items for removal (shows strikethrough)
- Preview total with tax calculation
- Print PDF bill or finalize transaction

## Status Workflow

1. **Pending**: Newly added items
2. **Fire**: Drinks and quick items (immediate preparation)
3. **Hold**: Main course items (preparation on hold)
4. **Served**: Completed items

## Technical Features

- **Responsive Design**: Adapts to different screen sizes
- **Dark Theme**: Modern dark UI with gradient backgrounds
- **Real-time Updates**: Live status counters and order updates
- **Drag & Drop**: Intuitive item management
- **PDF Generation**: Professional bill printing
- **State Persistence**: Maintains state across navigation

## Customization

The system is designed to be easily customizable:

- Menu items can be modified in `pos_provider.dart`
- Table layout can be adjusted in `floor_layout_screen.dart`
- UI themes can be customized in individual screen files
- Status workflow can be modified in the model files

## Future Enhancements

Potential improvements could include:

- Multi-language support
- Payment integration
- Inventory management
- Customer loyalty programs
- Analytics and reporting
- Kitchen display system integration

## Running the App

1. Ensure Flutter is installed and configured
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app
5. Use PIN `123456` to login and explore the system

This POS system provides a complete solution for restaurant order management with a modern, intuitive interface and comprehensive functionality.
