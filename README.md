# Gourmet Restaurant POS System

A comprehensive, modern Point of Sale (POS) system built with Flutter featuring a beautiful dark theme, splash screen, and mobile app-style animations for professional restaurant management.

## ✨ Features

### 🎨 **Modern Dark UI**

- **Splash Screen** with restaurant branding and smooth animations
- **Dark Theme** throughout the entire application with beautiful gradients
- **Background Patterns** with restaurant-themed decorative elements
- **Professional Typography** using Poppins font family
- **Mobile App-style Animations** with fade, slide, and scale effects

### 🔐 **Enhanced Authentication**

- **6-digit PIN Authentication** with visual feedback and animations
- **Animated Number Pad** with press effects and color transitions
- **Error Handling** with styled error messages and icons

### 🍽️ **Visual Floor Management**

- **Interactive Table Layout** with responsive design for mobile and desktop
- **Background Patterns** showing table and chair arrangements
- **Smooth Animations** for table selection and joining
- **Status Indicators** with color-coded table states

### 📱 **Modern POS Interface**

- **Responsive Layout** adapting to all screen sizes
- **Drag & Drop** order management with visual feedback
- **Animated Cards** with press effects and hover states
- **Real-time Status Updates** with pulsing indicators

### 🔥 **Smart Kitchen System**

- **Kitchen-themed Backgrounds** with flame patterns
- **Animated Status Columns** with drag-and-drop functionality
- **Live Timers** with progress indicators
- **Priority Management** with visual ordering

### 🧾 **Professional Billing**

- **Clean Bill Design** with restaurant branding and simplified layout
- **App Bar Controls** with close and print buttons (no bottom clutter)
- **PDF Generation** with professional formatting
- **Responsive Layout** that works perfectly on all screen sizes

## 🚀 Quick Start

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Run the app**

   ```bash
   # For web (recommended)
   flutter run -d chrome --web-port=8080

   # For desktop
   flutter run -d windows

   # For mobile
   flutter run -d android
   ```

3. **✅ Status: FULLY WORKING**

   - ✅ APK builds successfully
   - ✅ Web version runs perfectly
   - ✅ All compilation errors resolved
   - ✅ Clean, responsive design

4. **✅ Working Features**

   - **Splash Screen**: Beautiful animated intro with "GOURMET" branding
   - **Dark Theme**: Professional dark UI throughout the entire app
   - **Background Patterns**: Context-aware patterns for each screen
   - **Mobile Animations**: Smooth transitions and interactive effects
   - **Responsive Design**: Perfect on mobile, tablet, and desktop
   - **Clean Bill Screen**: Simplified design with app bar controls

5. **🔐 Login**
   - Use PIN: `123456` to access the system
   - Enhanced login screen with animated number pad and beautiful gradients

## 🎯 What You'll See

### 🌟 **Splash Screen**

- **Animated Logo**: Rotating restaurant icon with scaling effects
- **"GOURMET" Branding**: Professional typography with letter spacing
- **Loading Animation**: Smooth progress indicator
- **Background Pattern**: Geometric patterns with floating elements

### 🌙 **Dark Theme Experience**

- **Gradient Backgrounds**: Multi-layered dark gradients throughout
- **Context Patterns**: Different background patterns for each screen:
  - **Restaurant Screen**: Food and dining themed patterns 🍽️
  - **Kitchen Screen**: Flame and cooking themed patterns 🔥
  - **Table Layout**: Table and chair arrangement patterns 🪑
  - **Bill Screen**: Professional document-style backgrounds 📄

### 📱 **Mobile App Features**

- **Button Animations**: Scale effects on press with color transitions
- **Card Interactions**: Hover effects and smooth transitions
- **Status Indicators**: Pulsing animations for live updates
- **Responsive Design**: Seamless experience across all screen sizes

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
├── main.dart                 # App entry point with enhanced theming
├── models/                   # Data models (MenuItem, TableModel, etc.)
├── providers/                # State management (POS & Settings providers)
├── screens/                  # UI screens with enhanced animations
│   ├── splash_screen.dart    # ✨ NEW: Animated splash screen
│   ├── login_screen.dart     # Enhanced login with animations
│   ├── floor_layout_screen.dart # Visual table layout with patterns
│   ├── pos_screen.dart       # Modern POS interface
│   ├── kitchen_screen.dart   # Kitchen management with backgrounds
│   └── bill_screen.dart      # Professional billing system
└── widgets/                  # ✨ NEW: Custom widgets and animations
    ├── background_painter.dart # Custom background patterns
    └── animations.dart         # Animation utilities
```

### 📁 Assets Structure

```
assets/
├── images/                   # Background images and patterns
├── animations/               # Lottie animation files
├── icons/                    # Custom icons
└── fonts/                    # Poppins font family
```

## Dependencies

### Core Dependencies

- `provider: ^6.1.1` - State management
- `shared_preferences: ^2.2.2` - Local storage for settings

### UI & Animation

- `animate_do: ^3.3.4` - Beautiful animations and transitions
- `lottie: ^3.1.0` - Lottie animation support
- `cached_network_image: ^3.3.0` - Image caching and optimization

### Document Generation

- `printing: ^5.12.0` - PDF printing functionality
- `pdf: ^3.10.7` - PDF document generation

### 🎨 **Note on Current Implementation**

- **Custom Fonts**: Currently using system fonts (Poppins fonts commented out for compatibility)
- **Background Images**: Using procedural patterns instead of static images for better performance
- **Animation Files**: Custom Lottie animations included for enhanced user experience
- **Responsive Design**: Fully responsive across mobile, tablet, and desktop platforms

## 🎨 Visual Enhancements

### Dark Theme System

- **Enhanced Gradients**: Multi-layered background gradients throughout the app
- **Custom Color Palette**: Restaurant-themed colors (red, orange, green, blue)
- **Background Patterns**: Context-aware patterns for each screen
- **Professional Typography**: Poppins font family for modern look

### Animation System

- **Splash Screen Animations**: Logo rotation, scaling, and fade effects
- **Button Press Effects**: Scale animations and color transitions
- **Card Hover Effects**: Interactive feedback on user interactions
- **Status Indicators**: Pulsing animations for live status updates

### Background Patterns

- **Restaurant Screen**: Food and dining themed patterns with utensils
- **Kitchen Screen**: Flame and cooking themed patterns
- **Table Layout**: Table and chair arrangement patterns
- **Bill Screen**: Professional document-style backgrounds

## Customization

The system is designed to be easily customizable:

### Adding New Features

- **Menu Items**: Modify `pos_provider.dart` to add new menu categories
- **Table Layout**: Adjust table positions in `floor_layout_screen.dart`
- **Background Patterns**: Create new patterns in `background_painter.dart`
- **Animations**: Add new effects using the `animations.dart` utilities

### Theme Customization

- **Colors**: Modify colors in `settings_provider.dart`
- **Gradients**: Update gradient definitions in the theme
- **Typography**: Adjust font families and sizes in `main.dart`
- **Background Images**: Add new patterns to the assets folder

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.
