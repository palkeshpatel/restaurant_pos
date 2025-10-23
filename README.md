# Restaurant POS System

A comprehensive Point of Sale (POS) system built with Flutter for restaurant management.

## Features

- 🔐 **6-digit PIN Authentication** - Secure login system
- 🍽️ **Restaurant Floor Layout** - Visual table management with cartoon-style design
- 🔗 **Table Joining** - Connect tables for larger groups with canvas visualization
- 📱 **Modern POS Interface** - Intuitive order management system
- 🔥 **Fire/Hold Status System** - Smart item status tracking for kitchen workflow
- 📊 **Real-time Status Counters** - Live tracking of item preparation status
- 🧾 **Bill Management** - Complete billing system with PDF generation
- 🖨️ **Print Functionality** - Generate and print professional bills

## Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd restaurant_pos
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**

   ```bash
   flutter run
   ```

4. **Login with demo PIN**
   - Use PIN: `123456` to access the system

## Usage

### 1. Authentication

- Enter 6-digit PIN using the number pad
- Demo PIN: `123456`

### 2. Table Selection

- View restaurant floor layout
- Tap tables to select them
- Join tables by selecting multiple tables
- Tap "Enter Table" to start taking orders

### 3. Order Management

- Browse menu categories
- Add items to customer orders
- Monitor item status (Fire/Hold/Served)
- View real-time status counters

### 4. Bill Generation

- Preview complete bill
- Mark items for removal
- Print PDF bills
- Finalize transactions

## Status System

- **🔥 Fire**: Drinks, soda, tea (immediate preparation)
- **⏸️ Hold**: Main course items (preparation on hold)
- **✅ Served**: Completed items
- **⏳ Pending**: Newly added items

## Technical Stack

- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **PDF**: Document generation
- **Printing**: PDF printing functionality

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── providers/                # State management
└── screens/                  # UI screens
```

## Dependencies

- `provider: ^6.1.1` - State management
- `shared_preferences: ^2.2.2` - Local storage
- `printing: ^5.12.0` - PDF printing
- `pdf: ^3.10.7` - PDF generation

## Customization

The system is designed to be easily customizable:

- Modify menu items in `pos_provider.dart`
- Adjust table layout in `floor_layout_screen.dart`
- Customize UI themes in individual screen files

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.
