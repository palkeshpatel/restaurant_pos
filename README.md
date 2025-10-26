# Restaurant POS System

A professional Point of Sale system designed for restaurants with multi-user support and role-based access control.

## Features

- **Multi-User Authentication**: Support for managers, waiters, and owners
- **Role-Based Access**: Different permissions based on user roles
- **PIN Security**: 4-digit PIN authentication for enhanced security
- **Professional UI**: Modern, restaurant-themed interface
- **Menu Management**: Categorized menu items with easy ordering
- **Order Cart**: Real-time cart management with pricing
- **Responsive Design**: Works across different screen sizes

## Screens

1. **Splash Screen**: Professional loading screen with restaurant branding
2. **Restaurant Login**: Enter restaurant code to access the system
3. **User Selection**: Choose from available staff members with role indicators
4. **PIN Authentication**: Secure 4-digit PIN entry
5. **POS System**: Full-featured point of sale interface with menu and cart

## User Roles

- **Manager (MGR)**: Full system access and management capabilities
- **Owner (OWN)**: Complete restaurant management and oversight
- **Waiter (WTR)**: Order taking and customer service functions

## Getting Started

1. **Install Dependencies**

   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

## How to Use

1. **Splash Screen**: App loads with restaurant branding (3 seconds)
2. **Restaurant Login**: Enter any 6-digit restaurant code
3. **User Selection**: Choose from 5 available staff members:
   - John Smith (Manager)
   - Sarah Johnson (Waiter)
   - Mike Wilson (Waiter)
   - Emily Davis (Waiter)
   - David Brown (Owner)
4. **PIN Authentication**: Enter PIN "1234" to login
5. **POS System**: Full restaurant interface with:
   - Category sidebar (Pizza, Burgers, Drinks, Desserts)
   - Menu items grid with prices
   - Shopping cart with quantity controls
   - Checkout functionality

## Dependencies

- `flutter`: Flutter SDK
- `cupertino_icons`: iOS style icons

## Project Structure

```
lib/
├── main.dart                 # Main application with all screens
assets/
├── images/                   # Restaurant images and logos
└── icons/                    # App icons and UI elements
```

## Security Features

- Restaurant code verification
- User role validation
- 4-digit PIN authentication
- Session management
- Secure logout functionality

## Customization

The system is designed to be easily customizable:

- **Colors**: Update the primary color scheme in `main.dart`
- **Menu Items**: Add your restaurant's actual menu items
- **User Management**: Integrate with your staff database
- **Branding**: Add your restaurant logo and branding

## Development

- **Hot Reload**: Make changes and see them instantly
- **Multi-Platform**: Works on Android, iOS, Web, Windows, macOS, Linux
- **Material Design**: Follows Google's Material Design guidelines

## License

This project is licensed under the MIT License.
