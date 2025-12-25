# Restaurant POS System API

A comprehensive Point of Sale (POS) system built with Laravel 12, designed for restaurant management with features including order management, table management, employee management, menu management, and payment processing.

## 🚀 Features

### Core Functionality

-   **Business Management**: Multi-business support with timezone and configuration settings
-   **Employee Management**: Role-based access control with PIN authentication
-   **Table Management**: Floor layout with table status tracking
-   **Order Management**: Complete order lifecycle from creation to payment
-   **Menu Management**: Categories, items, modifiers, and pricing
-   **Payment Processing**: Multiple payment methods with tip tracking
-   **Kitchen Integration**: Kitchen ticket generation and status tracking
-   **Reservation System**: Table reservation management
-   **Reporting**: Sales and employee performance reports

### Technical Features

-   RESTful API design
-   UUID primary keys for all entities
-   Comprehensive validation
-   Eloquent relationships
-   Database migrations
-   Role-based permissions
-   Multi-tenant architecture

## 📋 Requirements

-   PHP 8.2+
-   Laravel 12.0+
-   MySQL/PostgreSQL/SQLite
-   Composer
-   Node.js (for frontend assets)

## 🛠️ Installation

1. **Clone the repository**

    ```bash
    git clone <repository-url>
    cd myproject
    ```

2. **Install dependencies**

    ```bash
    composer install
    npm install
    ```

3. **Environment setup**

    ```bash
    cp .env.example .env
    php artisan key:generate
    ```

4. **Database configuration**
   Update your `.env` file with database credentials:

    ```env
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=restaurant_pos
    DB_USERNAME=your_username
    DB_PASSWORD=your_password
    ```

5. **Run migrations**

    ```bash
    php artisan migrate
    ```

6. **Seed the database (optional)**

    ```bash
    php artisan db:seed
    ```

7. **Start the development server**
    ```bash
    php artisan serve
    ```

## 🗄️ Database Schema

### Core Entities

#### Business

-   Multi-tenant business management
-   Timezone and configuration settings
-   Auto-gratuity and credit card fee settings

#### Employee

-   Employee management with PIN authentication
-   Role-based access control
-   Shift tracking

#### Floor & Tables

-   Floor layout management
-   Table status tracking (available, occupied, reserved, out_of_order)
-   Capacity and shape management

#### Menu System

-   Hierarchical menu categories organized under menus (e.g., dine-in, takeaway)
-   Menu items with cash/card pricing
-   Modifier groups and modifiers
-   Printer route assignments

#### Order Management

-   Order creation and management
-   Check splitting functionality
-   Order item tracking with modifiers
-   Kitchen ticket generation

#### Payment System

-   Multiple payment methods
-   Tip tracking
-   Payment status management

## 🔌 API Endpoints

### Business Management

-   `GET /api/businesses` - List all businesses
-   `POST /api/businesses` - Create new business
-   `GET /api/businesses/{id}` - Get business details
-   `PUT /api/businesses/{id}` - Update business
-   `DELETE /api/businesses/{id}` - Delete business

### Employee Management

-   `GET /api/employees` - List employees
-   `POST /api/employees` - Create employee
-   `GET /api/employees/{id}` - Get employee details
-   `PUT /api/employees/{id}` - Update employee
-   `DELETE /api/employees/{id}` - Delete employee
-   `POST /api/employees/{id}/assign-roles` - Assign roles to employee

### Table Management

-   `GET /api/tables` - List tables
-   `POST /api/tables` - Create table
-   `GET /api/tables/{id}` - Get table details
-   `PUT /api/tables/{id}` - Update table
-   `DELETE /api/tables/{id}` - Delete table
-   `GET /api/tables/status/summary` - Get table status summary

### Order Management

-   `GET /api/orders` - List orders
-   `POST /api/orders` - Create order
-   `GET /api/orders/{id}` - Get order details
-   `PUT /api/orders/{id}` - Update order
-   `DELETE /api/orders/{id}` - Delete order
-   `POST /api/orders/{id}/add-item` - Add item to order

### Menu Management

-   `GET /api/menu-items` - List menu items
-   `POST /api/menu-items` - Create menu item
-   `GET /api/menu-items/{id}` - Get menu item details
-   `PUT /api/menu-items/{id}` - Update menu item
-   `DELETE /api/menu-items/{id}` - Delete menu item
-   `POST /api/menu-items/{id}/attach-modifier-groups` - Attach modifier groups

### Payment Processing

-   `GET /api/payments` - List payments
-   `POST /api/payments` - Process payment
-   `GET /api/payments/{id}` - Get payment details
-   `PUT /api/payments/{id}` - Update payment
-   `DELETE /api/payments/{id}` - Delete payment
-   `GET /api/checks/{id}/payment-summary` - Get payment summary for check

## 📊 Data Models

### Business Model

```php
class Business extends Model
{
    protected $fillable = [
        'name', 'llc_name', 'address', 'logo_url', 'timezone',
        'auto_gratuity_percent', 'auto_gratuity_min_guests', 'cc_fee_percent'
    ];
}
```

### Employee Model

```php
class Employee extends Model
{
    protected $fillable = [
        'business_id', 'first_name', 'last_name', 'email', 'pin4', 'image', 'is_active'
    ];
}
```

### Order Model

```php
class Order extends Model
{
    protected $fillable = [
        'table_id', 'created_by_employee_id', 'status', 'notes'
    ];
}
```

## 🔐 Authentication & Authorization

The system uses role-based access control:

### Roles

-   **Manager**: Full system access
-   **Server**: Order management, table management
-   **Kitchen**: Kitchen ticket management
-   **Host**: Reservation management

### Permissions

-   `orders.create` - Create orders
-   `orders.update` - Update orders
-   `orders.delete` - Delete orders
-   `payments.process` - Process payments
-   `employees.manage` - Manage employees
-   `reports.view` - View reports

## 🧪 Testing

Run the test suite:

```bash
php artisan test
```

## 📈 Performance Considerations

-   Database indexes on frequently queried fields
-   Eager loading for relationships
-   Pagination for large datasets
-   Caching for frequently accessed data

## 🔧 Configuration

### Environment Variables

```env
APP_NAME="Restaurant POS"
APP_ENV=local
APP_KEY=base64:...
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=restaurant_pos
DB_USERNAME=root
DB_PASSWORD=

CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
```

## 📝 API Documentation

For detailed API documentation, see [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:

-   Create an issue in the repository
-   Contact the development team
-   Check the documentation

## 🔄 Changelog

### Version 1.0.0

-   Initial release
-   Core POS functionality
-   API endpoints
-   Database schema
-   Basic authentication

---

**Built with ❤️ using Laravel 12**
