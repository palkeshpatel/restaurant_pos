<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::prefix('auth')->group(function () {
    Route::post('login', [\App\Http\Controllers\Api\AuthController::class, 'login']);

    Route::middleware('auth.token')->group(function () {
        Route::post('logout', [\App\Http\Controllers\Api\AuthController::class, 'logout']);
        Route::get('me', [\App\Http\Controllers\Api\AuthController::class, 'me']);
    });
});

// ============================================================================
// ADMIN API ROUTES - Base Prefix: /api/admin/
// ============================================================================

Route::middleware('auth.token')->prefix('admin')->group(function () {

    // Dashboard Routes
    Route::get('dashboard/counts', [\App\Http\Controllers\Api\Admin\DashboardController::class, 'getCounts']);

    // Employee Routes
    Route::apiResource('employees', \App\Http\Controllers\Api\Admin\EmployeeController::class);
    Route::post('employees/{id}/avatar', [\App\Http\Controllers\Api\Admin\EmployeeController::class, 'uploadAvatar']);
    Route::post('employees/{employee}/assign-roles', [\App\Http\Controllers\Api\Admin\EmployeeController::class, 'assignRoles']);

    // Role Routes
    Route::apiResource('roles', \App\Http\Controllers\Api\Admin\RoleController::class);
    Route::post('roles/{role}/assign-permissions', [\App\Http\Controllers\Api\Admin\RoleController::class, 'assignPermissions']);

    // Permission Routes
    Route::apiResource('permissions', \App\Http\Controllers\Api\Admin\PermissionController::class);

    // Discount Reasons Routes
    Route::apiResource('discount-reasons', \App\Http\Controllers\Api\Admin\DiscountReasonController::class);

    // Floor Routes
    Route::apiResource('floors', \App\Http\Controllers\Api\Admin\FloorController::class);
    Route::post('floors/{id}/background', [\App\Http\Controllers\Api\Admin\FloorController::class, 'uploadBackground']);
    Route::get('floors/{id}/background-image', [\App\Http\Controllers\Api\Admin\FloorController::class, 'getBackgroundImage']);
    Route::delete('floors/{id}/background-image', [\App\Http\Controllers\Api\Admin\FloorController::class, 'deleteBackground']);

    // Table Routes
    Route::apiResource('tables', \App\Http\Controllers\Api\Admin\TableController::class);

    // Menu Routes
    Route::apiResource('menus', \App\Http\Controllers\Api\Admin\MenuController::class);

    // Menu Category Routes
    Route::apiResource('menu-categories', \App\Http\Controllers\Api\Admin\MenuCategoryController::class);

    // Menu Type Routes
    Route::apiResource('menu-types', \App\Http\Controllers\Api\Admin\MenuTypeController::class);
    Route::post('menu-types/{id}/update-auto-fire', [\App\Http\Controllers\Api\Admin\MenuTypeController::class, 'updateAutoFire']);

    // Menu Item Routes
    Route::apiResource('menu-items', \App\Http\Controllers\Api\Admin\MenuItemController::class);
    Route::post('menu-items/{menuItem}/attach-modifier-groups', [\App\Http\Controllers\Api\Admin\MenuItemController::class, 'attachModifierGroups']);
    Route::post('menu-items/{menuItem}/attach-decision-groups', [\App\Http\Controllers\Api\Admin\MenuItemController::class, 'attachDecisionGroups']);

    // Modifier Group Routes
    Route::apiResource('modifier-groups', \App\Http\Controllers\Api\Admin\ModifierGroupController::class);

    // Modifier Routes
    Route::apiResource('modifiers', \App\Http\Controllers\Api\Admin\ModifierController::class);

    // Decision Group Routes
    Route::apiResource('decision-groups', \App\Http\Controllers\Api\Admin\DecisionGroupController::class);

    // Decision Routes
    Route::apiResource('decisions', \App\Http\Controllers\Api\Admin\DecisionController::class);

    // Tax Routes (only add/edit, no list/delete)
    Route::post('taxes', [\App\Http\Controllers\Api\Admin\TaxRateController::class, 'store']);
    Route::put('taxes/{id}', [\App\Http\Controllers\Api\Admin\TaxRateController::class, 'update']);

    // Printer Routes
    Route::apiResource('printers', \App\Http\Controllers\Api\Admin\PrinterController::class);

    // Printer Route Routes
    Route::apiResource('printer-routes', \App\Http\Controllers\Api\Admin\PrinterRouteController::class);

    // Shift Routes
    Route::apiResource('shifts', \App\Http\Controllers\Api\Admin\ShiftController::class);

    // Reservation Routes
    Route::apiResource('reservations', \App\Http\Controllers\Api\Admin\ReservationController::class);

    // Order Routes
    Route::apiResource('orders', \App\Http\Controllers\Api\Admin\OrderController::class);

    // Check Routes
    Route::apiResource('checks', \App\Http\Controllers\Api\Admin\CheckController::class);

    // Payment Routes
    Route::apiResource('payments', \App\Http\Controllers\Api\Admin\PaymentController::class);

    // Kitchen Ticket Routes
    Route::apiResource('kitchen-tickets', \App\Http\Controllers\Api\Admin\KitchenTicketController::class);

    // Order Item Routes
    Route::apiResource('order-items', \App\Http\Controllers\Api\Admin\OrderItemController::class);

    // Gratuity Setting Routes
    Route::apiResource('gratuity-setting', \App\Http\Controllers\Api\Admin\GratuitySettingController::class);
    Route::get('gratuity-setting/business/{business_id}', [\App\Http\Controllers\Api\Admin\GratuitySettingController::class, 'getByBusiness']);

    // Fee Routes
    Route::get('fees', [\App\Http\Controllers\Api\Admin\FeeController::class, 'show']);
    Route::post('fees', [\App\Http\Controllers\Api\Admin\FeeController::class, 'store']);
    Route::put('fees/{id}', [\App\Http\Controllers\Api\Admin\FeeController::class, 'update']);

    // Settings Routes - Get/Update all config values at once
    Route::get('settings/config', [\App\Http\Controllers\Api\Admin\SettingsController::class, 'getConfig']);
    Route::put('settings/config', [\App\Http\Controllers\Api\Admin\SettingsController::class, 'updateConfig']);

    // Menu Management Routes - Dedicated endpoints for pad view
    Route::get('menu-management/pad-data', [\App\Http\Controllers\Api\Admin\MenuManagementController::class, 'getMenuPadData']);
    Route::post('menu-management/category/{id}/toggle-status', [\App\Http\Controllers\Api\Admin\MenuManagementController::class, 'toggleCategoryStatus']);
    Route::post('menu-management/item/{id}/toggle-status', [\App\Http\Controllers\Api\Admin\MenuManagementController::class, 'toggleMenuItemStatus']);

    // Report Routes
    Route::get('reports/daily-summary', [\App\Http\Controllers\Api\Admin\ReportController::class, 'dailySummary']);
    Route::get('reports/order-agent-activity', [\App\Http\Controllers\Api\Admin\OrderAgentActivityController::class, 'summary']);
});

Route::middleware(['auth.token', 'superadmin'])->prefix('super-admin')->group(function () {
    Route::apiResource('businesses', \App\Http\Controllers\Api\SuperAdmin\BusinessController::class);
    Route::apiResource('users', \App\Http\Controllers\Api\SuperAdmin\UserController::class);
});

// ============================================================================
// POS API ROUTES - Base Prefix: /api/pos/
// ============================================================================

Route::prefix('pos')->group(function () {
    // Step 1 - Get Business with Employees
    Route::get('get-business/{id}', [\App\Http\Controllers\Api\Pos\PosController::class, 'getBusiness']);

    // Step 2 - Verify Employee PIN
    Route::post('verify-pin', [\App\Http\Controllers\Api\Pos\PosController::class, 'verifyPin']);

    // Get Configuration Data - Public endpoint (no authentication required)
    Route::get('get-config-data', [\App\Http\Controllers\Api\Pos\PosController::class, 'getConfigData']);

    Route::middleware('auth.employee')->group(function () {
        // Step 2 - Change Password (PIN)
        Route::post('change-password', [\App\Http\Controllers\Api\Pos\PosController::class, 'changePassword']);
        Route::post('logout', [\App\Http\Controllers\Api\Pos\PosController::class, 'logout']);
        // Step 3 - Get Tables
        Route::get('get-tables', [\App\Http\Controllers\Api\Pos\PosController::class, 'getTables']);
        // Step 3 - Get Floors
        Route::get('get-floors', [\App\Http\Controllers\Api\Pos\PosController::class, 'getFloors']);

        // Step 4 - Get Menu
        Route::get('menu', [\App\Http\Controllers\Api\Pos\PosController::class, 'getMenu']);

        // Step 5 - Reserve Table (Create New Order)
        Route::post('reserve_table', [\App\Http\Controllers\Api\Pos\PosController::class, 'orderProcess']);

        // Step 5 - Cancel Reservation (Remove Order and Set Table Available)
        Route::post('cancel_reservation', [\App\Http\Controllers\Api\Pos\PosController::class, 'cancelReservation']);

        // Step 5 - Resume Order (Access Existing Order)
        Route::post('resume_order', [\App\Http\Controllers\Api\Pos\PosController::class, 'resumeOrder']);

        // Step 5 - Change Table
        Route::post('change_table', [\App\Http\Controllers\Api\Pos\PosController::class, 'changeTable']);

        // Step 5 - Replace Table
        Route::post('replace_table', [\App\Http\Controllers\Api\Pos\PosController::class, 'replaceTable']);

        // Step 5 - Merge Tables
        Route::post('merge_tables', [\App\Http\Controllers\Api\Pos\PosController::class, 'mergeTables']);

        // Send to Kitchen
        Route::post('send-to-kitchen', [\App\Http\Controllers\Api\Pos\PosController::class, 'sendToKitchen']);

        // Update Order Item Status - Update order_status (0=HOLD, 1=FIRE, 2=TEMP, 3=VOID)
        Route::post('order_item_status', [\App\Http\Controllers\Api\Pos\PosController::class, 'orderItemStatus']);

        // Void Order Items - Void items with undo functionality
        Route::post('order_item_void', [\App\Http\Controllers\Api\Pos\PosController::class, 'orderItemVoid']);

        // Apply/Remove Discount on Order Items
        Route::post('order_item_discount', [\App\Http\Controllers\Api\Pos\PosController::class, 'orderItemDiscount']);

        // Remove Order Item - Remove order items with TEMP status (order_status = 2)
        Route::post('order_item_removed', [\App\Http\Controllers\Api\Pos\PosController::class, 'orderItemRemoved']);

        // Update Order Item Sequence
        Route::post('order-item/update-sequence', [\App\Http\Controllers\Api\Pos\PosController::class, 'updateItemSequence']);

        // Payment
        Route::get('order/payment-history', [\App\Http\Controllers\Api\Pos\PosController::class, 'getPaymentHistory']);
        Route::get('order/bill-preview', [\App\Http\Controllers\Api\Pos\PosController::class, 'getOrderBillPreview']);
        Route::post('order/refund', [\App\Http\Controllers\Api\Pos\PosController::class, 'processRefund']);

        // Step 7 - Get Active Orders and Search Order
        Route::get('get-active-orders', [\App\Http\Controllers\Api\Pos\PosController::class, 'getActiveOrders']);
        Route::get('search-order', [\App\Http\Controllers\Api\Pos\PosController::class, 'searchOrder']);
        Route::post('order/payment', [\App\Http\Controllers\Api\Pos\PosController::class, 'processPayment']);
        Route::post('order/complete', [\App\Http\Controllers\Api\Pos\PosController::class, 'completeOrder']);

        // Stripe Tap Payment
        Route::post('stripe/create-payment-intent', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'createPaymentIntent']);
        Route::post('stripe/confirm-payment', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'confirmPayment']);
        Route::post('stripe/check-status', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'checkPaymentStatus']);
        Route::post('stripe/create-connection-token', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'createConnectionToken']);

        // Stripe Test Payment (with card number)
        Route::post('stripe/test-payment', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'testCreatePaymentIntent']);

        // Table Release
        Route::post('table/release', [\App\Http\Controllers\Api\Pos\PosController::class, 'releaseTable']);

        // Reports
        Route::get('reports/x-report', [\App\Http\Controllers\Api\Pos\ReportController::class, 'generateXReport']);
        Route::get('reports/z-report', [\App\Http\Controllers\Api\Pos\ReportController::class, 'generateZReport']);

        // End of Day
        Route::get('end-of-date', [\App\Http\Controllers\Api\Pos\PosController::class, 'getEndOfDate']);
        Route::post('make-end-of-date', [\App\Http\Controllers\Api\Pos\PosController::class, 'makeEndOfDate']);

        // Utility Endpoints
        Route::get('orders/open', [\App\Http\Controllers\Api\Pos\PosController::class, 'getOpenOrders']);
        Route::get('orders/history', [\App\Http\Controllers\Api\Pos\PosController::class, 'getOrderHistory']);
        Route::get('modifiers', [\App\Http\Controllers\Api\Pos\PosController::class, 'getModifiers']);
    });
});

// ============================================================================
// DEMO API ROUTES - Base Prefix: /api/stripe-demo/ (No Authentication Required)
// ============================================================================

Route::prefix('stripe-demo')->group(function () {
    Route::post('create-payment-intent', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'demoCreatePaymentIntent']);
    Route::post('check-status', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'demoCheckPaymentStatus']);
    Route::post('test-payment', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'demoTestPayment']);
    Route::post('refund-payment', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'demoRefundPayment']);
    Route::post('create-connection-token', [\App\Http\Controllers\Api\Pos\StripePaymentController::class, 'createConnectionToken']);
});
