# Restaurant POS System

A complete Point of Sale (POS) system for restaurants built with Flutter. This application provides a comprehensive solution for managing restaurant operations including order taking, kitchen management, and payment processing.

## 📋 Features Included

✅ **Complete POS System** with all screens
✅ **5 Different Color Themes** (Red/Yellow, Blue/Teal, Purple/Pink, Green/Lime, Dark)
✅ **Settings Screen** accessible from every screen
✅ **Real-time Theme Switching**
✅ **Order Management** with status tracking
✅ **Kitchen Status Screen** with print and payment options
✅ **Responsive Design**
✅ **Clean Architecture** with proper separation of concerns

## 📁 Project Structure

```
restaurant_pos2/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── floor.dart
│   │   ├── table.dart
│   │   ├── category.dart
│   │   ├── menu_item.dart
│   │   ├── order_item.dart
│   │   └── order_status.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── user_list_screen.dart
│   │   ├── pin_screen.dart
│   │   ├── floor_selection_screen.dart
│   │   ├── table_selection_screen.dart
│   │   ├── pos_screen.dart
│   │   ├── kitchen_status_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/
│   │   └── status_count_widget.dart
│   └── themes/
│       └── app_themes.dart
├── pubspec.yaml
├── assets/
│   └── images/
└── README.md
```

## 🚀 Getting Started

### Prerequisites

Before running this project, make sure you have the following installed:

- **Flutter SDK** (3.0.0 or higher)
- **Chrome Browser** (for web development)
- **Dart SDK** (comes with Flutter)
- **Git** (optional, for version control)

### Installation

1. **Clone or download this project**

   ```bash
   cd restaurant_pos2
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```

### Running the Application in Chrome

To run the application in Chrome browser:

```bash
flutter run -d chrome
```

Or simply use:

```bash
flutter run
```

Then select `Chrome` from the available devices list.

### Running in Release Mode

For better performance:

```bash
flutter run -d chrome --release
```

## 📱 Application Flow

1. **Login Screen**: Enter credentials (any email/password will work for demo)
2. **User Selection**: Choose a waiter/user from the list
3. **PIN Entry**: Enter a 4-digit PIN (any 4 digits will work for demo)
4. **Floor Selection**: Choose the restaurant floor
5. **Table Selection**: Select a table
6. **POS Screen**:
   - Add items to the order
   - View cart and totals
   - Send order to kitchen
7. **Kitchen Status**: View and manage order statuses
   - Hold
   - In Kitchen
   - Served
8. **Settings**: Change theme anytime from the settings icon

## 🎨 Available Themes

- **Red & Yellow Theme**: Classic restaurant theme
- **Blue & Teal Theme**: Modern and clean
- **Purple & Pink Theme**: Elegant and vibrant
- **Green & Lime Theme**: Fresh and natural
- **Dark Theme**: Easy on the eyes

## 🛠️ Technologies Used

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Material Design**: UI components
- **Chrome**: Web platform for testing

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
```

## 🧪 Testing

Run the test suite:

```bash
flutter test
```

## 🚢 Building for Web

Build the web application:

```bash
flutter build web
```

The built files will be in the `build/web` directory.

## 📝 Configuration

The application uses minimal configuration. All data is currently hardcoded for demonstration purposes. You can modify:

- **Menu items** in `lib/screens/pos_screen.dart`
- **Users** in `lib/screens/user_list_screen.dart`
- **Floors** in `lib/screens/floor_selection_screen.dart`
- **Tables** in `lib/screens/table_selection_screen.dart`
- **Themes** in `lib/themes/app_themes.dart`

## 🤝 Contributing

This is a demo project. Feel free to fork and modify as needed for your restaurant.

## 📄 License

This project is for demonstration purposes.

## 🐛 Troubleshooting

### Chrome not launching

If Chrome doesn't launch:

```bash
flutter doctor -v
```

Make sure Chrome is properly configured.

### Build errors

If you encounter build errors:

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Web not enabled

If web support is not enabled:

```bash
flutter config --enable-web
flutter create .
```

## 📞 Support

For issues or questions, please check:

- Flutter documentation: https://flutter.dev/docs
- Dart documentation: https://dart.dev/guides

## 🎯 Future Enhancements

Potential improvements:

- Backend integration with Firebase or REST API
- Real-time database updates
- Print receipt functionality
- Payment gateway integration
- Inventory management
- Reports and analytics
- Multi-language support

---

**Note**: This is a demonstration project. In a production environment, you would need to integrate with a real backend, implement proper authentication, add database storage, and configure actual payment processing.
