<?php

namespace App\Http\Controllers\Api\Pos;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Employee;
use App\Models\Floor;
use App\Models\Order;
use App\Models\RestaurantTable;
use App\Models\Check;
use App\Models\Payment;
use App\Models\OrderItem;
use App\Models\OrderCancel;
use App\Models\VoidItem;
use App\Models\Menu;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\ModifierGroup;
use App\Models\Modifier;
use App\Models\Decision;
use App\Models\DecisionGroup;
use App\Models\KitchenTicket;
use App\Models\GratuitySetting;
use App\Models\PaymentHistory;
use App\Models\TaxRate;
use App\Models\Fee;
use App\Models\EndOfDay;
use App\Models\OrderAccessLog;
use App\Services\ReportService;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Barryvdh\DomPDF\Facade\Pdf;

/**
 * @OA\Info(
 *     title="Restaurant POS System API",
 *     version="2.0.0",
 *     description="Real-time operational flow for waiters and order processing.",
 *     @OA\Contact(
 *         email="support@restaurantpos.com"
 *     )
 * )
 *
 * @OA\Server(
 *     url=L5_SWAGGER_CONST_HOST,
 *     description="API Server"
 * )
 *
 * @OA\SecurityScheme(
 *     securityScheme="bearerAuth",
 *     type="http",
 *     scheme="bearer",
 *     bearerFormat="Token"
 * )
 */
class PosController extends Controller
{
    use ApiResponse;

    /**
     * @OA\Get(
     *     path="/pos/get-business/{id}",
     *     tags={"POS API - Step 1"},
     *     summary="Get Business with Employees",
     *     description="Return business details along with its active employees for waiter selection",
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Business ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Business with active employees retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Restaurant Name"),
     *                 @OA\Property(property="employees", type="array", @OA\Items(
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="first_name", type="string", example="John"),
     *                     @OA\Property(property="last_name", type="string", example="Doe"),
     *                     @OA\Property(property="is_active", type="boolean", example=true),
     *                     @OA\Property(property="roles", type="array", @OA\Items(
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="name", type="string", example="Waiter"),
     *                         @OA\Property(property="business_id", type="integer", example=1)
     *                     ))
     *                 ))
     *             )
     *         )
     *     )
     * )
     */
    public function getBusiness($id)
    {
        $business = Business::with(['employees' => function ($query) {
            $query->where('is_active', true)->with('roles');
        }])->find($id);

        if (!$business) {
            return $this->notFoundResponse('Business not found');
        }

        return $this->successResponse($business, 'Business with active employees retrieved successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/verify-pin",
     *     tags={"POS API - Step 2"},
     *     summary="Verify Employee PIN",
     *     description="Validate waiter PIN before allowing access to POS system",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"employee_id", "pin4"},
     *             @OA\Property(property="employee_id", type="integer", example=1),
     *             @OA\Property(property="pin4", type="string", example="1234")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="PIN verified successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="employee", type="object"),
     *                 @OA\Property(property="verified", type="boolean", example=true),
     *                 @OA\Property(property="token", type="string", example="O10a2X..."),
     *                 @OA\Property(property="token_type", type="string", example="Bearer")
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Invalid PIN"),
     *     @OA\Response(response=403, description="Employee is not active")
     * )
     */
    public function verifyPin(Request $request)
    {
        $validated = $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'pin4' => 'required|string|size:4',
        ]);

        $employee = Employee::find($validated['employee_id']);

        if (!$employee) {
            return $this->notFoundResponse('Employee not found');
        }

        if ($employee->pin4 !== $validated['pin4']) {
            return $this->unauthorizedResponse('Invalid PIN');
        }

        if (!$employee->is_active) {
            return $this->forbiddenResponse('Employee is not active');
        }

        $plainToken = Str::random(64);
        $employee->forceFill([
            'api_token' => hash('sha256', $plainToken),
        ])->save();

        return $this->successResponse([
            'employee' => $employee->load('roles'),
            'verified' => true,
            'token' => $plainToken,
            'token_type' => 'Bearer',
        ], 'PIN verified successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/change-password",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 2"},
     *     summary="Change Employee Password (PIN)",
     *     description="Change the employee's 4-digit PIN password. Requires old PIN, new PIN, and confirmation.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"old_pin", "new_pin", "confirm_pin"},
     *             @OA\Property(property="old_pin", type="string", example="1234", description="Current 4-digit PIN"),
     *             @OA\Property(property="new_pin", type="string", example="5678", description="New 4-digit PIN"),
     *             @OA\Property(property="confirm_pin", type="string", example="5678", description="Confirm new 4-digit PIN")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Password changed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Password changed successfully")
     *         )
     *     ),
     *     @OA\Response(response=400, description="Validation error or PINs do not match"),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=404, description="Invalid old PIN")
     * )
     */
    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'old_pin' => 'required|string|size:4',
            'new_pin' => 'required|string|size:4',
            'confirm_pin' => 'required|string|size:4',
        ]);

        // Get authenticated employee
        $employee = $request->user();

        if (!$employee) {
            return $this->unauthorizedResponse('Unauthorized');
        }

        // Verify old PIN
        if ($employee->pin4 !== $validated['old_pin']) {
            return $this->notFoundResponse('Invalid old PIN');
        }

        // Check if new PIN and confirm PIN match
        if ($validated['new_pin'] !== $validated['confirm_pin']) {
            return $this->errorResponse('New PIN and confirm PIN do not match', 400);
        }

        // Check if new PIN is different from old PIN
        if ($validated['old_pin'] === $validated['new_pin']) {
            return $this->errorResponse('New PIN must be different from old PIN', 400);
        }

        // Update the PIN
        $employee->forceFill([
            'pin4' => $validated['new_pin'],
        ])->save();

        return $this->successResponse(null, 'Password changed successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/logout",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 2"},
     *     summary="POS Employee Logout",
     *     description="Invalidate the current employee's API token.",
     *     @OA\Response(
     *         response=200,
     *         description="Logout successful",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Logged out successfully")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthorized")
     * )
     */
    public function logout(Request $request)
    {
        $employee = $request->user();

        if ($employee) {
            $employee->forceFill(['api_token' => null])->save();
        }

        return $this->successResponse(null, 'Logged out successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/get-tables",
     *     tags={"POS API - Step 3"},
     *     summary="Get Tables",
     *     security={{"bearerAuth":{}}},
     *     description="Return list of floors with their tables. Each table includes current status (available, occupied, reserved). If table is occupied, includes order_ticket_id and order_ticket_title. Otherwise, these fields are blank/null.",
     *     @OA\Parameter(
     *         name="floor_id",
     *         in="query",
     *         description="Filter tables by floor ID. Defaults to 1 if not provided.",
     *         required=false,
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Tables retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Ground Floor"),
     *                 @OA\Property(property="floor_type", type="string", example="indoor"),
     *                 @OA\Property(property="background_image_url", type="string", example="", description="Background image URL for the floor. Returns empty string if not set."),
     *                 @OA\Property(property="tables", type="array", @OA\Items(
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="name", type="string", example="T1"),
     *                     @OA\Property(property="size", type="string", example="medium"),
     *                     @OA\Property(property="capacity", type="integer", example=4),
     *                     @OA\Property(property="status", type="string", example="available"),
     *                     @OA\Property(property="x", type="number", format="float", example=100, description="X coordinate position of the table on the floor plan"),
     *                     @OA\Property(property="y", type="number", format="float", example=200, description="Y coordinate position of the table on the floor plan"),
     *                     @OA\Property(property="fire_status_pending", type="integer", example=0, description="Fire status pending: 1 = true (pending), 0 = false (not pending). Indicates if order has items still not fired"),
     *                     @OA\Property(property="is_table_locked", type="boolean", example=true, description="Table locking status. If true, only current_served_by_id can access the table. If false, any employee can access."),
     *                     @OA\Property(property="current_served_by_id", type="integer", nullable=true, example=7, description="Employee ID currently serving this table"),
     *                     @OA\Property(property="current_served_by_name", type="string", nullable=true, example="Riya Patel", description="Full name of employee currently serving this table"),
     *                     @OA\Property(property="order_ticket_id", type="string", nullable=true, example="ORD-20251103-U9VFRB", description="Order ticket ID if table is occupied, null otherwise"),
     *                     @OA\Property(property="order_ticket_title", type="string", nullable=true, example="20251103-01T1", description="Order ticket title if table is occupied, null otherwise"),
     *                     @OA\Property(property="selected_guest_count", type="integer", nullable=true, example=2, description="Number of customers/guests from the orders table if table is occupied, null otherwise"),
     *                     @OA\Property(property="occupied_by_employee_id", type="integer", nullable=true, example=7, description="Employee ID that opened the order for this table"),
     *                     @OA\Property(property="occupied_by_employee_name", type="string", nullable=true, example="Riya Patel", description="Employee full name that opened the order"),
     *                     @OA\Property(property="occupied_by_employee_avatar", type="string", nullable=true, example="https://ui-avatars.com/api/?name=Riya+Patel&size=200", description="Employee avatar URL")
     *                 ))
     *             ))
     *         )
     *     )
     * )
     */
    public function getTables(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        // Get floor_id from query parameter, default to 1 if not provided
        $floorId = $request->has('floor_id') ? $request->input('floor_id') : 1;
        // Convert to integer and ensure it's valid (default to 1 if invalid)
        $floorId = filter_var($floorId, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]) ?: 1;

        // Check if merged_table_ids column exists ONCE (outside the loop)
        $hasMergedTableIds = false;
        try {
            $columns = Schema::getColumnListing('orders');
            $hasMergedTableIds = in_array('merged_table_ids', $columns);
        } catch (\Exception $e) {
            // Column doesn't exist, skip merged_table_ids check
        }

        // OPTIMIZATION: Get table IDs for the requested floor(s) first to optimize order queries
        $floorQuery = Floor::where('business_id', $businessId)
            ->where('id', $floorId);
        $requestedFloors = $floorQuery->pluck('id');

        // Get all table IDs for the requested floors
        $tableIds = RestaurantTable::whereIn('floor_id', $requestedFloors)->pluck('id');

        // OPTIMIZATION: Fetch only active orders for tables in the requested floor
        // This further reduces data fetched when filtering by floor_id
        $activeOrdersQuery = Order::with([
            'createdByEmployee:id,first_name,last_name,avatar',
            'table',
            'checks.orderItems.menuItem.menuType',
            'checks.orderItems.menuItem.modifierGroups.modifiers',
            'checks.orderItems.menuItem.decisionGroups.decisions',
            'checks.orderItems.modifiers',
            'checks.orderItems.decisions'
        ])
            ->where('business_id', $businessId)
            ->where('status', '!=', 'completed');

        // Filter orders by table_ids from the requested floor
        // We need to also check merged tables, so we'll filter those in memory
        if ($tableIds->isNotEmpty()) {
            $activeOrdersQuery->whereIn('table_id', $tableIds);
        }

        $activeOrders = $activeOrdersQuery->get();

        // Filter merged table orders to only include those in requested floor
        // This handles cases where an order's main table is in a different floor
        // but has merged tables in the requested floor
        if ($hasMergedTableIds && $tableIds->isNotEmpty()) {
            $activeOrders = $activeOrders->filter(function ($order) use ($tableIds) {
                // Include if main table is in requested floor
                if ($tableIds->contains($order->table_id)) {
                    return true;
                }
                // Include if any merged table is in requested floor
                if ($order->merged_table_ids && is_array($order->merged_table_ids)) {
                    foreach ($order->merged_table_ids as $mergedTableId) {
                        if ($tableIds->contains($mergedTableId)) {
                            return true;
                        }
                    }
                }
                return false;
            });
        } elseif ($tableIds->isEmpty()) {
            // If no tables found for the floor, return empty collection
            $activeOrders = collect();
        }

        // OPTIMIZATION: Build lookup maps for O(1) access
        // Map: table_id => Order (for main table orders)
        $ordersByTableId = $activeOrders->keyBy('table_id');

        // Map: table_id => Order (for merged table orders)
        $ordersByMergedTableId = collect();
        if ($hasMergedTableIds) {
            foreach ($activeOrders as $order) {
                if ($order->merged_table_ids && is_array($order->merged_table_ids)) {
                    foreach ($order->merged_table_ids as $mergedTableId) {
                        // Only set if not already set (main table takes priority)
                        if (!$ordersByMergedTableId->has($mergedTableId)) {
                            $ordersByMergedTableId->put($mergedTableId, $order);
                        }
                    }
                }
            }
        }

        // Get floors with their tables (filtered by floor_id, default to 1)
        $floors = Floor::where('business_id', $businessId)
            ->where('id', $floorId)
            ->with(['tables.currentServedBy'])
            ->get()
            ->map(function ($floor) use ($ordersByTableId, $ordersByMergedTableId) {
                // Process each table to determine its status
                $tables = $floor->tables->map(function ($table) use ($ordersByTableId, $ordersByMergedTableId) {
                    // OPTIMIZATION: Use lookup maps instead of queries
                    $order = $ordersByTableId->get($table->id);

                    // If not found in main table orders, check merged table orders
                    if (!$order) {
                        $order = $ordersByMergedTableId->get($table->id);
                    }

                    $isOccupied = $order !== null;
                    $occupiedEmployee = $order?->createdByEmployee;

                    // If order exists, format full order data
                    $orderData = null;
                    if ($isOccupied && $order) {
                        // Format order with enhanced menu_item structure
                        $formattedOrder = $this->formatOrderWithEnhancedMenuItems($order);

                        // Format order data similar to resumeOrder response
                        $orderData = [
                            'ticket_id' => $order->order_ticket_id,
                            'data' => [
                                'order' => $formattedOrder,
                                'order_id' => $order->id,
                                'order_ticket_id' => $order->order_ticket_id,
                                'order_ticket_title' => $order->order_ticket_title,
                            ]
                        ];
                    }

                    // Get current served by employee info from log (not from table)
                    $currentServedById = null;
                    $currentServedByName = null;
                    if ($isOccupied && $order) {
                        // Get current_served_by_id from the latest log entry (where end_date is null)
                        $lastLogEntry = OrderAccessLog::with('employee')
                            ->where('order_id', $order->id)
                            ->whereNull('end_date')
                            ->orderBy('start_date', 'desc')
                            ->first();

                        if ($lastLogEntry && $lastLogEntry->employee) {
                            $currentServedById = $lastLogEntry->employee_id;
                            $currentServedByName = trim($lastLogEntry->employee->first_name . ' ' . $lastLogEntry->employee->last_name);
                        }
                    }

                    return [
                        'id' => $table->id,
                        'name' => $table->name,
                        'size' => $table->size,
                        'capacity' => $table->capacity,
                        'status' => $isOccupied ? 'occupied' : ($table->status ?? 'available'),
                        'x' => (float) ($table->x_coordinates ?? 0),
                        'y' => (float) ($table->y_coordinates ?? 0),
                        'fire_status_pending' => $table->fire_status_pending ?? 0,
                        'is_table_locked' => (bool) ($table->is_table_locked ?? true),
                        'current_served_by_id' => $currentServedById,
                        'current_served_by_name' => $currentServedByName,
                        'order_id' => $isOccupied ? ($order->id ?? null) : null,
                        'order_ticket_id' => $isOccupied ? ($order->order_ticket_id ?? null) : null,
                        'order_ticket_title' => $isOccupied ? ($order->order_ticket_title ?? null) : null,
                        'selected_guest_count' => $isOccupied ? ($order->customer ?? null) : null,
                        'occupied_by_employee_id' => $isOccupied ? ($order->created_by_employee_id ?? null) : null,
                        'occupied_by_employee_name' => ($isOccupied && $occupiedEmployee)
                            ? trim($occupiedEmployee->first_name . ' ' . $occupiedEmployee->last_name)
                            : null,
                        'occupied_by_employee_avatar' => ($isOccupied && $occupiedEmployee)
                            ? $occupiedEmployee->avatar
                            : null,
                        'order' => $orderData,
                    ];
                });

                return [
                    'id' => $floor->id,
                    'name' => $floor->name,
                    'floor_type' => $floor->floor_type,
                    'background_image_url' => $floor->background_image_url ?? '',
                    'tables' => $tables->values(),
                ];
            });

        return $this->successResponse($floors->values(), 'Tables retrieved successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/get-floors",
     *     tags={"POS API - Step 3"},
     *     summary="Get Floors",
     *     security={{"bearerAuth":{}}},
     *     description="Return list of all floors for the business. Each floor includes basic information like name, type, dimensions, and background image.",
     *     @OA\Response(
     *         response=200,
     *         description="Floors retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Ground Floor"),
     *                 @OA\Property(property="floor_type", type="string", example="indoor", nullable=true),
     *                 @OA\Property(property="width_px", type="integer", example=1920, nullable=true, description="Floor width in pixels"),
     *                 @OA\Property(property="height_px", type="integer", example=1080, nullable=true, description="Floor height in pixels"),
     *                 @OA\Property(property="background_image_url", type="string", example="", nullable=true, description="Background image URL for the floor. Returns empty string or null if not set.")
     *             )),
     *             @OA\Property(property="message", type="string", example="Floors retrieved successfully")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Employee not associated with a business",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Authenticated employee is not associated with a business")
     *         )
     *     )
     * )
     */
    public function getFloors(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        // Get all floors for the business
        $floors = Floor::where('business_id', $businessId)
            ->orderBy('id', 'asc')
            ->get()
            ->map(function ($floor) {
                return [
                    'id' => $floor->id,
                    'name' => $floor->name,
                    'floor_type' => $floor->floor_type,
                    'width_px' => $floor->width_px,
                    'height_px' => $floor->height_px,
                    'background_image_url' => $floor->background_image_url ?? '',
                ];
            });

        return $this->successResponse($floors->values(), 'Floors retrieved successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/menu",
     *     tags={"POS API - Step 4"},
     *     summary="Get Menu",
     *     security={{"bearerAuth":{}}},
     *     description="Fetch active menus with their categories (including hierarchy) and menu items with modifiers",
     *     @OA\Response(
     *         response=200,
     *         description="Menu retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="Dine-In Menu"),
     *                 @OA\Property(property="description", type="string", example="Restaurant dine-in offerings"),
     *                 @OA\Property(property="categories", type="array", @OA\Items(
     *                     @OA\Property(property="id", type="integer", example=11),
     *                     @OA\Property(property="name", type="string", example="Main Course"),
     *                     @OA\Property(property="description", type="string", example="Signature entrees"),
     *                     @OA\Property(property="menu_items", type="array", @OA\Items(
     *                         @OA\Property(property="id", type="integer", example=101),
     *                         @OA\Property(property="name", type="string", example="Chicken Biryani"),
     *                         @OA\Property(property="price_cash", type="number", example=18.00),
     *                         @OA\Property(property="price_card", type="number", example=19.00),
     *                         @OA\Property(property="printer_route_id", type="integer", nullable=true, example=2),
     *                         @OA\Property(property="menu_type_id", type="integer", nullable=true, example=3),
     *                         @OA\Property(property="menu_type", type="object", nullable=true,
     *                             @OA\Property(property="id", type="integer", example=3),
     *                             @OA\Property(property="name", type="string", example="Beverages"),
     *                             @OA\Property(property="description", type="string", example="Beverage items")
     *                         ),
     *                         @OA\Property(property="is_auto_fire", type="boolean", example=true, description="Auto fire status: true = automatically fire to kitchen, false = on hold"),
     *                         @OA\Property(property="modifier_groups", type="array", @OA\Items(
     *                             @OA\Property(property="id", type="integer", example=5),
     *                             @OA\Property(property="name", type="string", example="Spice Level"),
     *                             @OA\Property(property="min_select", type="integer", example=1),
     *                             @OA\Property(property="max_select", type="integer", example=1),
     *                             @OA\Property(property="modifiers", type="array", @OA\Items(
     *                                 @OA\Property(property="id", type="integer", example=21),
     *                                 @OA\Property(property="name", type="string", example="Medium"),
     *                                 @OA\Property(property="additional_price", type="number", example=0.00)
     *                             ))
     *                         ))
     *                     )),
     *                     @OA\Property(property="children", type="array", @OA\Items(
     *                         @OA\Property(property="id", type="integer", example=12),
     *                         @OA\Property(property="name", type="string", example="Vegetarian"),
     *                         @OA\Property(property="description", type="string", example="Meat-free offerings"),
     *                         @OA\Property(property="menu_items", type="array", @OA\Items(type="object")),
     *                         @OA\Property(property="children", type="array", @OA\Items(type="object"))
     *                     ))
     *                 ))
     *             ))
     *         )
     *     )
     * )
     */
    public function getMenu(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $menus = Menu::where('business_id', $businessId)
            ->where('is_active', true)
            ->with(['categories' => function ($categoryQuery) {
                $categoryQuery->whereNull('parent_id')
                    ->where('is_active', true)
                    ->with([
                        'childrenRecursive',
                        'menuItems' => function ($itemQuery) {
                            $itemQuery->where('is_active', true)
                                ->with([
                                    'menuType',
                                    'modifierGroups.modifiers',
                                    'decisionGroups.decisions',
                                ]);
                        },
                    ]);
            }])
            ->get();

        $formattedMenus = $this->formatMenus($menus);

        return $this->successResponse($formattedMenus, 'Menu retrieved successfully');
    }

    private function formatMenus(Collection $menus): array
    {
        return $menus->map(function (Menu $menu) {
            $categories = $menu->relationLoaded('categories') ? $menu->categories : collect();
            $formattedCategories = $this->formatCategories($categories);

            return [
                'id' => $menu->id ?? 0,
                'name' => $menu->name ?? '',
                'description' => $menu->description ?? '',
                'image' => $menu->image ?? '',
                'icon_image' => $menu->icon_image ?? '',
                'categories' => $formattedCategories ?? [],
            ];
        })->values()->toArray();
    }

    private function formatCategories(Collection $categories): array
    {
        return $categories->map(function (MenuCategory $category) {
            // Get children sub-categories (recursive)
            $childrenCollection = $category->relationLoaded('childrenRecursive')
                ? $category->childrenRecursive
                : collect();

            // Get menu items directly assigned to this category (via menu_category_id)
            $itemsCollection = $category->relationLoaded('menuItems')
                ? $category->menuItems
                : collect();

            // Format children recursively (each child will have its own menu_items if assigned)
            $children = $this->formatCategories($childrenCollection);

            // Format menu items for this category (items stay with their assigned category)
            $items = $this->formatMenuItems($itemsCollection);

            // Only exclude category if it has no menu items AND no children
            if (empty($items) && empty($children)) {
                return null;
            }

            return [
                'id' => $category->id,
                'name' => $category->name,
                'description' => $category->description,
                'image' => $category->image,
                'icon_image' => $category->icon_image,
                'menu_items' => $items, // Menu items assigned to this category
                'children' => $children, // Child categories (each with their own menu_items)
            ];
        })->filter()->values()->toArray();
    }

    private function formatMenuItems(Collection $items): array
    {
        return $items->map(function (MenuItem $item) {
            $modifierGroups = $item->relationLoaded('modifierGroups')
                ? $this->formatModifierGroups($item->modifierGroups)
                : [];
            $decisionGroups = $item->relationLoaded('decisionGroups')
                ? $this->formatDecisionGroups($item->decisionGroups)
                : [];

            return [
                'id' => $item->id,
                'name' => $item->name,
                'price_cash' => (float) $item->price_cash,
                'price_card' => (float) $item->price_card,
                'image' => $item->image,
                'icon_image' => $item->icon_image,
                'printer_route_id' => $item->printer_route_id ?? 0,
                'menu_type_id' => $item->menu_type_id,
                'menu_type' => $item->relationLoaded('menuType') && $item->menuType ? [
                    'id' => $item->menuType->id,
                    'name' => $item->menuType->name,
                    'description' => $item->menuType->description,
                ] : null,
                'is_auto_fire' => (bool) $item->is_auto_fire,
                'is_open_item' => (bool) $item->is_open_item,
                'modifier_groups' => $modifierGroups,
                'decision_groups' => $decisionGroups,
            ];
        })->values()->toArray();
    }

    private function formatModifierGroups(Collection $groups): array
    {
        return $groups->map(function (ModifierGroup $group) {
            $modifiers = $group->relationLoaded('modifiers')
                ? $group->modifiers->map(function (Modifier $modifier) {
                    return [
                        'id' => $modifier->id,
                        'name' => $modifier->name,
                        'additional_price' => (float) $modifier->additional_price,
                    ];
                })->values()->toArray()
                : [];

            return [
                'id' => $group->id,
                'name' => $group->name,
                'min_select' => $group->min_select,
                'max_select' => $group->max_select,
                'modifiers' => $modifiers,
            ];
        })->values()->toArray();
    }

    private function formatDecisionGroups(Collection $groups): array
    {
        return $groups->map(function (DecisionGroup $group) {
            $decisions = $group->relationLoaded('decisions')
                ? $group->decisions->map(function (Decision $decision) {
                    return [
                        'id' => $decision->id,
                        'name' => $decision->name,
                    ];
                })->values()->toArray()
                : [];

            return [
                'id' => $group->id,
                'name' => $group->name,
                'decisions' => $decisions,
            ];
        })->values()->toArray();
    }

    /**
     * Format order with enhanced menu_item structure (matching getMenu API format)
     */
    private function formatOrderWithEnhancedMenuItems($order)
    {
        // Work with model relationships directly, then convert to array
        $formattedChecks = $order->checks->map(function ($check) {
            $formattedOrderItems = $check->orderItems->map(function ($orderItem) {
                $orderItemArray = $orderItem->toArray();

                // Discount fields are handled by model casts (decimal:2 returns strings like "0.00")
                $orderItemArray['discount_type'] = $orderItem->discount_type;
                $orderItemArray['discount_value'] = $orderItem->discount_value;
                $orderItemArray['discount_amount'] = $orderItem->discount_amount;

                if ($orderItem->menuItem) {
                    $menuItem = $orderItem->menuItem;

                    // Format menu_item with enhanced structure
                    $modifierGroups = $menuItem->relationLoaded('modifierGroups')
                        ? $this->formatModifierGroups($menuItem->modifierGroups)
                        : [];
                    $decisionGroups = $menuItem->relationLoaded('decisionGroups')
                        ? $this->formatDecisionGroups($menuItem->decisionGroups)
                        : [];

                    $orderItemArray['menu_item'] = [
                        'id' => $menuItem->id,
                        'business_id' => $menuItem->business_id,
                        'menu_category_id' => $menuItem->menu_category_id,
                        'menu_type_id' => $menuItem->menu_type_id,
                        'name' => $menuItem->name,
                        'price_cash' => (float) $menuItem->price_cash,
                        'price_card' => (float) $menuItem->price_card,
                        'image' => $menuItem->image ?? '',
                        'icon_image' => $menuItem->icon_image ?? '',
                        'is_active' => (bool) $menuItem->is_active,
                        'is_auto_fire' => (bool) $menuItem->is_auto_fire,
                        'is_open_item' => (bool) $menuItem->is_open_item,
                        'printer_route_id' => $menuItem->printer_route_id ?? 0,
                        'created_at' => $menuItem->created_at,
                        'updated_at' => $menuItem->updated_at,
                        'menu_type' => $menuItem->relationLoaded('menuType') && $menuItem->menuType ? [
                            'id' => $menuItem->menuType->id,
                            'name' => $menuItem->menuType->name,
                            'description' => $menuItem->menuType->description ?? '',
                        ] : null,
                        'modifier_groups' => $modifierGroups,
                        'decision_groups' => $decisionGroups,
                    ];
                }

                return $orderItemArray;
            });

            $checkArray = $check->toArray();
            $checkArray['order_items'] = $formattedOrderItems->toArray();
            return $checkArray;
        });

        // Convert order to array and replace checks
        $orderArray = $order->toArray();
        $orderArray['checks'] = $formattedChecks->toArray();

        return $orderArray;
    }

    /**
     * @OA\Post(
     *     path="/pos/reserve_table",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 5"},
     *     summary="Reserve Table (Create New Order)",
     *     description="Reserve a table by creating a new order. Table must be available (not occupied). Server automatically generates order_ticket_id (unique ID) and order_ticket_title (format: YYYYMMDD-NNT1). gratuity_key defaults to 'NotApplicable'. If gratuity_key is 'Auto' or 'NotApplicable', gratuity_type and gratuity_value are not required. If gratuity_key is 'Manual', both gratuity_type and gratuity_value are required.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"table_id"},
     *             @OA\Property(property="table_id", type="integer", example=1, description="Table ID - table must be available (not occupied). Once used, table becomes occupied."),
     *             @OA\Property(property="customer", type="integer", example=2, description="Number of customers (default: 1). Must not exceed table capacity. If exceeded, merge tables first."),
     *             @OA\Property(property="gratuity_key", type="string", enum={"Auto", "Manual", "NotApplicable"}, example="NotApplicable", description="Gratuity key type. Defaults to 'NotApplicable'. If 'Auto' or 'NotApplicable', gratuity_type and gratuity_value are not required. If 'Manual', both gratuity_type and gratuity_value are required."),
     *             @OA\Property(property="gratuity_type", type="string", enum={"fixed_money", "percentage"}, example="percentage", description="Required if gratuity_key is 'Manual'. Optional otherwise. fixed_money or percentage"),
     *             @OA\Property(property="gratuity_value", type="integer", example=15, description="Required if gratuity_key is 'Manual'. Optional otherwise. Value in integer (e.g., 10, 12, 20)"),
     *             @OA\Property(property="order_notes", type="string", example="Table near window", description="Optional notes for the order")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Order created successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="order", type="object", description="Full order object"),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20241103-ABC123", description="Server-generated unique ticket ID"),
     *                 @OA\Property(property="order_ticket_title", type="string", example="20241103-01T1", description="Format: YYYYMMDD-NNT1 (e.g., 20241103-01T1 for first order of day on table T1)"),
     *                 @OA\Property(property="message", type="string", example="Order created successfully")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad request - table is already occupied"
     *     )
     * )
     */
    public function orderProcess(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        // Validate table_id first to locate table and business info
        $request->validate([
            'table_id' => 'required|exists:restaurant_tables,id',
        ]);

        $table = RestaurantTable::with('floor')->find($request->table_id);

        if (!$table) {
            return $this->notFoundResponse('Table not found');
        }

        if ((int) $table->floor->business_id !== (int) $businessId) {
            return $this->forbiddenResponse('Table does not belong to the authenticated business');
        }

        // Build validation rules - gratuity_key defaults to 'NotApplicable'
        $validationRules = [
            'table_id' => 'required|exists:restaurant_tables,id',
            'customer' => 'nullable|integer|min:1|max:20',
            'order_notes' => 'nullable|string|max:1000',
            'gratuity_key' => 'nullable|in:Auto,Manual,NotApplicable',
            'gratuity_type' => 'nullable|in:fixed_money,percentage',
            'gratuity_value' => 'nullable|integer|min:0',
        ];

        $validated = $request->validate($validationRules);

        // Set default gratuity_key to 'NotApplicable' if not provided
        $gratuityKey = $validated['gratuity_key'] ?? 'NotApplicable';

        // Conditional validation based on gratuity_key
        if ($gratuityKey === 'Manual') {
            $manualValidation = $request->validate([
                'gratuity_type' => 'required|in:fixed_money,percentage',
                'gratuity_value' => 'required|integer|min:0',
            ]);
            // Merge validated manual fields back into validated array
            $validated = array_merge($validated, $manualValidation);
        }

        // Ensure user cannot pass temp_ticket_id - server generates order_ticket_id
        // Remove temp_ticket_id if user tries to send it
        $request->merge(['temp_ticket_id' => null]);

        // Check if table is already occupied (has open order)
        $existingOrder = Order::where('business_id', $businessId)
            ->where('table_id', $validated['table_id'])
            ->where('status', '!=', 'completed')
            ->first();

        if ($existingOrder) {
            return $this->errorResponse('Table is already occupied. Use resume_order API to access the existing order.', 400);
        }

        // Verify table is not occupied (status check)
        if ($table->status === 'occupied') {
            return $this->errorResponse('Table is already occupied. Please select another table.', 400);
        }

        // Validate customer count against table capacity
        $customerCount = $validated['customer'] ?? 1;
        $tableCapacity = $table->capacity ?? 0;

        if ($customerCount > $tableCapacity) {
            return $this->errorResponse("Number of customers ($customerCount) exceeds table capacity ($tableCapacity). Please merge tables to accommodate more customers.", 400);
        }

        // Generate order_ticket_id (unique ID) - server generates this, user cannot pass it
        $orderTicketId = 'ORD-' . date('Ymd') . '-' . strtoupper(Str::random(6));

        // Generate order_ticket_title (YYYYMMDD-NNT1 format)
        // Count how many orders exist for this table on this day
        $today = date('Y-m-d');
        $orderCount = Order::where('business_id', $businessId)
            ->where('table_id', $validated['table_id'])
            ->whereDate('created_at', $today)
            ->count();

        // Increment for this new order
        $orderNumber = str_pad($orderCount + 1, 2, '0', STR_PAD_LEFT);

        // Format: YYYYMMDD-NNT1 (e.g., 20241103-01T1, 20241103-02T1)
        $orderTicketTitle = date('Ymd') . '-' . $orderNumber . $table->name;

        // Get gratuity values based on gratuity_key from request
        $gratuityType = null;
        $gratuityValue = 0; // Default to 0 (cannot be null in database)

        if ($gratuityKey === 'Manual') {
            // Manual: Use values from request (already validated as required)
            $gratuityType = $validated['gratuity_type'];
            $gratuityValue = $validated['gratuity_value'];
        } elseif ($gratuityKey === 'Auto') {
            // Auto: Get values from GratuitySetting table
            $gratuitySetting = GratuitySetting::where('business_id', $businessId)->first();
            if ($gratuitySetting) {
                $gratuityType = $gratuitySetting->gratuity_type;
                $gratuityValue = $gratuitySetting->gratuity_value ?? 0;
            }
        }
        // NotApplicable: gratuity_type = null, gratuity_value = 0 (default)

        // Get tax rate from tax_rates table (food)
        $taxValue = 0.00;
        $foodTaxRate = TaxRate::where('business_id', $businessId)
            ->where('applies_to', 'food')
            ->first();

        if ($foodTaxRate && $foodTaxRate->rate_percent > 0) {
            // Store the tax rate percentage initially (will be updated to calculated amount later)
            $taxValue = $foodTaxRate->rate_percent;
        }

        // Get fee preset from fees table
        $feeValue = 0.00;
        $fee = Fee::where('business_id', $businessId)->first();

        if ($fee && $fee->fee_preset > 0) {
            // Store the fee preset amount
            $feeValue = $fee->fee_preset;
        }

        // Create new order
        $order = Order::create([
            'business_id' => $businessId,
            'table_id' => $validated['table_id'],
            'created_by_employee_id' => $employee->id,
            'status' => 'open',
            'customer' => $customerCount,
            'notes' => $validated['order_notes'] ?? null,
            'order_ticket_id' => $orderTicketId,
            'order_ticket_title' => $orderTicketTitle,
            'gratuity_key' => $gratuityKey,
            'gratuity_type' => $gratuityType,
            'gratuity_value' => $gratuityValue,
            'tax_value' => $taxValue,
            'fee_value' => $feeValue,
            'merged_table_ids' => [$validated['table_id']], // Initialize with single table ID
        ]);

        // Create a check for this order
        // check_number is integer - use simple sequential number
        $check = Check::create([
            'order_id' => $order->id,
            'check_number' => $order->id, // Simple integer check number
            'status' => 'open',
        ]);

        // Update table status to occupied and set current_served_by_id
        RestaurantTable::where('id', $validated['table_id'])->update([
            'status' => 'occupied',
            'current_served_by_id' => $employee->id,
        ]);

        // Create order_access_log entry
        OrderAccessLog::create([
            'order_id' => $order->id,
            'employee_id' => $employee->id,
            'start_date' => now(),
            'end_date' => null,
        ]);

        // Return order with explicitly shown order_ticket_id and order_ticket_title
        $order->load(['table', 'createdByEmployee', 'checks']);

        return $this->successResponse([
            'order' => $order,
            'order_ticket_id' => $order->order_ticket_id,
            'order_ticket_title' => $order->order_ticket_title,
            'message' => 'Order created successfully'
        ], 'Order created successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/resume_order",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 5"},
     *     summary="Resume Order",
     *     description="Resume an existing order by order_ticket_id. When accessed, automatically sets is_table_locked = true and creates/updates order_access_log entry. If a different employee accesses, the previous log entry is closed and a new one is created.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id"},
     *             @OA\Property(property="order_ticket_id", type="string", example="ORD-20251103-U9VFRB", description="Order ticket ID from get-tables API (when table is occupied)"),
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Order resumed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="order", type="object", description="Full order object"),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251103-U9VFRB", description="Order ticket ID"),
     *                 @OA\Property(property="order_ticket_title", type="string", example="20251103-01T1", description="Order ticket title"),
     *                 @OA\Property(property="message", type="string", example="Order resumed successfully")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Order does not belong to business"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order not found or already completed"
     *     )
     * )
     */
    public function resumeOrder(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
        ]);

        // Find order by order_ticket_id
        $order = Order::with(['table.floor'])
            ->where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->where('status', '!=', 'completed')
            ->first();

        if (!$order) {
            return $this->errorResponse('Order not found or already completed', 404);
        }

        if (!$order->table || !$order->table->floor) {
            return $this->forbiddenResponse('Order does not belong to the authenticated business');
        }

        if ((int) $order->table->floor->business_id !== (int) $businessId) {
            return $this->forbiddenResponse('Order does not belong to the authenticated business');
        }

        // Load table
        $table = $order->table;

        // Check if table is locked
        $isTableLocked = (bool) ($table->is_table_locked ?? true);

        // If table is NOT locked (false), lock it and create log entry
        if (!$isTableLocked) {
            // Get current_served_by_id from the latest log entry (where end_date is null)
            $lastLogEntry = OrderAccessLog::where('order_id', $order->id)
                ->whereNull('end_date')
                ->orderBy('start_date', 'desc')
                ->first();

            $currentServedById = $lastLogEntry ? $lastLogEntry->employee_id : null;

            // Handle order_access_log
            // If different employee is accessing, close previous log and create new one
            if ($currentServedById && (int) $currentServedById !== (int) $employee->id) {
                // Update previous entry's end_date
                $lastLogEntry->update(['end_date' => now()]);

                // Create new log entry with new employee
                OrderAccessLog::create([
                    'order_id' => $order->id,
                    'employee_id' => $employee->id,
                    'start_date' => now(),
                    'end_date' => null,
                ]);
            } elseif (!$currentServedById) {
                // If no current server, create log entry
                OrderAccessLog::create([
                    'order_id' => $order->id,
                    'employee_id' => $employee->id,
                    'start_date' => now(),
                    'end_date' => null,
                ]);
            }

            // Lock the table and set current_served_by_id from the log
            // Get the latest current_served_by_id from log after creating/updating log entry
            $latestLogEntry = OrderAccessLog::where('order_id', $order->id)
                ->whereNull('end_date')
                ->orderBy('start_date', 'desc')
                ->first();

            $table->update([
                'current_served_by_id' => $latestLogEntry ? $latestLogEntry->employee_id : $employee->id,
                'is_table_locked' => true, // Change from false to true
            ]);

            // Reload table to get updated values
            $table->refresh();
        } else {
            // If table is locked (true), don't create log entry, don't change lock
            // But update current_served_by_id from log to ensure it's correct
            $latestLogEntry = OrderAccessLog::where('order_id', $order->id)
                ->whereNull('end_date')
                ->orderBy('start_date', 'desc')
                ->first();

            if ($latestLogEntry && $table->current_served_by_id != $latestLogEntry->employee_id) {
                // Update current_served_by_id from log (but keep is_table_locked as true)
                $table->update([
                    'current_served_by_id' => $latestLogEntry->employee_id,
                ]);
                $table->refresh();
            }
        }

        // Load relationships - include menu_item with full details, modifiers, and decisions for order items
        $order->load([
            'table.currentServedBy',
            'createdByEmployee',
            'checks.orderItems.menuItem.menuType',
            'checks.orderItems.menuItem.modifierGroups.modifiers',
            'checks.orderItems.menuItem.decisionGroups.decisions',
            'checks.orderItems.modifiers',
            'checks.orderItems.decisions'
        ]);

        // Format order with enhanced menu_item structure
        $formattedOrder = $this->formatOrderWithEnhancedMenuItems($order);

        return $this->successResponse([
            'order' => $formattedOrder,
            'order_id' => $order->id,
            'order_ticket_id' => $order->order_ticket_id,
            'order_ticket_title' => $order->order_ticket_title,
            'message' => 'Order resumed successfully'
        ], 'Order resumed successfully');
    }

    public function addOrderItems(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_id' => 'required|exists:orders,id',
            'items' => 'required|array',
            'items.*.menu_item_id' => 'required|exists:menu_items,id',
            'items.*.qty' => 'required|integer|min:1',
            'items.*.instructions' => 'nullable|string|max:500',
            'items.*.modifier_ids' => 'nullable|array',
            'items.*.modifier_ids.*' => 'exists:modifiers,id',
        ]);

        $order = Order::where('id', $validated['order_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        $createdItems = [];

        foreach ($validated['items'] as $item) {
            $menuItem = MenuItem::find($item['menu_item_id']);

            $orderItem = OrderItem::create([
                'order_id' => $order->id,
                'check_id' => $check->id,
                'menu_item_id' => $item['menu_item_id'],
                'qty' => $item['qty'],
                'unit_price' => $menuItem->price_card,
                'instructions' => $item['instructions'] ?? '',
                'employee_id' => $employee->id, // Set employee_id from authenticated employee (token user)
            ]);

            // Attach modifiers if provided
            if (isset($item['modifier_ids']) && is_array($item['modifier_ids'])) {
                $pivotData = collect($item['modifier_ids'])
                    ->mapWithKeys(fn($modifierId) => [$modifierId => [
                        'order_id' => $order->id,
                        'employee_id' => $employee->id, // Set employee_id from authenticated employee (token user)
                    ]])
                    ->toArray();

                $orderItem->modifiers()->sync($pivotData);
            }

            $createdItems[] = $orderItem->load(['menuItem', 'modifiers']);
        }

        return $this->successResponse($createdItems, 'Items added to order successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/send-to-kitchen",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 6"},
     *     summary="Send to Kitchen",
     *     description="Send order items to kitchen. This endpoint creates new order items in the database and sends them to the kitchen.
     *
     *     **How It Works:**
     *     1. Frontend sends only items that don't have an `orderItemId` (temporary/new items)
     *     2. Backend creates all sent items in the database and assigns unique IDs
     *     3. Backend returns the created items with their database IDs
     *     4. Frontend updates local items with the returned IDs, marking them as 'saved'
     *     5. Saved items (with orderItemId) won't be sent again, preventing duplicates
     *     6. Users can re-add the same item by creating a new temporary item (orderItemId = null)
     *
     *     **Re-Ordering Same Items:**
     *     - If user adds 'Anarkali' and sends it, it gets an orderItemId
     *     - If user adds 'Anarkali' again, it's a NEW temporary item (orderItemId = null)
     *     - When sent, it creates a NEW order item in database (allows re-ordering)
     *     - Both items will exist in the order (first one with ID=1, second one with ID=2)
     *
     *     **Item States:**
     *     - Temporary Item: orderItemId = 0 (not saved, can be sent)
     *     - Saved Item: orderItemId > 0 (already in database, won't be sent again)
     *
     *     **Note:** You must first create an order using the 'reserve_table' endpoint to get a valid order_id.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="application/json",
     *             @OA\Schema(
     *                 required={"order_ticket_id", "order_id", "items"},
     *                 @OA\Property(
     *                     property="order_ticket_id",
     *                     type="string",
     *                     example="ORD-20241103-ABC123",
     *                     description="Order ticket ID from reserve_table endpoint"
     *                 ),
     *                 @OA\Property(
     *                     property="order_id",
     *                     type="integer",
     *                     example=1,
     *                     description="Order ID from reserve_table endpoint"
     *                 ),
     *                 @OA\Property(
     *                     property="items",
     *                     type="array",
     *                     description="**IMPORTANT:** Send items with orderItemId = 0 to create new items, or orderItemId > 0 to update existing items. Frontend should filter items: orderItemId == 0 for new items, orderItemId > 0 for updates.",
     *                     @OA\Items(
     *                     @OA\Property(property="orderItemId", type="integer", example=0, description="**REQUIRED.** 0 = new item (create), > 0 = existing item ID (update)"),
     *                     @OA\Property(property="menu_item_id", type="integer", example=1),
     *                     @OA\Property(property="qty", type="integer", example=2),
     *                     @OA\Property(property="unit_price", type="number", format="float", example=10.50),
     *                     @OA\Property(property="instructions", type="string", example="No onions", nullable=true),
     *                     @OA\Property(property="order_status", type="integer", example=1, description="Order status: 0=HOLD, 1=FIRE, 2=TEMP, 3=VOID", nullable=true),
     *                     @OA\Property(property="customer_no", type="integer", example=1, description="Customer number (1, 2, 3, etc.)", nullable=true),
     *                     @OA\Property(property="decisions", type="array", description="Array of decision objects. Each decision_id must exist in the decisions table. Can be empty array or null if no decisions.", nullable=true,
     *                         @OA\Items(
     *                             type="object",
     *                             @OA\Property(property="decision_id", type="integer", example=1, description="ID of the decision. Must exist in the decisions table.")
     *                         )
     *                     ),
     *                     @OA\Property(property="modifiers", type="array", description="Array of modifier objects. Each modifier_id must exist in the modifiers table. Can be empty array or null if no modifiers.", nullable=true,
     *                         @OA\Items(
     *                             type="object",
     *                             @OA\Property(property="modifier_id", type="integer", example=1, description="ID of the modifier. Must exist in the modifiers table."),
     *                             @OA\Property(property="qty", type="integer", example=1, description="Quantity of the modifier"),
     *                             @OA\Property(property="price", type="number", format="float", example=2.00, description="Price of the modifier")
     *                         )
     *                     )
     *                 )),
     *                 @OA\Property(property="is_table_locked", type="boolean", example=false, nullable=true, description="Table locking status. If provided, updates the table's is_table_locked field and sets current_served_by_id to the authenticated employee.")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Order sent to kitchen successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Order sent to kitchen successfully"),
     *             @OA\Property(
     *                 property="data",
     *                 type="object",
     *                 @OA\Property(
     *                     property="new_items_count",
     *                     type="integer",
     *                     example=3,
     *                     description="Number of new items created and sent to kitchen"
     *                 ),
     *                 @OA\Property(
     *                     property="total_items_count",
     *                     type="integer",
     *                     example=5,
     *                     description="Total number of items in the order (including previously sent items)"
     *                 ),
     *                 @OA\Property(
     *                     property="new_items",
     *                     type="array",
     *                     description="Array of newly created order items with their database IDs. Frontend MUST update local items with these IDs to mark them as saved.",
     *                     @OA\Items(
     *                         type="object",
     *                         @OA\Property(
     *                             property="id",
     *                             type="integer",
     *                             example=1,
     *                             description="**IMPORTANT:** This is the database ID (orderItemId). Frontend must store this in the OrderItem's orderItemId field to mark it as saved."
     *                         ),
     *                         @OA\Property(property="order_id", type="integer", example=1),
     *                         @OA\Property(property="check_id", type="integer", example=1),
     *                         @OA\Property(property="menu_item_id", type="integer", example=5),
     *                         @OA\Property(property="qty", type="integer", example=2),
     *                         @OA\Property(property="unit_price", type="number", example=210.00),
     *                         @OA\Property(property="instructions", type="string", nullable=true, example="No onions"),
     *                         @OA\Property(
     *                             property="order_status",
     *                             type="integer",
     *                             example=1,
     *                             description="Order status: 0=HOLD, 1=FIRE, 2=TEMP, 3=VOID"
     *                         ),
     *                         @OA\Property(
     *                             property="customer_no",
     *                             type="integer",
     *                             example=1,
     *                             description="Customer number (1-based: 1, 2, 3, etc.)"
     *                         ),
     *                         @OA\Property(
     *                             property="sequence",
     *                             type="integer",
     *                             example=0,
     *                             description="Priority sequence (lower number = higher priority). Set incrementally based on existing max sequence for the check."
     *                         ),
     *                         @OA\Property(
     *                             property="created_at",
     *                             type="string",
     *                             format="date-time",
     *                             example="2025-11-23T06:17:11.000000Z",
     *                             description="Timestamp when the item was created. Used for calculating elapsed time in status screen."
     *                         ),
     *                         @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-23T06:17:11.000000Z")
     *                     )
     *                 ),
     *                 @OA\Property(
     *                     property="order",
     *                     type="object",
     *                     description="Order details with table and employee information"
     *                 ),
     *                 @OA\Property(
     *                     property="kitchen_tickets",
     *                     type="array",
     *                     description="Kitchen tickets generated for printing",
     *                     @OA\Items(
     *                         type="object"
     *                     )
     *                 ),
     *                 @OA\Property(
     *                     property="is_table_locked",
     *                     type="boolean",
     *                     example=false,
     *                     description="Table locking status. If true, only current_served_by_id can access the table."
     *                 ),
     *                 @OA\Property(
     *                     property="current_served_by_id",
     *                     type="integer",
     *                     nullable=true,
     *                     example=7,
     *                     description="Employee ID currently serving this table"
     *                 ),
     *                 @OA\Property(
     *                     property="current_served_by_name",
     *                     type="string",
     *                     nullable=true,
     *                     example="Riya Patel",
     *                     description="Full name of employee currently serving this table"
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or Check not found"
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Order does not belong to business"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Validation error"
     *     )
     * )
     */
    public function sendToKitchen(Request $request)
    {

        try {
            Log::info('Send to Kitchen - Request received', [
                'employee_id' => $request->user()?->id,
                'order_id' => $request->input('order_id'),
                'order_ticket_id' => $request->input('order_ticket_id'),
                'items_count' => count($request->input('items', [])),
            ]);

            $employee = $request->user();
            $businessId = $employee?->business_id;

            if (!$businessId) {
                Log::warning('Send to Kitchen - Employee not associated with business', [
                    'employee_id' => $employee?->id,
                ]);
                return $this->forbiddenResponse('Authenticated employee is not associated with a business');
            }

            $validated = $request->validate([
                'order_ticket_id' => 'required|string',
                'order_id' => [
                    'required',
                    'integer',
                    function ($attribute, $value, $fail) use ($businessId) {
                        $order = Order::where('id', $value)
                            ->where('business_id', $businessId)
                            ->first();
                        if (!$order) {
                            Log::warning('Send to Kitchen - Invalid order ID', [
                                'order_id' => $value,
                                'business_id' => $businessId,
                            ]);
                            $fail('The selected order id is invalid or does not belong to your business.');
                        }
                    },
                ],
                'items' => 'nullable|array',
                'items.*.orderItemId' => 'required|integer|min:0',
                'items.*.menu_item_id' => 'required|exists:menu_items,id',
                'items.*.qty' => 'required|integer|min:1',
                'items.*.unit_price' => 'required|numeric|min:0',
                'items.*.instructions' => 'nullable|string|max:500',
                'items.*.order_status' => 'nullable|integer|in:0,1,2,3',
                'items.*.customer_no' => 'nullable|integer|min:0|max:10',
                'items.*.decisions' => 'nullable|array',
                'items.*.decisions.*.decision_id' => 'required|exists:decisions,id',
                'items.*.modifiers' => 'nullable|array',
                'items.*.modifiers.*.modifier_id' => 'required|exists:modifiers,id',
                'items.*.modifiers.*.qty' => 'required|integer|min:1',
                'items.*.modifiers.*.price' => 'required|numeric|min:0',
                'is_table_locked' => 'nullable|boolean',
            ]);

            Log::info('Send to Kitchen - Validation passed', [
                'order_id' => $validated['order_id'],
                'order_ticket_id' => $validated['order_ticket_id'],
                'items_count' => count($validated['items'] ?? []),
                'is_table_locked' => $validated['is_table_locked'] ?? null,
            ]);

            $order = Order::where('id', $validated['order_id'])
                ->where('business_id', $businessId)
                ->first();

            if (!$order) {
                Log::error('Send to Kitchen - Order not found', [
                    'order_id' => $validated['order_id'],
                    'business_id' => $businessId,
                ]);
                return $this->notFoundResponse('Order not found or does not belong to your business');
            }

            $check = Check::where('order_id', $order->id)->first();

            if (!$check) {
                Log::error('Send to Kitchen - Check not found', [
                    'order_id' => $order->id,
                ]);
                return $this->notFoundResponse('Check not found for this order');
            }

            Log::info('Send to Kitchen - Order and Check found', [
                'order_id' => $order->id,
                'check_id' => $check->id,
                'order_status' => $order->status,
            ]);

            // Handle empty items array - if items is empty and is_table_locked is false, just unlock table
            $items = $validated['items'] ?? [];

            // If items is empty and is_table_locked is false, just unlock the table and return success
            if (empty($items) && isset($validated['is_table_locked']) && $validated['is_table_locked'] === false) {
                $table = $order->table;
                if ($table) {
                    $table->update([
                        'is_table_locked' => false,
                        'current_served_by_id' => null,
                    ]);

                    Log::info('Send to Kitchen - Table unlocked (no items)', [
                        'order_id' => $order->id,
                        'table_id' => $table->id,
                        'is_table_locked' => false,
                    ]);

                    return $this->successResponse([
                        'order' => $order->load(['table', 'createdByEmployee']),
                        'new_items' => [],
                        'new_items_count' => 0,
                        'updated_items' => [],
                        'updated_items_count' => 0,
                        'total_items_count' => 0,
                        'kitchen_tickets' => [],
                        'is_table_locked' => false,
                        'current_served_by_id' => null,
                        'current_served_by_name' => null,
                    ], 'Table unlocked successfully');
                }
            }

            // If items is empty but is_table_locked is not false, require items
            if (empty($items)) {
                Log::warning('Send to Kitchen - No items provided', [
                    'order_id' => $order->id,
                    'is_table_locked' => $validated['is_table_locked'] ?? null,
                ]);
                return $this->errorResponse('Items are required when not unlocking table. Provide items array or set is_table_locked to false to unlock table.', 422);
            }

            // Separate items into new items (orderItemId = 0) and update items (orderItemId > 0)
            $newItems = [];
            $updateItems = [];

            foreach ($items as $item) {
                if (!isset($item['orderItemId'])) {
                    continue; // Skip items without orderItemId
                }

                $orderItemId = (int)$item['orderItemId'];
                if ($orderItemId === 0) {
                    $newItems[] = $item;
                } else {
                    $updateItems[] = $item;
                }
            }

            if (empty($newItems) && empty($updateItems)) {
                Log::warning('Send to Kitchen - No items to process', [
                    'order_id' => $order->id,
                    'total_items_received' => count($items),
                ]);
                return $this->errorResponse('No items to process. Items must have orderItemId (0 for new items, > 0 for updates).', 422);
            }

            Log::info('Send to Kitchen - Processing items', [
                'order_id' => $order->id,
                'requested_items_count' => count($items),
                'new_items_count' => count($newItems),
                'update_items_count' => count($updateItems),
            ]);

            // Get max sequence for this check to set new items' sequence
            $maxSequence = OrderItem::where('check_id', $check->id)->max('sequence') ?? -1;

            // Create new order items (orderItemId = 0)
            $createdOrderItems = [];
            $newItemsForTickets = [];
            $skippedItems = [];

            foreach ($newItems as $index => $item) {
                $menuItem = MenuItem::find($item['menu_item_id']);

                if (!$menuItem) {
                    Log::warning('Send to Kitchen - Menu item not found, skipping', [
                        'menu_item_id' => $item['menu_item_id'],
                        'order_id' => $order->id,
                    ]);
                    $skippedItems[] = $item['menu_item_id'];
                    continue;
                }

                // Set order_status from request, default to 0 (HOLD) if not provided
                // Set sequence incrementally (lower = higher priority)
                $orderItem = OrderItem::create([
                    'order_id' => $order->id,
                    'check_id' => $check->id,
                    'menu_item_id' => $item['menu_item_id'],
                    'qty' => $item['qty'],
                    'unit_price' => $item['unit_price'],
                    'instructions' => $item['instructions'] ?? '',
                    'order_status' => $item['order_status'] ?? 0, // Accept from request: 0=HOLD, 1=FIRE, 2=TEMP, 3=VOID
                    'customer_no' => $item['customer_no'] ?? 1, // Default to customer 1 if not provided, 0 = common shared box
                    'sequence' => $maxSequence + $index + 1, // Increment sequence for each new item
                    'employee_id' => $employee->id, // Set employee_id from authenticated employee (token user)
                ]);

                // Attach decisions if provided
                if (isset($item['decisions']) && is_array($item['decisions'])) {
                    $decisionData = [];
                    foreach ($item['decisions'] as $decision) {
                        $decisionData[$decision['decision_id']] = [
                            'employee_id' => $employee->id, // Set employee_id from authenticated employee (token user)
                        ];
                    }
                    $orderItem->decisions()->sync($decisionData);
                }

                // Attach modifiers if provided
                if (isset($item['modifiers']) && is_array($item['modifiers'])) {
                    $modifierData = [];
                    foreach ($item['modifiers'] as $modifier) {
                        $modifierData[$modifier['modifier_id']] = [
                            'order_id' => $order->id,
                            'qty' => $modifier['qty'],
                            'price' => $modifier['price'],
                            'employee_id' => $employee->id, // Set employee_id from authenticated employee (token user)
                        ];
                    }
                    $orderItem->modifiers()->sync($modifierData);
                }

                $orderItem->load(['menuItem', 'decisions', 'modifiers']);
                $createdOrderItems[] = $orderItem;
                $newItemsForTickets[] = $orderItem;

                Log::debug('Send to Kitchen - Order item created', [
                    'order_item_id' => $orderItem->id,
                    'order_id' => $order->id,
                    'menu_item_id' => $item['menu_item_id'],
                    'qty' => $item['qty'],
                    'has_decisions' => !empty($item['decisions']),
                    'has_modifiers' => !empty($item['modifiers']),
                ]);
            }

            if (!empty($skippedItems)) {
                Log::warning('Send to Kitchen - Some items were skipped', [
                    'order_id' => $order->id,
                    'skipped_menu_item_ids' => $skippedItems,
                ]);
            }

            Log::info('Send to Kitchen - Order items created', [
                'order_id' => $order->id,
                'created_items_count' => count($createdOrderItems),
                'skipped_items_count' => count($skippedItems),
            ]);

            // Update existing order items (orderItemId > 0)
            $updatedOrderItems = [];
            $notFoundItems = [];

            foreach ($updateItems as $item) {
                $orderItemId = (int)$item['orderItemId'];

                // Find the existing order item
                $orderItem = OrderItem::where('id', $orderItemId)
                    ->where('check_id', $check->id)
                    ->where('order_id', $order->id)
                    ->first();

                if (!$orderItem) {
                    Log::warning('Send to Kitchen - Order item not found for update', [
                        'order_item_id' => $orderItemId,
                        'order_id' => $order->id,
                        'check_id' => $check->id,
                    ]);
                    $notFoundItems[] = $orderItemId;
                    continue;
                }

                // Update order item fields
                $orderItem->update([
                    'menu_item_id' => $item['menu_item_id'],
                    'qty' => $item['qty'],
                    'unit_price' => $item['unit_price'],
                    'instructions' => $item['instructions'] ?? '',
                    'order_status' => $item['order_status'] ?? $orderItem->order_status,
                    'customer_no' => $item['customer_no'] ?? $orderItem->customer_no,
                    'employee_id' => $employee->id, // Update employee_id from authenticated employee (token user)
                ]);

                // Update decisions if provided
                if (isset($item['decisions']) && is_array($item['decisions'])) {
                    $decisionData = [];
                    foreach ($item['decisions'] as $decision) {
                        $decisionData[$decision['decision_id']] = [
                            'employee_id' => $employee->id, // Set employee_id from authenticated employee (token user)
                        ];
                    }
                    $orderItem->decisions()->sync($decisionData);
                }

                // Update modifiers if provided
                if (isset($item['modifiers']) && is_array($item['modifiers'])) {
                    $modifierData = [];
                    foreach ($item['modifiers'] as $modifier) {
                        $modifierData[$modifier['modifier_id']] = [
                            'order_id' => $order->id,
                            'qty' => $modifier['qty'],
                            'price' => $modifier['price'],
                            'employee_id' => $employee->id, // Set employee_id from authenticated employee (token user)
                        ];
                    }
                    $orderItem->modifiers()->sync($modifierData);
                }

                $orderItem->load(['menuItem', 'decisions', 'modifiers']);
                $updatedOrderItems[] = $orderItem;
                $newItemsForTickets[] = $orderItem; // Include updated items in kitchen tickets

                Log::debug('Send to Kitchen - Order item updated', [
                    'order_item_id' => $orderItem->id,
                    'order_id' => $order->id,
                    'menu_item_id' => $item['menu_item_id'],
                    'qty' => $item['qty'],
                    'has_decisions' => !empty($item['decisions']),
                    'has_modifiers' => !empty($item['modifiers']),
                ]);
            }

            if (!empty($notFoundItems)) {
                Log::warning('Send to Kitchen - Some items were not found for update', [
                    'order_id' => $order->id,
                    'not_found_order_item_ids' => $notFoundItems,
                ]);
            }

            Log::info('Send to Kitchen - Order items updated', [
                'order_id' => $order->id,
                'updated_items_count' => count($updatedOrderItems),
                'not_found_items_count' => count($notFoundItems),
            ]);

            // Update orders.customer to reflect the maximum customer_no from all order items
            // This handles cases where a new guest/frame is added (e.g., customer_no: 3)
            $maxCustomerNo = OrderItem::where('order_id', $order->id)->max('customer_no') ?? 1;

            if ($order->customer < $maxCustomerNo) {
                $oldCustomer = $order->customer;
                $order->update(['customer' => $maxCustomerNo]);
                Log::info('Send to Kitchen - Order customer count updated', [
                    'order_id' => $order->id,
                    'old_customer' => $oldCustomer,
                    'new_customer' => $maxCustomerNo,
                ]);
            }

            // Update order status to sent_to_kitchen if not already
            if ($order->status !== 'sent_to_kitchen') {
                $oldStatus = $order->status;
                $order->update(['status' => 'sent_to_kitchen']);
                Log::info('Send to Kitchen - Order status updated', [
                    'order_id' => $order->id,
                    'old_status' => $oldStatus,
                    'new_status' => 'sent_to_kitchen',
                ]);
            }

            // Generate kitchen tickets for new items only
            $printerRoutes = [];
            foreach ($newItemsForTickets as $orderItem) {
                $menuItem = $orderItem->menuItem;

                if ($menuItem && $menuItem->printer_route_id) {
                    $printerRoute = $menuItem->printerRoute;

                    if (!isset($printerRoutes[$printerRoute->id])) {
                        $printerRoutes[$printerRoute->id] = [
                            'printer' => $printerRoute->printer,
                            'items' => []
                        ];
                    }

                    $printerRoutes[$printerRoute->id]['items'][] = [
                        'order_item' => $orderItem,
                        'menu_item' => $menuItem,
                        'qty' => $orderItem->qty,
                        'instructions' => $orderItem->instructions,
                        'modifiers' => $orderItem->modifiers,
                        'decisions' => $orderItem->decisions,
                    ];
                }
            }

            // Create kitchen tickets
            $createdTickets = [];
            foreach ($printerRoutes as $printerRouteId => $data) {
                if ($data['printer'] && $data['printer']->is_kitchen) {
                    $ticket = KitchenTicket::create([
                        'business_id' => $businessId,
                        'order_id' => $order->id,
                        'ticket_type' => 'new',
                        'printer_id' => $data['printer']->id,
                        'generated_at' => now(),
                    ]);

                    $ticket->items_data = $data['items'];
                    $createdTickets[] = $ticket;

                    Log::info('Send to Kitchen - Kitchen ticket created', [
                        'ticket_id' => $ticket->id,
                        'order_id' => $order->id,
                        'printer_id' => $data['printer']->id,
                        'printer_route_id' => $printerRouteId,
                        'items_count' => count($data['items']),
                    ]);
                } else {
                    Log::warning('Send to Kitchen - Printer is not a kitchen printer, skipping ticket', [
                        'printer_id' => $data['printer']?->id,
                        'printer_route_id' => $printerRouteId,
                        'is_kitchen' => $data['printer']?->is_kitchen ?? false,
                    ]);
                }
            }

            Log::info('Send to Kitchen - Kitchen tickets generation completed', [
                'order_id' => $order->id,
                'tickets_created' => count($createdTickets),
                'printer_routes_processed' => count($printerRoutes),
            ]);

            // Get total items count for this check (after creating/updating items)
            $totalItemsCount = OrderItem::where('check_id', $check->id)->count();

            // Update table with is_table_locked and current_served_by_id if provided
            if (isset($validated['is_table_locked'])) {
                $tableUpdateData = [
                    'is_table_locked' => (bool) $validated['is_table_locked'],
                    'current_served_by_id' => $employee->id,
                ];
                RestaurantTable::where('id', $order->table_id)->update($tableUpdateData);
                Log::info('Send to Kitchen - Table updated with locking info', [
                    'table_id' => $order->table_id,
                    'is_table_locked' => $validated['is_table_locked'],
                    'current_served_by_id' => $employee->id,
                ]);
            }

            // Reload order with table and current served by
            $order->load(['table.currentServedBy', 'createdByEmployee']);
            $table = $order->table;
            $currentServedBy = $table->currentServedBy ?? null;
            $currentServedByName = $currentServedBy
                ? trim($currentServedBy->first_name . ' ' . $currentServedBy->last_name)
                : null;

            $responseData = [
                'order' => $order,
                'new_items' => $createdOrderItems,
                'new_items_count' => count($createdOrderItems),
                'updated_items' => $updatedOrderItems,
                'updated_items_count' => count($updatedOrderItems),
                'total_items_count' => $totalItemsCount,
                'kitchen_tickets' => $createdTickets,
                'is_table_locked' => (bool) ($table->is_table_locked ?? true),
                'current_served_by_id' => $table->current_served_by_id,
                'current_served_by_name' => $currentServedByName,
            ];

            Log::info('Send to Kitchen - Success', [
                'order_id' => $order->id,
                'new_items_count' => count($createdOrderItems),
                'updated_items_count' => count($updatedOrderItems),
                'total_items_count' => $responseData['total_items_count'],
                'kitchen_tickets_count' => count($createdTickets),
                'employee_id' => $employee->id,
            ]);

            Log::info('========================================');
            Log::info('Send to Kitchen - REQUEST COMPLETED SUCCESSFULLY');
            Log::info('========================================');

            return $this->successResponse($responseData, 'Order sent to kitchen successfully');
        } catch (\Illuminate\Validation\ValidationException $e) {
            // Re-throw validation exceptions (already logged above)
            throw $e;
        } catch (\Exception $e) {
            Log::error('========================================');
            Log::error('Send to Kitchen - EXCEPTION OCCURRED');
            Log::error('========================================');
            Log::error('Exception Type: ' . get_class($e));
            Log::error('Exception Message: ' . $e->getMessage());
            Log::error('Exception File: ' . $e->getFile());
            Log::error('Exception Line: ' . $e->getLine());
            Log::error('Stack Trace:', [
                'trace' => $e->getTraceAsString(),
            ]);
            Log::error('Request Data at time of exception:', [
                'order_id' => $request->input('order_id'),
                'order_ticket_id' => $request->input('order_ticket_id'),
                'items_count' => count($request->input('items', [])),
            ]);
            Log::error('========================================');

            return $this->errorResponse('An error occurred while sending order to kitchen: ' . $e->getMessage(), 500);
        }
    }

    /**
     * @OA\Post(
     *     path="/pos/order_item_status",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 6"},
     *     summary="Update Order Item Status - Update order_status and sequence",
     *     description="Update order items' order_status (0=HOLD, 1=FIRE, 2=TEMP, 3=VOID) and optionally update their sequence for priority ordering. Can update all items or specific items by order_item_id.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "order_status"},
     *             @OA\Property(
     *                 property="order_ticket_id",
     *                 type="string",
     *                 example="ORD-20251121-XJROYU",
     *                 description="Order ticket ID (format: ORD-YYYYMMDD-XXXXX)"
     *             ),
     *             @OA\Property(
     *                 property="order_status",
     *                 type="integer",
     *                 example=1,
     *                 description="Order status to set: 0=HOLD, 1=FIRE, 2=TEMP, 3=VOID",
     *                 enum={0, 1, 2, 3}
     *             ),
     *             @OA\Property(
     *                 property="order_item_ids",
     *                 type="array",
     *                 description="Optional: Array of specific order_item IDs to update. If not provided, all items will be updated.",
     *                 @OA\Items(type="integer", example=1)
     *             ),
     *             @OA\Property(
     *                 property="items_sequence",
     *                 type="array",
     *                 description="Optional: Array of objects to update sequence for items. Each object should have order_item_id and sequence.",
     *                 @OA\Items(
     *                     type="object",
     *                     @OA\Property(property="order_item_id", type="integer", example=1, description="Order item ID"),
     *                     @OA\Property(property="sequence", type="integer", example=0, description="New sequence value (lower = higher priority)")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Order items status updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Order items status updated successfully"),
     *             @OA\Property(
     *                 property="data",
     *                 type="object",
     *                 @OA\Property(property="updated_items_count", type="integer", example=3, description="Number of items that were updated"),
     *                 @OA\Property(property="updated_sequences_count", type="integer", example=3, description="Number of items that had sequence updated"),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU"),
     *                 @OA\Property(
     *                     property="order_items",
     *                     type="array",
     *                     description="Updated order items with current order_status and sequence",
     *                     @OA\Items(
     *                         type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="menu_item_id", type="integer", example=5),
     *                         @OA\Property(property="qty", type="integer", example=2),
     *                         @OA\Property(property="unit_price", type="number", example=210.00),
     *                         @OA\Property(property="order_status", type="integer", example=1, description="Order status: 0=HOLD, 1=FIRE, 2=TEMP, 3=VOID"),
     *                         @OA\Property(property="sequence", type="integer", example=0, description="Priority sequence (lower = higher priority)"),
     *                         @OA\Property(property="customer_no", type="integer", example=1),
     *                         @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-23T06:17:11.000000Z"),
     *                         @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-23T06:17:11.000000Z")
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order not found"
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Order does not belong to business"
     *     )
     * )
     */
    public function orderItemStatus(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'order_status' => 'required|integer|in:0,1,2,3',
            'order_item_ids' => 'nullable|array',
            'order_item_ids.*' => 'integer|exists:order_items,id',
            'items_sequence' => 'nullable|array',
            'items_sequence.*.order_item_id' => 'required_with:items_sequence|integer|exists:order_items,id',
            'items_sequence.*.sequence' => 'required_with:items_sequence|integer|min:0',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        // Build query for items to update
        $itemsQuery = OrderItem::where('check_id', $check->id);

        // If specific order_item_ids provided, filter by them
        if (!empty($validated['order_item_ids'])) {
            $itemsQuery->whereIn('id', $validated['order_item_ids']);
        }

        // Update order_status to the provided value (0=HOLD, 1=FIRE, 2=TEMP, 3=VOID)
        $updatedCount = $itemsQuery->update(['order_status' => $validated['order_status']]);

        // Update sequences if provided
        $updatedSequencesCount = 0;
        if (!empty($validated['items_sequence'])) {
            foreach ($validated['items_sequence'] as $seqData) {
                $orderItem = OrderItem::where('id', $seqData['order_item_id'])
                    ->where('check_id', $check->id)
                    ->first();

                if ($orderItem) {
                    $orderItem->update(['sequence' => $seqData['sequence']]);
                    $updatedSequencesCount++;
                }
            }
        }

        // Get all order items for this check (with updated order_status and sequence)
        $orderItems = OrderItem::where('check_id', $check->id)
            ->with(['menuItem', 'decisions', 'modifiers'])
            ->orderBy('sequence', 'asc') // Order by sequence (lower = higher priority)
            ->get();

        return $this->successResponse([
            'order' => $order->load(['table', 'createdByEmployee']),
            'updated_items_count' => $updatedCount,
            'updated_sequences_count' => $updatedSequencesCount,
            'order_items' => $orderItems,
            'order_ticket_id' => $order->order_ticket_id,
        ], 'Order items status updated successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/order_item_void",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 6"},
     *     summary="Void Order Items - Void items with undo functionality",
     *     description="Void order items (set order_status to 3) and store old status in void_items table for undo functionality. Can void specific items or undo voided items by id or undo all.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "action"},
     *             @OA\Property(
     *                 property="order_ticket_id",
     *                 type="string",
     *                 example="ORD-20251121-XJROYU",
     *                 description="Order ticket ID (format: ORD-YYYYMMDD-XXXXX)"
     *             ),
     *             @OA\Property(
     *                 property="action",
     *                 type="string",
     *                 enum={"void", "undo", "undo_all"},
     *                 example="void",
     *                 description="Action to perform: void = void items, undo = undo specific items, undo_all = undo all voided items"
     *             ),
     *             @OA\Property(
     *                 property="order_item_ids",
     *                 type="array",
     *                 description="Required for 'void' and 'undo' actions: Array of order_item IDs to void or undo",
     *                 @OA\Items(type="integer", example=1)
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Action completed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Order items voided successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="updated_items_count", type="integer", example=2),
     *                 @OA\Property(property="order_items", type="array", @OA\Items(type="object")),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Validation error"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or items not found"
     *     )
     *     )
     * )
     */
    public function orderItemVoid(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'action' => 'required|string|in:void,undo,undo_all',
            'order_item_ids' => 'required_if:action,void|required_if:action,undo|nullable|array',
            'order_item_ids.*' => 'integer|exists:order_items,id',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        $action = $validated['action'];
        $updatedCount = 0;

        if ($action === 'void') {
            // Void items: Store old status and set to void (3)
            if (empty($validated['order_item_ids'])) {
                return $this->errorResponse('order_item_ids is required for void action', 400);
            }

            $itemsToVoid = OrderItem::where('check_id', $check->id)
                ->whereIn('id', $validated['order_item_ids'])
                ->where('order_status', '!=', 3) // Don't void already voided items
                ->get();

            if ($itemsToVoid->isEmpty()) {
                return $this->errorResponse('No valid items found to void', 404);
            }

            DB::beginTransaction();
            try {
                foreach ($itemsToVoid as $item) {
                    // Check if already in void_items (shouldn't happen, but safety check)
                    $existingVoid = VoidItem::where('order_id', $order->id)
                        ->where('item_id', $item->id)
                        ->first();

                    if (!$existingVoid) {
                        // Store old status in void_items table
                        VoidItem::create([
                            'order_id' => $order->id,
                            'item_id' => $item->id,
                            'old_order_status' => $item->order_status,
                        ]);
                    }

                    // Update order_status to 3 (VOID)
                    $item->update(['order_status' => 3]);
                    $updatedCount++;
                }

                DB::commit();
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to void items: ' . $e->getMessage(), 500);
            }
        } elseif ($action === 'undo') {
            // Undo specific items: Restore old status and remove from void_items
            if (empty($validated['order_item_ids'])) {
                return $this->errorResponse('order_item_ids is required for undo action', 400);
            }

            $itemsToUndo = OrderItem::where('check_id', $check->id)
                ->whereIn('id', $validated['order_item_ids'])
                ->where('order_status', 3) // Only undo voided items
                ->get();

            if ($itemsToUndo->isEmpty()) {
                return $this->errorResponse('No voided items found to undo', 404);
            }

            DB::beginTransaction();
            try {
                foreach ($itemsToUndo as $item) {
                    // Find the void_item record
                    $voidItem = VoidItem::where('order_id', $order->id)
                        ->where('item_id', $item->id)
                        ->first();

                    if ($voidItem) {
                        // Restore old status
                        $item->update(['order_status' => $voidItem->old_order_status]);

                        // Remove from void_items table
                        $voidItem->delete();
                        $updatedCount++;
                    }
                }

                DB::commit();
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to undo items: ' . $e->getMessage(), 500);
            }
        } elseif ($action === 'undo_all') {
            // Undo all voided items for this order
            $itemsToUndo = OrderItem::where('check_id', $check->id)
                ->where('order_status', 3) // Only voided items
                ->get();

            if ($itemsToUndo->isEmpty()) {
                return $this->errorResponse('No voided items found to undo', 404);
            }

            DB::beginTransaction();
            try {
                foreach ($itemsToUndo as $item) {
                    // Find the void_item record
                    $voidItem = VoidItem::where('order_id', $order->id)
                        ->where('item_id', $item->id)
                        ->first();

                    if ($voidItem) {
                        // Restore old status
                        $item->update(['order_status' => $voidItem->old_order_status]);

                        // Remove from void_items table
                        $voidItem->delete();
                        $updatedCount++;
                    }
                }

                DB::commit();
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to undo all items: ' . $e->getMessage(), 500);
            }
        }

        // Get all order items for this check (with updated order_status)
        $orderItems = OrderItem::where('check_id', $check->id)
            ->with(['menuItem', 'decisions', 'modifiers'])
            ->orderBy('sequence', 'asc')
            ->get();

        $message = match ($action) {
            'void' => 'Order items voided successfully',
            'undo' => 'Order items undone successfully',
            'undo_all' => 'All voided items undone successfully',
            default => 'Action completed successfully'
        };

        return $this->successResponse([
            'order' => $order->load(['table', 'createdByEmployee']),
            'updated_items_count' => $updatedCount,
            'order_items' => $orderItems,
            'order_ticket_id' => $order->order_ticket_id,
        ], $message);
    }

    /**
     * @OA\Post(
     *     path="/pos/order_item_discount",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 6"},
     *     summary="Apply/Edit/Remove Discount on Order Items",
     *     description="Apply, edit, or remove discount (percentage or fixed) on order items. Can apply to multiple items, edit existing discounts, or remove discounts from specific items or all items.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "action"},
     *             @OA\Property(
     *                 property="order_ticket_id",
     *                 type="string",
     *                 example="ORD-20251121-XJROYU",
     *                 description="Order ticket ID (format: ORD-YYYYMMDD-XXXXX)"
     *             ),
     *             @OA\Property(
     *                 property="action",
     *                 type="string",
     *                 enum={"apply", "edit", "remove", "remove_all"},
     *                 example="apply",
     *                 description="Action to perform: apply = apply discount, edit = edit existing discount, remove = remove discount from specific items, remove_all = remove all discounts"
     *             ),
     *             @OA\Property(
     *                 property="order_item_ids",
     *                 type="array",
     *                 description="Required for 'apply', 'edit', and 'remove' actions: Array of order_item IDs",
     *                 @OA\Items(type="integer", example=1)
     *             ),
     *             @OA\Property(
     *                 property="discount_type",
     *                 type="string",
     *                 enum={"percentage", "fixed"},
     *                 example="percentage",
     *                 description="Required for 'apply' and 'edit' actions: Type of discount (percentage or fixed amount)"
     *             ),
     *             @OA\Property(
     *                 property="discount_value",
     *                 type="number",
     *                 example=10.00,
     *                 description="Required for 'apply' and 'edit' actions: For percentage (0-100), for fixed (amount in currency)"
     *             ),
     *             @OA\Property(
     *                 property="discount_reason",
     *                 type="string",
     *                 nullable=true,
     *                 example="Customer complaint",
     *                 description="Optional: Discount reason text (max 500 characters)"
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Action completed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Discount applied successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="updated_items_count", type="integer", example=2),
     *                 @OA\Property(property="order_items", type="array", @OA\Items(type="object")),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Validation error"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or items not found"
     *     )
     *     )
     * )
     */
    public function orderItemDiscount(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'action' => 'required|string|in:apply,edit,remove,remove_all',
            'order_item_ids' => 'required_if:action,apply|required_if:action,edit|required_if:action,remove|nullable|array',
            'order_item_ids.*' => 'integer|exists:order_items,id',
            'discount_type' => 'required_if:action,apply|required_if:action,edit|nullable|string|in:percentage,fixed',
            'discount_value' => 'required_if:action,apply|required_if:action,edit|nullable|numeric|min:0',
            'discount_reason' => 'nullable|string|max:500',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        $action = $validated['action'];
        $updatedCount = 0;

        if ($action === 'apply') {
            // Apply discount to items
            if (empty($validated['order_item_ids'])) {
                return $this->errorResponse('order_item_ids is required for apply action', 400);
            }

            if (empty($validated['discount_type']) || empty($validated['discount_value'])) {
                return $this->errorResponse('discount_type and discount_value are required for apply action', 400);
            }

            // Validate percentage range
            if ($validated['discount_type'] === 'percentage' && $validated['discount_value'] > 100) {
                return $this->errorResponse('Percentage discount cannot exceed 100', 400);
            }

            $itemsToDiscount = OrderItem::where('check_id', $check->id)
                ->whereIn('id', $validated['order_item_ids'])
                ->get();

            if ($itemsToDiscount->isEmpty()) {
                return $this->errorResponse('No valid items found to apply discount', 404);
            }

            DB::beginTransaction();
            try {
                // Update order with discount_reason if provided
                if (isset($validated['discount_reason'])) {
                    $order->update([
                        'discount_reason' => $validated['discount_reason'],
                    ]);
                }

                foreach ($itemsToDiscount as $item) {
                    $discountType = $validated['discount_type'];
                    $discountValue = $validated['discount_value'];
                    $discountAmount = 0;

                    // Calculate discount amount
                    if ($discountType === 'percentage') {
                        // Calculate percentage discount: (unit_price * qty) * (discount_value / 100)
                        $itemTotal = $item->unit_price * $item->qty;
                        $discountAmount = ($itemTotal * $discountValue) / 100;
                    } else {
                        // Fixed discount: discount_value is the fixed amount
                        $itemTotal = $item->unit_price * $item->qty;
                        $discountAmount = min($discountValue, $itemTotal); // Don't exceed item total
                    }

                    // Update order item with discount
                    $item->update([
                        'discount_type' => $discountType,
                        'discount_value' => $discountValue,
                        'discount_amount' => round($discountAmount, 2),
                    ]);

                    $updatedCount++;
                }

                DB::commit();
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to apply discount: ' . $e->getMessage(), 500);
            }
        } elseif ($action === 'edit') {
            // Edit existing discount on items
            if (empty($validated['order_item_ids'])) {
                return $this->errorResponse('order_item_ids is required for edit action', 400);
            }

            if (empty($validated['discount_type']) || empty($validated['discount_value'])) {
                return $this->errorResponse('discount_type and discount_value are required for edit action', 400);
            }

            // Validate percentage range
            if ($validated['discount_type'] === 'percentage' && $validated['discount_value'] > 100) {
                return $this->errorResponse('Percentage discount cannot exceed 100', 400);
            }

            $itemsToEdit = OrderItem::where('check_id', $check->id)
                ->whereIn('id', $validated['order_item_ids'])
                ->where('discount_type', '!=', '') // Only items with existing discount
                ->where('discount_type', '!=', null)
                ->get();

            if ($itemsToEdit->isEmpty()) {
                return $this->errorResponse('No items with existing discount found to edit', 404);
            }

            DB::beginTransaction();
            try {
                // Update order with discount_reason if provided
                if (isset($validated['discount_reason'])) {
                    $order->update([
                        'discount_reason' => $validated['discount_reason'],
                    ]);
                }

                foreach ($itemsToEdit as $item) {
                    $discountType = $validated['discount_type'];
                    $discountValue = $validated['discount_value'];
                    $discountAmount = 0;

                    // Calculate discount amount
                    if ($discountType === 'percentage') {
                        // Calculate percentage discount: (unit_price * qty) * (discount_value / 100)
                        $itemTotal = $item->unit_price * $item->qty;
                        $discountAmount = ($itemTotal * $discountValue) / 100;
                    } else {
                        // Fixed discount: discount_value is the fixed amount
                        $itemTotal = $item->unit_price * $item->qty;
                        $discountAmount = min($discountValue, $itemTotal); // Don't exceed item total
                    }

                    // Update order item with new discount
                    $item->update([
                        'discount_type' => $discountType,
                        'discount_value' => $discountValue,
                        'discount_amount' => round($discountAmount, 2),
                    ]);

                    $updatedCount++;
                }

                DB::commit();
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to edit discount: ' . $e->getMessage(), 500);
            }
        } elseif ($action === 'remove') {
            // Remove discount from specific items
            if (empty($validated['order_item_ids'])) {
                return $this->errorResponse('order_item_ids is required for remove action', 400);
            }

            $itemsToRemoveDiscount = OrderItem::where('check_id', $check->id)
                ->whereIn('id', $validated['order_item_ids'])
                ->where('discount_type', '!=', '') // Only items with discount
                ->where('discount_type', '!=', null)
                ->get();

            if ($itemsToRemoveDiscount->isEmpty()) {
                return $this->errorResponse('No items with discount found to remove', 404);
            }

            DB::beginTransaction();
            try {
                // Check if all items with discount are being removed
                $allItemsWithDiscount = OrderItem::where('check_id', $check->id)
                    ->where('discount_type', '!=', '')
                    ->where('discount_type', '!=', null)
                    ->count();

                $itemsBeingRemoved = count($itemsToRemoveDiscount);

                // If all discounted items are being removed, clear discount_reason from order
                if ($allItemsWithDiscount === $itemsBeingRemoved) {
                    $order->update(['discount_reason' => null]);
                }

                foreach ($itemsToRemoveDiscount as $item) {
                    $item->update([
                        'discount_type' => '',
                        'discount_value' => 0.00,
                        'discount_amount' => 0.00,
                    ]);

                    $updatedCount++;
                }

                DB::commit();
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to remove discount: ' . $e->getMessage(), 500);
            }
        } elseif ($action === 'remove_all') {
            // Remove all discounts from all items in this order
            $itemsToRemoveDiscount = OrderItem::where('check_id', $check->id)
                ->where('discount_type', '!=', '') // Only items with discount
                ->where('discount_type', '!=', null)
                ->get();

            if ($itemsToRemoveDiscount->isEmpty()) {
                return $this->errorResponse('No items with discount found to remove', 404);
            }

            DB::beginTransaction();
            try {
                // Clear discount_reason from order
                $order->update(['discount_reason' => null]);

                foreach ($itemsToRemoveDiscount as $item) {
                    $item->update([
                        'discount_type' => '',
                        'discount_value' => 0.00,
                        'discount_amount' => 0.00,
                    ]);

                    $updatedCount++;
                }

                DB::commit();
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to remove all discounts: ' . $e->getMessage(), 500);
            }
        }

        // Get all order items for this check (with updated discount info)
        $orderItems = OrderItem::where('check_id', $check->id)
            ->with(['menuItem.menuType', 'menuItem.modifierGroups.modifiers', 'menuItem.decisionGroups.decisions', 'decisions', 'modifiers'])
            ->orderBy('sequence', 'asc')
            ->get();

        // Format order items with proper discount field types
        $formattedOrderItems = $orderItems->map(function ($orderItem) {
            $orderItemArray = $orderItem->toArray();

            // Discount fields are handled by model casts (decimal:2 returns strings like "0.00")
            $orderItemArray['discount_type'] = $orderItem->discount_type;
            $orderItemArray['discount_value'] = $orderItem->discount_value;
            $orderItemArray['discount_amount'] = $orderItem->discount_amount;

            if ($orderItem->menuItem) {
                $menuItem = $orderItem->menuItem;

                // Format menu_item with enhanced structure
                $modifierGroups = $menuItem->relationLoaded('modifierGroups')
                    ? $this->formatModifierGroups($menuItem->modifierGroups)
                    : [];
                $decisionGroups = $menuItem->relationLoaded('decisionGroups')
                    ? $this->formatDecisionGroups($menuItem->decisionGroups)
                    : [];

                $orderItemArray['menu_item'] = [
                    'id' => $menuItem->id,
                    'business_id' => $menuItem->business_id,
                    'menu_category_id' => $menuItem->menu_category_id,
                    'menu_type_id' => $menuItem->menu_type_id,
                    'name' => $menuItem->name,
                    'price_cash' => (float) $menuItem->price_cash,
                    'price_card' => (float) $menuItem->price_card,
                    'image' => $menuItem->image ?? '',
                    'icon_image' => $menuItem->icon_image ?? '',
                    'is_active' => (bool) $menuItem->is_active,
                    'is_auto_fire' => (bool) $menuItem->is_auto_fire,
                    'is_open_item' => (bool) $menuItem->is_open_item,
                    'printer_route_id' => $menuItem->printer_route_id ?? 0,
                    'created_at' => $menuItem->created_at,
                    'updated_at' => $menuItem->updated_at,
                    'menu_type' => $menuItem->relationLoaded('menuType') && $menuItem->menuType ? [
                        'id' => $menuItem->menuType->id,
                        'name' => $menuItem->menuType->name,
                        'description' => $menuItem->menuType->description ?? '',
                    ] : null,
                    'modifier_groups' => $modifierGroups,
                    'decision_groups' => $decisionGroups,
                ];
            }

            return $orderItemArray;
        });

        $message = match ($action) {
            'apply' => 'Discount applied successfully',
            'edit' => 'Discount updated successfully',
            'remove' => 'Discount removed successfully',
            'remove_all' => 'All discounts removed successfully',
            default => 'Action completed successfully'
        };

        return $this->successResponse([
            'order' => $order->load(['table', 'createdByEmployee']),
            'updated_items_count' => $updatedCount,
            'order_items' => $formattedOrderItems->values(),
            'order_ticket_id' => $order->order_ticket_id,
        ], $message);
    }

    /**
     * @OA\Post(
     *     path="/pos/order_item_removed",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 6"},
     *     summary="Remove Order Item - Remove order items with TEMP status",
     *     description="Remove (delete) order items that have order_status = 2 (TEMP). Can remove all TEMP items or specific items by order_item_id. Only items with order_status = 2 will be removed.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id"},
     *             @OA\Property(
     *                 property="order_ticket_id",
     *                 type="string",
     *                 example="ORD-20251121-XJROYU",
     *                 description="Order ticket ID (format: ORD-YYYYMMDD-XXXXX)"
     *             ),
     *             @OA\Property(
     *                 property="order_item_ids",
     *                 type="array",
     *                 description="Optional: Array of specific order_item IDs to remove. If not provided, all TEMP items (order_status = 2) will be removed.",
     *                 @OA\Items(type="integer", example=1)
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Order items removed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Order items removed successfully"),
     *             @OA\Property(
     *                 property="data",
     *                 type="object",
     *                 @OA\Property(property="removed_items_count", type="integer", example=2, description="Number of TEMP items that were removed"),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU"),
     *                 @OA\Property(
     *                     property="order_items",
     *                     type="array",
     *                     description="Remaining order items after removal",
     *                     @OA\Items(
     *                         type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="menu_item_id", type="integer", example=5),
     *                         @OA\Property(property="qty", type="integer", example=2),
     *                         @OA\Property(property="unit_price", type="number", example=210.00),
     *                         @OA\Property(property="order_status", type="integer", example=1, description="Order status: 0=HOLD, 1=FIRE, 2=TEMP, 3=VOID"),
     *                         @OA\Property(property="sequence", type="integer", example=0, description="Priority sequence (lower = higher priority)"),
     *                         @OA\Property(property="customer_no", type="integer", example=1),
     *                         @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-23T06:17:11.000000Z"),
     *                         @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-23T06:17:11.000000Z")
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order not found"
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Order does not belong to business"
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad Request - No TEMP items found to remove"
     *     )
     * )
     */
    public function orderItemRemoved(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'order_item_ids' => 'nullable|array',
            'order_item_ids.*' => 'integer|exists:order_items,id',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        // Build query for items to remove - only items with order_status = 2 (TEMP)
        $itemsQuery = OrderItem::where('check_id', $check->id)
            ->where('order_status', 2); // Only TEMP items

        // If specific order_item_ids provided, filter by them
        if (!empty($validated['order_item_ids'])) {
            $itemsQuery->whereIn('id', $validated['order_item_ids']);
        }

        // Get items that will be deleted before deletion
        $itemsToDelete = $itemsQuery->get();

        if ($itemsToDelete->isEmpty()) {
            return $this->errorResponse('No TEMP items (order_status = 2) found to remove', 400);
        }

        // Delete the items (this will also cascade delete related pivot table entries)
        $removedCount = 0;
        foreach ($itemsToDelete as $item) {
            $item->delete();
            $removedCount++;
        }

        // Get all remaining order items for this check
        $orderItems = OrderItem::where('check_id', $check->id)
            ->with(['menuItem', 'decisions', 'modifiers'])
            ->orderBy('sequence', 'asc') // Order by sequence (lower = higher priority)
            ->get();

        return $this->successResponse([
            'removed_items_count' => $removedCount,
            'order_items' => $orderItems,
            'order_ticket_id' => $order->order_ticket_id,
        ], 'Order items removed successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/order-item/update-sequence",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 6"},
     *     summary="Update Order Item Sequence",
     *     description="Update the sequence (priority) of a specific order item. Lower sequence number = higher priority. Used for drag-and-drop reordering in the status screen.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "order_item_id", "sequence"},
     *             @OA\Property(
     *                 property="order_ticket_id",
     *                 type="string",
     *                 example="ORD-20251121-XJROYU",
     *                 description="Order ticket ID (format: ORD-YYYYMMDD-XXXXX)"
     *             ),
     *             @OA\Property(
     *                 property="order_item_id",
     *                 type="integer",
     *                 example=1,
     *                 description="Order item ID to update"
     *             ),
     *             @OA\Property(
     *                 property="sequence",
     *                 type="integer",
     *                 example=0,
     *                 description="New sequence value. Lower number = higher priority (displayed first). Minimum: 0"
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Sequence updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Sequence updated successfully"),
     *             @OA\Property(
     *                 property="data",
     *                 type="object",
     *                 @OA\Property(
     *                     property="order_item",
     *                     type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="sequence", type="integer", example=0)
     *                 ),
     *                 @OA\Property(property="sequence", type="integer", example=0)
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or Order Item not found"
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Order does not belong to business"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Validation error"
     *     )
     * )
     */
    public function updateItemSequence(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'order_item_id' => 'required|exists:order_items,id',
            'sequence' => 'required|integer|min:0',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        $orderItem = \App\Models\OrderItem::where('id', $validated['order_item_id'])
            ->whereHas('check.order', function ($query) use ($order) {
                $query->where('id', $order->id);
            })
            ->first();

        if (!$orderItem) {
            return $this->notFoundResponse('Order item not found');
        }

        $orderItem->update(['sequence' => $validated['sequence']]);

        return $this->successResponse([
            'order_item' => $orderItem,
            'sequence' => $orderItem->sequence,
        ], 'Sequence updated successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/get-config-data",
     *     tags={"POS API - Payment"},
     *     summary="Get Configuration Data (Public)",
     *     description="Get configuration values for tax, fee, and gratuity from settings tables. Public endpoint - no authentication required.",
     *     @OA\Parameter(
     *         name="business_id",
     *         in="query",
     *         required=false,
     *         description="Business ID (defaults to 1 if not provided)",
     *         @OA\Schema(type="integer", default=1)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Configuration data retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="tax_value", type="string", example="5.00", description="Tax rate percentage from tax_rates table (food) as string with 2 decimal places"),
     *                 @OA\Property(property="fee_value", type="string", example="2.00", description="Fee preset amount from fees table as string with 2 decimal places"),
     *                 @OA\Property(property="gratuity_value", type="string", example="10.00", description="Gratuity value from gratuity_settings table (percentage or fixed amount based on gratuity_type) as string with 2 decimal places")
     *             )
     *         )
     *     )
     * )
     */
    public function getConfigData(Request $request)
    {
        // Get business_id from query parameter, default to 1 if not provided (public endpoint, no authentication required)
        $businessId = $request->input('business_id', 1);

        // Validate business exists
        $business = \App\Models\Business::find($businessId);
        if (!$business) {
            return $this->errorResponse('Business not found', 404);
        }

        // Get tax rate from tax_rates table (food)
        $taxValue = 0.00;
        $foodTaxRate = TaxRate::where('business_id', $businessId)
            ->where('applies_to', 'food')
            ->first();

        if ($foodTaxRate && $foodTaxRate->rate_percent > 0) {
            $taxValue = (float) $foodTaxRate->rate_percent;
        }

        // Get fee preset from fees table
        $feeValue = 0.00;
        $fee = Fee::where('business_id', $businessId)->first();

        if ($fee && $fee->fee_preset > 0) {
            $feeValue = (float) $fee->fee_preset;
        }

        // Get gratuity value from gratuity_settings table
        $gratuityValue = 0.00;
        $gratuitySetting = GratuitySetting::where('business_id', $businessId)->first();

        if ($gratuitySetting && $gratuitySetting->gratuity_value > 0) {
            $gratuityValue = (float) $gratuitySetting->gratuity_value;
        }

        return $this->successResponse([
            'tax_value' => number_format($taxValue, 2, '.', ''),
            'fee_value' => number_format($feeValue, 2, '.', ''),
            'gratuity_value' => number_format($gratuityValue, 2, '.', ''),
        ], 'Configuration data retrieved successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/get-active-orders",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 7"},
     *     summary="Get Active Orders",
     *     description="Get a list of all active orders (status != 'completed'). Returns optimized order data with only essential fields.",
     *     @OA\Response(
     *         response=200,
     *         description="Active orders retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array",
     *                 @OA\Items(
     *                     type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="order_ticket_id", type="string", example="ORD-20240115-ABC123"),
     *                     @OA\Property(property="order_ticket_title", type="string", example="20240115-01T1"),
     *                     @OA\Property(property="status", type="string", example="open"),
     *                     @OA\Property(property="customer", type="integer", example=2, description="Number of guests"),
     *                     @OA\Property(property="created_at", type="string", example="2024-01-15 14:30:00"),
     *                     @OA\Property(property="table", type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="name", type="string", example="T1")
     *                     ),
     *                     @OA\Property(property="created_by_employee", type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="business_id", type="integer", example=1),
     *                         @OA\Property(property="first_name", type="string", example="Katheryn"),
     *                         @OA\Property(property="last_name", type="string", example="Eichmann"),
     *                         @OA\Property(property="email", type="string", example="waiter1@nadiadrestaurant.com"),
     *                         @OA\Property(property="image", type="string", example=""),
     *                         @OA\Property(property="avatar", type="string", example="http://localhost:8000/assets/img/avtar2.png"),
     *                         @OA\Property(property="is_active", type="boolean", example=true),
     *                         @OA\Property(property="created_at", type="string", example="2025-12-16T07:18:44.000000Z"),
     *                         @OA\Property(property="updated_at", type="string", example="2025-12-17T04:06:53.000000Z")
     *                     ),
     *                     @OA\Property(property="total_bill_amount", type="string", example="1250.50"),
     *                     @OA\Property(property="time_in_minutes", type="integer", example=45),
     *                     @OA\Property(property="isOnHold", type="boolean", example=false),
     *                     @OA\Property(property="item_status_count", type="object",
     *                         @OA\Property(property="total_order_items", type="integer", example=12, description="Total number of order items"),
     *                         @OA\Property(property="is_hold", type="integer", example=3, description="Count of items with order_status = 0 (HOLD)"),
     *                         @OA\Property(property="is_fire", type="integer", example=3, description="Count of items with order_status = 1 (FIRE)"),
     *                         @OA\Property(property="is_temp", type="integer", example=3, description="Count of items with order_status = 2 (TEMP)"),
     *                         @OA\Property(property="is_void", type="integer", example=3, description="Count of items with order_status = 3 (VOID)")
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=403, description="Employee is not associated with a business")
     * )
     */
    public function getActiveOrders(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        // Get all active orders (status != 'completed')
        // Note: Waiter-specific condition is commented out as per requirement
        // Original: ->where('created_by_employee_id', $employee->id)
        $orders = Order::where('business_id', $businessId)
            ->where('status', '!=', 'completed')
            ->whereHas('table.floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->with([
                'table:id,name,floor_id',
                'createdByEmployee',
                'checks.orderItems:id,check_id,order_status'
            ])
            ->orderBy('created_at', 'desc')
            ->get();

        $formattedOrders = $orders->map(function ($order) {
            // Calculate total bill amount
            $billAmounts = $this->calculateBillAmounts($order);

            // Get tip amount from payment history (only from completed payments, exclude refunds)
            $totalTipAmount = 0;
            $paymentHistories = PaymentHistory::where('order_id', $order->id)
                ->where('status', 'completed')
                ->get(['tip_amount']);

            foreach ($paymentHistories as $payment) {
                $totalTipAmount += (float) ($payment->tip_amount ?? 0);
            }

            // Calculate final total bill including tips (must match billing_summary.total_bill)
            $finalTotalBill = $billAmounts['total_bill'] + $totalTipAmount;

            // Count order items by status
            $itemStatusCount = [
                'total_order_items' => 0,
                'is_hold' => 0,
                'is_fire' => 0,
                'is_temp' => 0,
                'is_void' => 0,
            ];

            // Check if any item has hold status (order_status = 0) and count all statuses
            $isOnHold = false;
            if ($order->checks) {
                foreach ($order->checks as $check) {
                    if ($check->orderItems) {
                        foreach ($check->orderItems as $item) {
                            $itemStatusCount['total_order_items']++;

                            switch ($item->order_status) {
                                case 0: // HOLD
                                    $itemStatusCount['is_hold']++;
                                    $isOnHold = true;
                                    break;
                                case 1: // FIRE
                                    $itemStatusCount['is_fire']++;
                                    break;
                                case 2: // TEMP
                                    $itemStatusCount['is_temp']++;
                                    break;
                                case 3: // VOID
                                    $itemStatusCount['is_void']++;
                                    break;
                            }
                        }
                    }
                }
            }

            // Calculate time in minutes since order started
            $timeInMinutes = $order->created_at ? now()->diffInMinutes($order->created_at) : 0;

            // Return optimized structure with only essential data
            return [
                'id' => $order->id,
                'order_ticket_id' => $order->order_ticket_id,
                'order_ticket_title' => $order->order_ticket_title,
                'status' => $order->status,
                'customer' => $order->customer ?? 1,
                'created_at' => $order->created_at ? $order->created_at->format('Y-m-d H:i:s') : null,
                'table' => [
                    'id' => $order->table->id ?? null,
                    'name' => $order->table->name ?? '',
                ],
                'created_by_employee' => $order->createdByEmployee ? [
                    'id' => $order->createdByEmployee->id,
                    'business_id' => $order->createdByEmployee->business_id,
                    'first_name' => $order->createdByEmployee->first_name,
                    'last_name' => $order->createdByEmployee->last_name,
                    'email' => $order->createdByEmployee->email,
                    'image' => $order->createdByEmployee->image ?? '',
                    'avatar' => $order->createdByEmployee->avatar ?? '',
                    'is_active' => (bool) $order->createdByEmployee->is_active,
                    'created_at' => $order->createdByEmployee->created_at ? $order->createdByEmployee->created_at->format('Y-m-d\TH:i:s.000000\Z') : null,
                    'updated_at' => $order->createdByEmployee->updated_at ? $order->createdByEmployee->updated_at->format('Y-m-d\TH:i:s.000000\Z') : null,
                ] : null,
                'total_bill_amount' => number_format($finalTotalBill, 2, '.', ''),
                'time_in_minutes' => $timeInMinutes,
                'isOnHold' => $isOnHold,
                'item_status_count' => $itemStatusCount,
            ];
        })->values();

        return $this->successResponse($formattedOrders, 'Active orders retrieved successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/search-order",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 7"},
     *     summary="Search Order",
     *     description="Search orders by date range. Returns optimized order data with only essential fields. Default: today's data. If only start_date is provided, returns data for that single day. If both start_date and end_date are provided, returns data for the given date range.",
     *     @OA\Parameter(
     *         name="start_date",
     *         in="query",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-01-15"),
     *         description="Start date (YYYY-MM-DD). If only start_date is provided, returns data for that single day. Default: today"
     *     ),
     *     @OA\Parameter(
     *         name="end_date",
     *         in="query",
     *         required=false,
     *         @OA\Schema(type="string", format="date", example="2024-01-20"),
     *         description="End date (YYYY-MM-DD). If provided with start_date, returns data for the date range"
     *     ),
     *     @OA\Parameter(
     *         name="pdf",
     *         in="query",
     *         required=false,
     *         @OA\Schema(type="boolean", example=false),
     *         description="If true, returns PDF document with billing summary report for completed orders. Default: false (returns JSON)"
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Orders retrieved successfully. If pdf=true, returns PDF document (application/pdf). For completed orders, includes billing_summary in JSON response.",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array",
     *                 @OA\Items(
     *                     type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="order_ticket_id", type="string", example="ORD-20240115-ABC123"),
     *                     @OA\Property(property="order_ticket_title", type="string", example="20240115-01T1"),
     *                     @OA\Property(property="status", type="string", example="completed"),
     *                     @OA\Property(property="customer", type="integer", example=2, description="Number of guests"),
     *                     @OA\Property(property="created_at", type="string", example="2024-01-15 14:30:00"),
     *                     @OA\Property(property="table", type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="name", type="string", example="T1")
     *                     ),
     *                     @OA\Property(property="created_by_employee", type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="business_id", type="integer", example=1),
     *                         @OA\Property(property="first_name", type="string", example="Katheryn"),
     *                         @OA\Property(property="last_name", type="string", example="Eichmann"),
     *                         @OA\Property(property="email", type="string", example="waiter1@nadiadrestaurant.com"),
     *                         @OA\Property(property="image", type="string", example=""),
     *                         @OA\Property(property="avatar", type="string", example="http://localhost:8000/assets/img/avtar2.png"),
     *                         @OA\Property(property="is_active", type="boolean", example=true),
     *                         @OA\Property(property="created_at", type="string", example="2025-12-16T07:18:44.000000Z"),
     *                         @OA\Property(property="updated_at", type="string", example="2025-12-17T04:06:53.000000Z")
     *                     ),
     *                     @OA\Property(property="total_bill_amount", type="string", example="1250.50"),
     *                     @OA\Property(property="item_status_count", type="object",
     *                         @OA\Property(property="total_order_items", type="integer", example=12, description="Total number of order items"),
     *                         @OA\Property(property="is_hold", type="integer", example=3, description="Count of items with order_status = 0 (HOLD)"),
     *                         @OA\Property(property="is_fire", type="integer", example=3, description="Count of items with order_status = 1 (FIRE)"),
     *                         @OA\Property(property="is_temp", type="integer", example=3, description="Count of items with order_status = 2 (TEMP)"),
     *                         @OA\Property(property="is_void", type="integer", example=3, description="Count of items with order_status = 3 (VOID)")
     *                     ),
     *                     @OA\Property(property="billing_summary", type="object",
     *                         description="Billing summary (only for completed orders)",
     *                         @OA\Property(property="subtotal", type="string", example="1000.00"),
     *                         @OA\Property(property="total_discount", type="string", example="50.00"),
     *                         @OA\Property(property="tax_amount", type="string", example="95.00"),
     *                         @OA\Property(property="gratuity_amount", type="string", example="100.00"),
     *                         @OA\Property(property="fee_amount", type="string", example="5.50", description="Fee amount calculated as percentage from fees table"),
     *                         @OA\Property(property="total_bill", type="string", example="1250.50"),
     *                         @OA\Property(property="paid_amount", type="string", example="1250.50"),
     *                         @OA\Property(property="remaining_amount", type="string", example="0.00")
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=403, description="Employee is not associated with a business"),
     *     @OA\Response(response=400, description="Invalid date format")
     * )
     */
    public function searchOrder(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'pdf' => 'nullable|string|in:true,false,1,0',
            'status' => 'nullable|string|in:open,completed,hold,cancelled',
            'order_ticket_id' => 'nullable|string',
            'table_id' => 'nullable|integer|exists:restaurant_tables,id',
            'employee_id' => 'nullable|integer|exists:employees,id',
            'search' => 'nullable|string|max:255',
            'per_page' => 'nullable|integer|min:1|max:100',
            'page' => 'nullable|integer|min:1',
        ]);

        // Default to today if no dates provided
        $startDate = $validated['start_date'] ?? now()->format('Y-m-d');
        $endDate = $validated['end_date'] ?? $startDate;

        // If only start_date is provided, use it for both (single day)
        if (empty($validated['end_date']) && !empty($validated['start_date'])) {
            $endDate = $startDate;
        }

        // Check if PDF is requested - handle string "true"/"false" from query params
        $pdfValue = $validated['pdf'] ?? 'false';
        $isPdf = in_array(strtolower((string) $pdfValue), ['true', '1'], true);

        // Build date range query
        $ordersQuery = Order::where('business_id', $businessId)
            ->whereHas('table.floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->whereDate('created_at', '>=', $startDate)
            ->whereDate('created_at', '<=', $endDate);

        // Filter by status
        if (!empty($validated['status'])) {
            $statusMap = [
                'open' => ['open', 'pending', 'in_progress'],
                'completed' => ['completed'],
                'hold' => ['hold'],
                'cancelled' => ['cancelled'],
            ];
            $statuses = $statusMap[$validated['status']] ?? [$validated['status']];
            $ordersQuery->whereIn('status', $statuses);
        } elseif ($isPdf) {
            // If PDF is requested, only get completed orders for billing summary
            $ordersQuery->where('status', 'completed');
        }

        // Filter by order_ticket_id
        if (!empty($validated['order_ticket_id'])) {
            $ordersQuery->where('order_ticket_id', 'like', '%' . $validated['order_ticket_id'] . '%');
        }

        // Filter by table_id
        if (!empty($validated['table_id'])) {
            $ordersQuery->whereHas('table', function ($query) use ($validated) {
                $query->where('id', $validated['table_id']);
            });
        }

        // Filter by employee_id
        if (!empty($validated['employee_id'])) {
            $ordersQuery->where('created_by_employee_id', $validated['employee_id']);
        }

        // Search in order_ticket_id, order_ticket_title, or table name
        if (!empty($validated['search'])) {
            $searchTerm = $validated['search'];
            $ordersQuery->where(function ($query) use ($searchTerm) {
                $query->where('order_ticket_id', 'like', '%' . $searchTerm . '%')
                    ->orWhere('order_ticket_title', 'like', '%' . $searchTerm . '%')
                    ->orWhereHas('table', function ($q) use ($searchTerm) {
                        $q->where('name', 'like', '%' . $searchTerm . '%');
                    });
            });
        }

        $ordersQuery->with([
            'table:id,name,floor_id',
            'createdByEmployee',
            'checks.orderItems' => function ($query) {
                $query->whereNotIn('order_status', [2, 3]); // Exclude TEMP (2) and VOID (3) items
            },
            'checks.orderItems.modifiers',
            'checks.orderItems.menuItem',
        ])
            ->orderBy('created_at', 'desc');

        // Handle pagination
        $perPage = $validated['per_page'] ?? 50;
        $page = $validated['page'] ?? 1;
        $isPaginated = isset($validated['per_page']) || isset($validated['page']);

        // If pagination is requested, use paginate; otherwise get all
        if ($isPaginated) {
            $ordersPaginated = $ordersQuery->paginate($perPage, ['*'], 'page', $page);
            $totalOrders = $ordersPaginated->total();
            $ordersData = $ordersPaginated->items();
        } else {
            $ordersData = $ordersQuery->get();
            $totalOrders = $ordersData->count();
        }

        // Get business info for PDF
        $business = Business::find($businessId);
        $businessName = $business->name ?? 'RESTAURANT';

        $formattedOrders = collect($ordersData)->map(function ($order) use ($businessName) {
            // Calculate total bill amount with full billing summary
            $billAmounts = $this->calculateBillAmounts($order);

            // Count order items by status
            $itemStatusCount = [
                'total_order_items' => 0,
                'is_hold' => 0,
                'is_fire' => 0,
                'is_temp' => 0,
                'is_void' => 0,
            ];

            if ($order->checks) {
                foreach ($order->checks as $check) {
                    if ($check->orderItems) {
                        foreach ($check->orderItems as $item) {
                            $itemStatusCount['total_order_items']++;
                            switch ($item->order_status) {
                                case 0:
                                    $itemStatusCount['is_hold']++;
                                    break;
                                case 1:
                                    $itemStatusCount['is_fire']++;
                                    break;
                                case 2:
                                    $itemStatusCount['is_temp']++;
                                    break;
                                case 3:
                                    $itemStatusCount['is_void']++;
                                    break;
                            }
                        }
                    }
                }
            }

            $orderData = [
                'id' => $order->id,
                'order_ticket_id' => $order->order_ticket_id,
                'order_ticket_title' => $order->order_ticket_title,
                'status' => $order->status,
                'customer' => $order->customer ?? 1,
                'created_at' => $order->created_at ? $order->created_at->format('Y-m-d H:i:s') : null,
                'table' => [
                    'id' => $order->table->id ?? null,
                    'name' => $order->table->name ?? '',
                ],
                'created_by_employee' => $order->createdByEmployee ? [
                    'id' => $order->createdByEmployee->id,
                    'business_id' => $order->createdByEmployee->business_id,
                    'first_name' => $order->createdByEmployee->first_name,
                    'last_name' => $order->createdByEmployee->last_name,
                    'email' => $order->createdByEmployee->email,
                    'image' => $order->createdByEmployee->image ?? '',
                    'avatar' => $order->createdByEmployee->avatar ?? '',
                    'is_active' => (bool) $order->createdByEmployee->is_active,
                    'created_at' => $order->createdByEmployee->created_at ? $order->createdByEmployee->created_at->format('Y-m-d\TH:i:s.000000\Z') : null,
                    'updated_at' => $order->createdByEmployee->updated_at ? $order->createdByEmployee->updated_at->format('Y-m-d\TH:i:s.000000\Z') : null,
                ] : null,
                'item_status_count' => $itemStatusCount,
            ];

            // Get payment method information and tip amount from PaymentHistory
            $paymentMethods = [];
            $totalTipAmount = 0;
            $paymentHistoriesList = []; // Store individual payments and refunds for display
            $paymentHistories = PaymentHistory::where('order_id', $order->id)
                ->whereIn('status', ['completed', 'refunded'])
                ->orderBy('created_at', 'asc') // Chronological order for display
                ->get(['id', 'payment_mode', 'amount', 'tip_amount', 'status', 'refunded_payment_id', 'refund_reason', 'payment_is_refund', 'comment', 'created_at']);

            foreach ($paymentHistories as $payment) {
                $mode = strtolower($payment->payment_mode ?? '');

                // Format payment label
                $paymentLabel = ucfirst($mode);
                if ($mode === 'card') {
                    $paymentLabel = 'Card';
                } elseif ($mode === 'cash') {
                    $paymentLabel = 'Cash';
                } elseif ($mode === 'online') {
                    $paymentLabel = 'Online';
                }

                // Add individual payment/refund to list
                $paymentHistoriesList[] = [
                    'id' => $payment->id,
                    'payment_mode' => $paymentLabel,
                    'amount' => (float) $payment->amount,
                    'tip_amount' => (float) ($payment->tip_amount ?? 0),
                    'status' => $payment->status,
                    'payment_is_refund' => (bool) ($payment->payment_is_refund ?? false),
                    'refunded_payment_id' => $payment->refunded_payment_id ?? 0,
                    'refund_reason' => $payment->refund_reason ?? '',
                    'comment' => $payment->comment ?? '',
                    'created_at' => $payment->created_at,
                ];

                // Only count completed payments for grouped totals (exclude refunds)
                if ($payment->status === 'completed') {
                    if (!empty($mode)) {
                        if (!isset($paymentMethods[$mode])) {
                            $paymentMethods[$mode] = 0;
                        }
                        $paymentMethods[$mode] += (float) $payment->amount;
                    }
                    // Sum up tip amounts from all completed payments
                    $totalTipAmount += (float) ($payment->tip_amount ?? 0);
                }
            }

            // Calculate final total bill including tips
            $finalTotalBill = $billAmounts['total_bill'] + $totalTipAmount;

            // Update total_bill_amount to include tips (must match billing_summary.total_bill)
            $orderData['total_bill_amount'] = number_format($finalTotalBill, 2, '.', '');

            // Add billing summary for completed orders OR if payment has been made
            $hasPayment = $paymentHistories->isNotEmpty() || $billAmounts['paid_amount'] > 0;
            if ($order->status === 'completed' || $hasPayment) {
                $orderData['billing_summary'] = [
                    'subtotal' => number_format($billAmounts['subtotal'], 2, '.', ''),
                    'total_discount' => number_format($billAmounts['total_discount'], 2, '.', ''),
                    'tax_amount' => number_format($billAmounts['tax_amount'], 2, '.', ''),
                    'gratuity_amount' => number_format($billAmounts['gratuity_amount'], 2, '.', ''),
                    'fee_amount' => number_format($billAmounts['fee_amount'], 2, '.', ''),
                    'tip_amount' => number_format($totalTipAmount, 2, '.', ''),
                    'total_bill' => number_format($finalTotalBill, 2, '.', ''),
                    'paid_amount' => number_format($billAmounts['paid_amount'], 2, '.', ''),
                    'remaining_amount' => number_format(max(0, ($billAmounts['total_bill'] + $totalTipAmount) - $billAmounts['paid_amount']), 2, '.', ''),
                ];
            }

            // If no payment history, check Check type as fallback
            if (empty($paymentMethods) && $order->checks && $order->checks->isNotEmpty()) {
                $check = $order->checks->first();
                if ($check->type) {
                    $mode = strtolower($check->type);
                    $paymentMethods[$mode] = (float) ($billAmounts['paid_amount'] ?? 0);
                }
            }

            // Format payment method text for display
            $paymentMethodText = '';
            if (!empty($paymentMethods)) {
                $methodLabels = [];
                foreach ($paymentMethods as $mode => $amount) {
                    $label = ucfirst($mode);
                    if ($mode === 'card') {
                        $label = 'Card Payment';
                    } elseif ($mode === 'cash') {
                        $label = 'Cash Payment';
                    } elseif ($mode === 'online') {
                        $label = 'Online Payment';
                    }
                    $methodLabels[] = $label;
                }
                $paymentMethodText = implode(' + ', $methodLabels);
            }

            // Format order items with name and price (excluding TEMP and VOID items)
            $orderItems = [];
            if ($order->checks && $order->checks->isNotEmpty()) {
                foreach ($order->checks as $check) {
                    if ($check->orderItems && $check->orderItems->isNotEmpty()) {
                        foreach ($check->orderItems as $item) {
                            // Skip TEMP (2) and VOID (3) items
                            if (in_array($item->order_status, [2, 3])) {
                                continue;
                            }

                            // Calculate item total (unit_price * qty + modifiers)
                            $itemTotal = $item->unit_price * $item->qty;

                            // Add modifier prices
                            if ($item->relationLoaded('modifiers') && $item->modifiers->isNotEmpty()) {
                                foreach ($item->modifiers as $modifier) {
                                    $modifierPrice = $modifier->pivot->price ?? 0;
                                    $modifierQty = $modifier->pivot->qty ?? 1;
                                    $itemTotal += ($modifierPrice * $modifierQty);
                                }
                            }

                            $orderItems[] = [
                                'name' => $item->menuItem ? $item->menuItem->name : 'Unknown Item',
                                'price' => number_format($itemTotal, 2, '.', ''),
                                'qty' => $item->qty,
                                'unit_price' => number_format($item->unit_price, 2, '.', ''),
                            ];
                        }
                    }
                }
            }

            $orderData['order_items'] = $orderItems;
            $orderData['payment_method_text'] = $paymentMethodText;
            $orderData['payment_histories'] = $paymentHistoriesList; // Individual payments for display

            // Generate thermal format using Blade template
            $reportService = app(ReportService::class);
            $orderDate = $orderData['created_at'] ? date('m/d/Y h:i:s A', strtotime($orderData['created_at'])) : date('m/d/Y h:i:s A');
            $serverName = $orderData['created_by_employee']
                ? ($orderData['created_by_employee']['first_name'] . ' ' . $orderData['created_by_employee']['last_name'])
                : 'N/A';

            $thermalData = [
                'businessName' => $businessName,
                'orderData' => $orderData,
                'orderDate' => $orderDate,
                'serverName' => $serverName,
                'billing' => $orderData['billing_summary'] ?? [],
                'orderItems' => $orderItems,
                'paymentMethodText' => $paymentMethodText,
                'paymentHistories' => $paymentHistoriesList, // Individual payments for display
            ];

            $thermalFormat = $reportService->generateThermalFormat('search-order', $thermalData);
            $orderData['thermal_format'] = $thermalFormat;

            // Generate HTML format using Blade template
            $thermalFormatHtml = $reportService->generateThermalFormatHtml('search-order', $thermalData);
            $orderData['thermal_format_html'] = $thermalFormatHtml;

            return $orderData;
        })->values();

        // Generate PDF if requested
        if ($isPdf) {
            return $this->generateBillingSummaryPdf($formattedOrders, $businessName, $startDate, $endDate);
        }

        // Return orders with individual thermal_format for each order
        $responseData = [
            'orders' => $formattedOrders,
            'total' => $totalOrders,
        ];

        // Add pagination info if paginated
        if ($isPaginated) {
            $responseData['pagination'] = [
                'current_page' => $ordersPaginated->currentPage(),
                'per_page' => $ordersPaginated->perPage(),
                'total' => $ordersPaginated->total(),
                'last_page' => $ordersPaginated->lastPage(),
                'from' => $ordersPaginated->firstItem(),
                'to' => $ordersPaginated->lastItem(),
            ];
        }

        return $this->successResponse($responseData, 'Orders retrieved successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/order/payment",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 6"},
     *     summary="Process Payment",
     *     description="Process payment for an order. Marks the check as paid, updates order status to completed, and sets table status to available. Prevents further modifications to the order.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "type", "amount"},
     *             @OA\Property(
     *                 property="order_ticket_id",
     *                 type="string",
     *                 example="ORD-20251121-XJROYU",
     *                 description="Order ticket ID (format: ORD-YYYYMMDD-XXXXX)"
     *             ),
     *             @OA\Property(
     *                 property="type",
     *                 type="string",
     *                 enum={"cash", "online"},
     *                 example="cash",
     *                 description="Payment type: 'cash' for cash payment, 'online' for online/Stripe payment"
     *             ),
     *             @OA\Property(
     *                 property="amount",
     *                 type="number",
     *                 format="float",
     *                 example=1294.70,
     *                 description="Total payment amount (including tax)"
     *             ),
     *             @OA\Property(
     *                 property="tip_amount",
     *                 type="number",
     *                 format="float",
     *                 example=0.0,
     *                 description="Optional tip amount. Default: 0.0"
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Payment processed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Payment processed successfully"),
     *             @OA\Property(
     *                 property="data",
     *                 type="object",
     *                 @OA\Property(
     *                     property="payment",
     *                     type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="check_id", type="integer", example=1),
     *                     @OA\Property(property="employee_id", type="integer", example=1),
     *                     @OA\Property(property="method", type="string", example="cash"),
     *                     @OA\Property(property="amount", type="number", example=1294.70),
     *                     @OA\Property(property="tip_amount", type="number", example=0.0),
     *                     @OA\Property(property="payment_date", type="string", format="date-time", example="2025-11-23T21:18:06.000000Z")
     *                 ),
     *                 @OA\Property(
     *                     property="order",
     *                     type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU"),
     *                     @OA\Property(property="status", type="string", example="completed", description="Order status after payment"),
     *                     @OA\Property(
     *                         property="table",
     *                         type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="name", type="string", example="T1"),
     *                         @OA\Property(property="status", type="string", example="available", description="Table status after payment")
     *                     )
     *                 ),
     *                 @OA\Property(
     *                     property="check",
     *                     type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="order_id", type="integer", example=1),
     *                     @OA\Property(property="check_number", type="integer", example=1),
     *                     @OA\Property(property="status", type="string", example="paid", description="Check status after payment"),
     *                     @OA\Property(property="type", type="string", example="cash", description="Payment type: cash or online")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad Request - Order is already paid"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or Check not found"
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Order does not belong to business"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Validation error"
     *     )
     * )
     */

    /**
     * Calculate bill total and remaining amount for an order
     */
    private function calculateBillAmounts($order)
    {
        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return [
                'subtotal' => 0,
                'total_discount' => 0,
                'tax_amount' => 0,
                'gratuity_amount' => 0,
                'fee_amount' => 0,
                'total_bill' => 0,
                'paid_amount' => 0,
                'remaining_amount' => 0,
            ];
        }

        // Calculate total bill from order items (excluding TEMP and VOID items)
        $orderItems = OrderItem::where('check_id', $check->id)
            ->whereNotIn('order_status', [2, 3]) // Exclude TEMP (2) and VOID (3) items
            ->with('modifiers')
            ->get();

        $subtotal = 0;
        $totalDiscount = 0;

        foreach ($orderItems as $item) {
            // Item subtotal = unit_price * qty
            $itemSubtotal = $item->unit_price * $item->qty;

            // Add modifier prices to subtotal
            if ($item->relationLoaded('modifiers')) {
                foreach ($item->modifiers as $modifier) {
                    $modifierPrice = $modifier->pivot->price ?? 0;
                    $modifierQty = $modifier->pivot->qty ?? 1;
                    $itemSubtotal += $modifierPrice * $modifierQty;
                }
            }

            $itemDiscount = $item->discount_amount ?? 0;

            $subtotal += $itemSubtotal;
            $totalDiscount += $itemDiscount;
        }

        // Calculate amount after discount (before tax)
        $amountAfterDiscount = $subtotal - $totalDiscount;

        // Get food tax rate from tax_rates table
        $foodTaxRate = TaxRate::where('business_id', $order->business_id)
            ->where('applies_to', 'food')
            ->first();

        $taxAmount = 0;
        if ($foodTaxRate && $foodTaxRate->rate_percent > 0) {
            // Calculate tax on amount after discount
            $taxAmount = ($amountAfterDiscount * $foodTaxRate->rate_percent) / 100;
        }

        // Calculate amount after tax (for gratuity calculation)
        $amountAfterTax = $amountAfterDiscount + $taxAmount;

        // Calculate gratuity based on gratuity_key
        $gratuityAmount = 0;
        $gratuityKey = $order->gratuity_key ?? 'NotApplicable';

        if ($gratuityKey === 'Manual') {
            // Manual gratuity: Use order's gratuity_type and gratuity_value
            // Get raw attribute to avoid empty string from getter and formatted string from accessor
            $gratuityType = $order->getAttributes()['gratuity_type'] ?? null;
            $gratuityValue = (float) ($order->getAttributes()['gratuity_value'] ?? 0);

            if ($gratuityType === 'percentage' && $gratuityValue > 0) {
                // Calculate percentage gratuity on amount after tax
                $gratuityAmount = ($amountAfterTax * $gratuityValue) / 100;
            } elseif ($gratuityType === 'fixed_money' && $gratuityValue > 0) {
                // Fixed gratuity amount
                $gratuityAmount = $gratuityValue;
            }
        } elseif ($gratuityKey === 'Auto') {
            // Auto gratuity: Get from GratuitySetting table
            $gratuitySetting = GratuitySetting::where('business_id', $order->business_id)->first();

            if ($gratuitySetting) {
                $gratuityType = $gratuitySetting->gratuity_type;
                $gratuityValue = $gratuitySetting->gratuity_value ?? 0;

                if ($gratuityType === 'percentage' && $gratuityValue > 0) {
                    // Calculate percentage gratuity on amount after tax
                    $gratuityAmount = ($amountAfterTax * $gratuityValue) / 100;
                } elseif ($gratuityType === 'fixed_money' && $gratuityValue > 0) {
                    // Fixed gratuity amount
                    $gratuityAmount = $gratuityValue;
                }
            }
        }
        // NotApplicable: gratuity_amount remains 0

        // Get fee percentage from fees table and calculate fee amount
        $feeAmount = 0.00;
        $fee = Fee::where('business_id', $order->business_id)->first();

        if ($fee && $fee->fee_preset > 0) {
            // Fee is a percentage (fee_preset stores percentage value)
            // Calculate fee on amount after discount (before tax)
            $feeAmount = ($amountAfterDiscount * $fee->fee_preset) / 100;
        }

        // Total bill = Subtotal - Total Discount + Tax + Gratuity + Fee
        $totalBill = $amountAfterTax + $gratuityAmount + $feeAmount;

        // Update tax_value and fee_value in orders table
        $order->update([
            'tax_value' => round($taxAmount, 2),
            'fee_value' => round($feeAmount, 2),
        ]);

        // Calculate total paid amount from successful payments
        $paidAmount = PaymentHistory::where('order_id', $order->id)
            ->where('status', 'completed')
            ->sum('amount');

        // Subtract refunded amounts (refund records with status='refunded')
        $refundedAmount = PaymentHistory::where('order_id', $order->id)
            ->where('status', 'refunded')
            ->sum('amount');

        // Net paid amount = completed payments - refunds
        $netPaidAmount = $paidAmount - $refundedAmount;

        $remainingAmount = max(0, $totalBill - $netPaidAmount);

        return [
            'subtotal' => round($subtotal, 2),
            'total_discount' => round($totalDiscount, 2),
            'tax_amount' => round($taxAmount, 2),
            'gratuity_amount' => round($gratuityAmount, 2),
            'fee_amount' => round($feeAmount, 2),
            'total_bill' => round($totalBill, 2),
            'paid_amount' => round($netPaidAmount, 2),
            'remaining_amount' => round($remainingAmount, 2),
        ];
    }

    /**
     * @OA\Get(
     *     path="/pos/order/payment-history",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Payment"},
     *     summary="Get Payment History",
     *     description="Get payment history for an order. Returns all payment attempts (completed, failed, cancelled).",
     *     @OA\Parameter(
     *         name="order_ticket_id",
     *         in="query",
     *         required=true,
     *         @OA\Schema(type="string", example="ORD-20251121-XJROYU"),
     *         description="Order ticket ID"
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Payment history retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="payment_history", type="array", @OA\Items(type="object")),
     *                 @OA\Property(property="subtotal", type="string", example="2000.00", description="Subtotal before discount (sum of all item prices including modifiers) as string with 2 decimal places"),
     *                 @OA\Property(property="total_discount", type="string", example="200.00", description="Total discount amount applied as string with 2 decimal places"),
     *                 @OA\Property(property="tax_amount", type="string", example="90.00", description="Tax amount calculated on food items (applied on subtotal - discount) as string with 2 decimal places"),
     *                 @OA\Property(property="gratuity_amount", type="string", example="189.00", description="Gratuity amount calculated based on gratuity_key (Manual/Auto/NotApplicable). Applied on amount after tax (subtotal - discount + tax) as string with 2 decimal places"),
     *                 @OA\Property(property="fee_amount", type="string", example="2.00", description="Fee amount calculated as percentage from fees table (fee_preset percentage applied to amount after discount) as string with 2 decimal places"),
     *                 @OA\Property(property="total_bill", type="string", example="2129.00", description="Total bill amount after discount, tax, gratuity and fee (subtotal - total_discount + tax_amount + gratuity_amount + fee_amount) as string with 2 decimal places"),
     *                 @OA\Property(property="paid_amount", type="string", example="600.00", description="Total paid amount as string with 2 decimal places"),
     *                 @OA\Property(property="remaining_amount", type="string", example="1529.00", description="Remaining amount to pay (total_bill - paid_amount) as string with 2 decimal places"),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU")
     *             )
     *         )
     *     )
     * )
     */
    public function getPaymentHistory(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        // Get payment history
        $paymentHistory = PaymentHistory::where('order_id', $order->id)
            ->with(['employee:id,first_name,last_name'])
            ->orderBy('created_at', 'desc')
            ->get();

        // Calculate bill amounts
        $billAmounts = $this->calculateBillAmounts($order);

        return $this->successResponse([
            'payment_history' => $paymentHistory,
            'subtotal' => number_format($billAmounts['subtotal'], 2, '.', ''),
            'total_discount' => number_format($billAmounts['total_discount'], 2, '.', ''),
            'tax_amount' => number_format($billAmounts['tax_amount'], 2, '.', ''),
            'gratuity_amount' => number_format($billAmounts['gratuity_amount'], 2, '.', ''),
            'fee_amount' => number_format($billAmounts['fee_amount'], 2, '.', ''),
            'total_bill' => number_format($billAmounts['total_bill'], 2, '.', ''),
            'paid_amount' => number_format($billAmounts['paid_amount'], 2, '.', ''),
            'remaining_amount' => number_format($billAmounts['remaining_amount'], 2, '.', ''),
            'order_ticket_id' => $order->order_ticket_id,
        ], 'Payment history retrieved successfully');
    }

    /**
     * @OA\Get(
     *     path="/pos/order/bill-preview",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Reports"},
     *     summary="Get Order Bill Preview",
     *     description="Get billing summary/preview for an order. Returns complete bill breakdown including subtotal, discounts, taxes, gratuity, fees, total bill, paid amount, and remaining amount.",
     *     @OA\Parameter(
     *         name="order_ticket_id",
     *         in="query",
     *         required=true,
     *         @OA\Schema(type="string", example="ORD-20251103-U9VFRB"),
     *         description="Order ticket ID"
     *     ),
     *     @OA\Parameter(
     *         name="pdf",
     *         in="query",
     *         required=false,
     *         @OA\Schema(type="string", example="true"),
     *         description="If true, returns PDF document. Default: false (returns JSON)"
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Order bill preview retrieved successfully. If pdf=true, returns PDF document (application/pdf).",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251103-U9VFRB"),
     *                 @OA\Property(property="order_ticket_title", type="string", example="20251103-01T1"),
     *                 @OA\Property(property="status", type="string", example="open", description="Order status (open, completed)"),
     *                 @OA\Property(property="customer", type="integer", example=2, description="Number of guests"),
     *                 @OA\Property(property="created_at", type="string", example="2024-11-03 14:30:00"),
     *                 @OA\Property(property="table", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="name", type="string", example="T1")
     *                 ),
     *                 @OA\Property(property="created_by_employee", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="first_name", type="string", example="John"),
     *                     @OA\Property(property="last_name", type="string", example="Doe")
     *                 ),
     *                 @OA\Property(property="billing_summary", type="object",
     *                     @OA\Property(property="subtotal", type="string", example="1000.00", description="Subtotal before discount (sum of all item prices including modifiers)"),
     *                     @OA\Property(property="total_discount", type="string", example="50.00", description="Total discount amount applied"),
     *                     @OA\Property(property="tax_amount", type="string", example="95.00", description="Tax amount calculated on food items"),
     *                     @OA\Property(property="gratuity_amount", type="string", example="100.00", description="Gratuity amount calculated based on gratuity_key"),
     *                     @OA\Property(property="fee_amount", type="string", example="5.50", description="Fee amount calculated as percentage from fees table (fee_preset percentage applied to amount after discount)"),
     *                     @OA\Property(property="total_bill", type="string", example="1250.50", description="Total bill amount after discount, tax, gratuity and fee"),
     *                     @OA\Property(property="paid_amount", type="string", example="600.00", description="Total paid amount from completed payments"),
     *                     @OA\Property(property="remaining_amount", type="string", example="650.50", description="Remaining amount to pay")
     *                 ),
     *                 @OA\Property(property="order_items", type="array",
     *                     description="List of order items with name and price",
     *                     @OA\Items(type="object",
     *                         @OA\Property(property="name", type="string", example="Grilled Chicken"),
     *                         @OA\Property(property="price", type="string", example="25.50", description="Total price for this item (unit_price * qty + modifiers)"),
     *                         @OA\Property(property="qty", type="integer", example=2),
     *                         @OA\Property(property="unit_price", type="string", example="12.75")
     *                     )
     *                 ),
     *                 @OA\Property(property="thermal_format", type="string", description="Formatted text for thermal printer (32-character width)"),
     *                 @OA\Property(property="thermal_format_html", type="string", description="HTML formatted version of the thermal format. This is a complete HTML document that can be viewed in a browser or embedded in an iframe. Copy the HTML content and save it as an .html file to view, or use it directly in web applications.")
     *             )
     *         )
     *     ),
     *     @OA\Response(response=404, description="Order not found"),
     *     @OA\Response(response=403, description="Forbidden - Order does not belong to business"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     */
    public function getOrderBillPreview(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'pdf' => 'nullable|string|in:true,false,1,0',
        ]);

        // Check if PDF is requested
        $pdfValue = $validated['pdf'] ?? 'false';
        $isPdf = in_array(strtolower((string) $pdfValue), ['true', '1'], true);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->with([
                'table:id,name,floor_id',
                'createdByEmployee:id,first_name,last_name',
                'checks.orderItems' => function ($query) {
                    $query->whereNotIn('order_status', [2, 3]); // Exclude TEMP (2) and VOID (3) items
                },
                'checks.orderItems.menuItem:id,name',
                'checks.orderItems.modifiers',
            ])
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        // Get business info for PDF
        $business = Business::find($businessId);
        $businessName = $business->name ?? 'RESTAURANT';

        // Calculate bill amounts
        $billAmounts = $this->calculateBillAmounts($order);

        // Get payment method information and tip amount from PaymentHistory
        $paymentMethods = [];
        $totalTipAmount = 0;
        $paymentHistoriesList = []; // Store individual payments and refunds for display
        $paymentHistories = PaymentHistory::where('order_id', $order->id)
            ->whereIn('status', ['completed', 'refunded'])
            ->orderBy('created_at', 'asc') // Chronological order for display
            ->get(['id', 'payment_mode', 'amount', 'tip_amount', 'status', 'refunded_payment_id', 'refund_reason', 'payment_is_refund', 'comment', 'created_at']);

        foreach ($paymentHistories as $payment) {
            $mode = strtolower($payment->payment_mode ?? '');

            // Format payment label
            $paymentLabel = ucfirst($mode);
            if ($mode === 'card') {
                $paymentLabel = 'Card';
            } elseif ($mode === 'cash') {
                $paymentLabel = 'Cash';
            } elseif ($mode === 'online') {
                $paymentLabel = 'Online';
            }

            // Add individual payment/refund to list
            $paymentHistoriesList[] = [
                'id' => $payment->id,
                'payment_mode' => $paymentLabel,
                'amount' => (float) $payment->amount,
                'tip_amount' => (float) ($payment->tip_amount ?? 0),
                'status' => $payment->status,
                'payment_is_refund' => (bool) ($payment->payment_is_refund ?? false),
                'refunded_payment_id' => $payment->refunded_payment_id ?? 0,
                'refund_reason' => $payment->refund_reason ?? '',
                'comment' => $payment->comment ?? '',
                'created_at' => $payment->created_at,
            ];

            // Only count completed payments for grouped totals (exclude refunds)
            if ($payment->status === 'completed') {
                if (!empty($mode)) {
                    if (!isset($paymentMethods[$mode])) {
                        $paymentMethods[$mode] = 0;
                    }
                    $paymentMethods[$mode] += (float) $payment->amount;
                }
                // Sum up tip amounts from all completed payments
                $totalTipAmount += (float) ($payment->tip_amount ?? 0);
            }
        }

        // If no payment history, check Check type as fallback
        if (empty($paymentMethods) && $order->checks && $order->checks->isNotEmpty()) {
            $check = $order->checks->first();
            if ($check->type) {
                $mode = strtolower($check->type);
                $paymentMethods[$mode] = (float) ($billAmounts['paid_amount'] ?? 0);
            }
        }

        // Format payment method text for display
        $paymentMethodText = '';
        if (!empty($paymentMethods)) {
            $methodLabels = [];
            foreach ($paymentMethods as $mode => $amount) {
                $label = ucfirst($mode);
                if ($mode === 'card') {
                    $label = 'Card Payment';
                } elseif ($mode === 'cash') {
                    $label = 'Cash Payment';
                } elseif ($mode === 'online') {
                    $label = 'Online Payment';
                }
                $methodLabels[] = $label;
            }
            $paymentMethodText = implode(' + ', $methodLabels);
        }

        // Format order items with name and price (excluding TEMP and VOID items)
        $orderItems = [];
        if ($order->checks && $order->checks->isNotEmpty()) {
            foreach ($order->checks as $check) {
                if ($check->orderItems && $check->orderItems->isNotEmpty()) {
                    foreach ($check->orderItems as $item) {
                        // Skip TEMP (2) and VOID (3) items
                        if (in_array($item->order_status, [2, 3])) {
                            continue;
                        }

                        // Calculate item total (unit_price * qty + modifiers)
                        $itemTotal = $item->unit_price * $item->qty;

                        // Add modifier prices
                        if ($item->relationLoaded('modifiers') && $item->modifiers->isNotEmpty()) {
                            foreach ($item->modifiers as $modifier) {
                                $modifierPrice = $modifier->pivot->price ?? 0;
                                $modifierQty = $modifier->pivot->qty ?? 1;
                                $itemTotal += ($modifierPrice * $modifierQty);
                            }
                        }

                        $orderItems[] = [
                            'name' => $item->menuItem ? $item->menuItem->name : 'Unknown Item',
                            'price' => number_format($itemTotal, 2, '.', ''),
                            'qty' => $item->qty,
                            'unit_price' => number_format($item->unit_price, 2, '.', ''),
                        ];
                    }
                }
            }
        }

        $orderData = [
            'order_ticket_id' => $order->order_ticket_id,
            'order_ticket_title' => $order->order_ticket_title,
            'status' => $order->status,
            'customer' => $order->customer ?? 1,
            'created_at' => $order->created_at ? $order->created_at->format('Y-m-d H:i:s') : null,
            'table' => [
                'id' => $order->table->id ?? null,
                'name' => $order->table->name ?? '',
            ],
            'created_by_employee' => $order->createdByEmployee ? [
                'id' => $order->createdByEmployee->id,
                'first_name' => $order->createdByEmployee->first_name,
                'last_name' => $order->createdByEmployee->last_name,
            ] : null,
            'order_items' => $orderItems,
            'billing_summary' => [
                'subtotal' => number_format($billAmounts['subtotal'], 2, '.', ''),
                'total_discount' => number_format($billAmounts['total_discount'], 2, '.', ''),
                'tax_amount' => number_format($billAmounts['tax_amount'], 2, '.', ''),
                'gratuity_amount' => number_format($billAmounts['gratuity_amount'], 2, '.', ''),
                'fee_amount' => number_format($billAmounts['fee_amount'], 2, '.', ''),
                'tip_amount' => number_format($totalTipAmount, 2, '.', ''),
                'total_bill' => number_format($billAmounts['total_bill'] + $totalTipAmount, 2, '.', ''),
                'paid_amount' => number_format($billAmounts['paid_amount'], 2, '.', ''),
                'remaining_amount' => number_format(max(0, ($billAmounts['total_bill'] + $totalTipAmount) - $billAmounts['paid_amount']), 2, '.', ''),
            ],
            'payment_method_text' => $paymentMethodText,
            'payment_histories' => $paymentHistoriesList, // Individual payments for display
        ];

        // Generate thermal format using Blade template
        $reportService = app(ReportService::class);
        $thermalData = [
            'businessName' => $businessName,
            'orderData' => $orderData,
            'orderDate' => $orderData['created_at'] ? date('m/d/Y h:i:s A', strtotime($orderData['created_at'])) : date('m/d/Y h:i:s A'),
            'serverName' => $orderData['created_by_employee']
                ? ($orderData['created_by_employee']['first_name'] . ' ' . $orderData['created_by_employee']['last_name'])
                : 'N/A',
            'billing' => $orderData['billing_summary'] ?? [],
            'orderItems' => $orderData['order_items'] ?? [],
            'paymentMethodText' => $paymentMethodText,
            'paymentHistories' => $paymentHistoriesList, // Individual payments for display
        ];
        $thermalFormat = $reportService->generateThermalFormat('bill-preview', $thermalData);
        $orderData['thermal_format'] = $thermalFormat;

        // Generate HTML format using Blade template
        $thermalFormatHtml = $reportService->generateThermalFormatHtml('bill-preview', $thermalData);
        $orderData['thermal_format_html'] = $thermalFormatHtml;

        // Generate PDF if requested
        if ($isPdf) {
            return $this->generateOrderBillPreviewPdf($orderData, $businessName);
        }

        return $this->successResponse($orderData, 'Order bill preview retrieved successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/order/payment",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Payment"},
     *     summary="Process Payment or Update Payment Status",
     *     description="Process a new payment for an order OR update existing payment status. Supports split payments. Validates remaining amount. Stores all payment attempts (successful, failed, cancelled) in history. To update existing payment, provide payment_history_id and status.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "status"},
     *             @OA\Property(property="payment_history_id", type="integer", nullable=true, example=1, description="Optional: ID of existing payment to update. If provided, only status and failure_reason can be updated."),
     *             @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU"),
     *             @OA\Property(property="amount", type="number", nullable=true, example=200.00, description="Payment amount (required for new payment, ignored for update)"),
     *             @OA\Property(property="payment_mode", type="string", enum={"cash", "card", "online"}, nullable=true, example="cash", description="Required for new payment, ignored for update"),
     *             @OA\Property(property="status", type="string", enum={"completed", "failed", "cancelled"}, example="completed", description="Payment status"),
     *             @OA\Property(property="tip_type", type="string", enum={"percentage", "fixed"}, nullable=true, example="percentage", description="Ignored for update"),
     *             @OA\Property(property="tip_value", type="number", nullable=true, example=10.00, description="Tip percentage (0-100) or fixed amount (ignored for update)"),
     *             @OA\Property(property="failure_reason", type="string", nullable=true, example="Payment cancelled by user", description="Required if status is failed or cancelled")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Payment processed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Payment processed successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="payment_history", type="object"),
     *                 @OA\Property(property="subtotal", type="string", example="2000.00", description="Subtotal before discount (sum of all item prices including modifiers) as string with 2 decimal places"),
     *                 @OA\Property(property="total_discount", type="string", example="200.00", description="Total discount amount applied as string with 2 decimal places"),
     *                 @OA\Property(property="tax_amount", type="string", example="90.00", description="Tax amount calculated on food items (applied on subtotal - discount) as string with 2 decimal places"),
     *                 @OA\Property(property="gratuity_amount", type="string", example="189.00", description="Gratuity amount calculated based on gratuity_key (Manual/Auto/NotApplicable). Applied on amount after tax (subtotal - discount + tax) as string with 2 decimal places"),
     *                 @OA\Property(property="fee_amount", type="string", example="2.00", description="Fee amount calculated as percentage from fees table (fee_preset percentage applied to amount after discount) as string with 2 decimal places"),
     *                 @OA\Property(property="total_bill", type="string", example="2129.00", description="Total bill amount after discount, tax, gratuity and fee (subtotal - total_discount + tax_amount + gratuity_amount + fee_amount) as string with 2 decimal places"),
     *                 @OA\Property(property="paid_amount", type="string", example="200.00", description="Total paid amount as string with 2 decimal places"),
     *                 @OA\Property(property="remaining_amount", type="string", example="1929.00", description="Remaining amount to pay (total_bill - paid_amount) as string with 2 decimal places"),
     *                 @OA\Property(property="order_status", type="string", example="open", description="Order status: open or completed"),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad Request - Validation error (Note: Payment amount can exceed bill amount - no restriction)"
     *     )
     *     )
     * )
     */
    public function processPayment(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'payment_history_id' => 'nullable|integer|exists:payment_histories,id',
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'amount' => 'required_without:payment_history_id|nullable|numeric|min:0.01',
            'payment_mode' => 'required_without:payment_history_id|nullable|string|in:cash,card,online',
            'status' => 'required|string|in:completed,failed,cancelled',
            'tip_type' => 'nullable|string|in:percentage,fixed',
            'tip_value' => 'nullable|numeric|min:0',
            'failure_reason' => 'required_if:status,failed|required_if:status,cancelled|nullable|string|max:500',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        // Check if order is already fully paid
        if ($order->status === 'completed') {
            return $this->errorResponse('Order is already fully paid', 400);
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        // Check if updating existing payment
        $isUpdate = !empty($validated['payment_history_id']);

        if ($isUpdate) {
            // Update existing payment
            $paymentHistory = PaymentHistory::where('id', $validated['payment_history_id'])
                ->where('order_id', $order->id)
                ->first();

            if (!$paymentHistory) {
                return $this->notFoundResponse('Payment history not found or does not belong to this order');
            }

            // Get old status and amount for recalculation
            $oldStatus = $paymentHistory->status;
            $oldAmount = $paymentHistory->amount;

            DB::beginTransaction();
            try {
                // Update payment status and failure reason
                $paymentHistory->update([
                    'status' => $validated['status'],
                    'failure_reason' => $validated['failure_reason'] ?? $paymentHistory->failure_reason,
                ]);

                // Recalculate bill amounts after status change
                $updatedBillAmounts = $this->calculateBillAmounts($order);

                // Note: Order completion is handled by separate API endpoint
                // Payment status update no longer automatically completes orders
                if ($oldStatus === 'completed' && $validated['status'] !== 'completed') {
                    // Payment changed from completed to non-completed (failed/cancelled)
                    // Reopen order if it was completed
                    if ($order->status === 'completed') {
                        $order->update(['status' => 'open']);
                        $check->update(['status' => 'open']);
                    }
                }

                DB::commit();

                // Recalculate amounts after update
                $finalBillAmounts = $this->calculateBillAmounts($order);

                return $this->successResponse([
                    'payment_history' => $paymentHistory->load(['employee:id,first_name,last_name']),
                    'subtotal' => number_format($finalBillAmounts['subtotal'], 2, '.', ''),
                    'total_discount' => number_format($finalBillAmounts['total_discount'], 2, '.', ''),
                    'tax_amount' => number_format($finalBillAmounts['tax_amount'], 2, '.', ''),
                    'gratuity_amount' => number_format($finalBillAmounts['gratuity_amount'], 2, '.', ''),
                    'fee_amount' => number_format($finalBillAmounts['fee_amount'], 2, '.', ''),
                    'total_bill' => number_format($finalBillAmounts['total_bill'], 2, '.', ''),
                    'paid_amount' => number_format($finalBillAmounts['paid_amount'], 2, '.', ''),
                    'remaining_amount' => number_format($finalBillAmounts['remaining_amount'], 2, '.', ''),
                    'order_status' => $order->status,
                    'order_ticket_id' => $order->order_ticket_id,
                ], 'Payment status updated successfully');
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to update payment: ' . $e->getMessage(), 500);
            }
        } else {
            // Create new payment
            // Validate required fields for new payment
            if (empty($validated['amount']) || empty($validated['payment_mode'])) {
                return $this->errorResponse('amount and payment_mode are required for new payment', 400);
            }

            // Calculate bill amounts
            $billAmounts = $this->calculateBillAmounts($order);
            $remainingAmount = $billAmounts['remaining_amount'];
            $paidAmountBefore = $billAmounts['paid_amount'];

            // Payment validation for completed status
            // NOTE: Amount restriction removed - customers can pay any amount (including more than bill)
            // Example: Bill 1200, customer can pay 1400 cash - it's okay
            // Original validation was: if status === 'completed' && amount > remainingAmount
            // Now: No amount validation - allow any payment amount for any status

            // Calculate tip amount
            $tipAmount = 0;
            if (!empty($validated['tip_type']) && !empty($validated['tip_value'])) {
                if ($validated['tip_type'] === 'percentage') {
                    $tipAmount = ($validated['amount'] * $validated['tip_value']) / 100;
                } else {
                    $tipAmount = $validated['tip_value'];
                }
            }

            DB::beginTransaction();
            try {
                // Create payment history record
                $paymentHistory = PaymentHistory::create([
                    'order_id' => $order->id,
                    'check_id' => $check->id,
                    'employee_id' => $employee->id,
                    'amount' => $validated['amount'],
                    'tip_type' => $validated['tip_type'] ?? null,
                    'tip_value' => $validated['tip_value'] ?? 0,
                    'tip_amount' => round($tipAmount, 2),
                    'payment_mode' => $validated['payment_mode'],
                    'status' => $validated['status'],
                    'failure_reason' => $validated['failure_reason'] ?? null,
                    'total_bill_amount' => $billAmounts['total_bill'],
                    'remaining_amount' => $remainingAmount,
                    'paid_amount_before' => $paidAmountBefore,
                ]);

                // Note: Order completion is handled by separate API endpoint
                // Payment processing no longer automatically completes orders

                DB::commit();

                // Recalculate amounts after payment
                $updatedBillAmounts = $this->calculateBillAmounts($order);

                return $this->successResponse([
                    'payment_history' => $paymentHistory->load(['employee:id,first_name,last_name']),
                    'subtotal' => number_format($updatedBillAmounts['subtotal'], 2, '.', ''),
                    'total_discount' => number_format($updatedBillAmounts['total_discount'], 2, '.', ''),
                    'tax_amount' => number_format($updatedBillAmounts['tax_amount'], 2, '.', ''),
                    'gratuity_amount' => number_format($updatedBillAmounts['gratuity_amount'], 2, '.', ''),
                    'fee_amount' => number_format($updatedBillAmounts['fee_amount'], 2, '.', ''),
                    'total_bill' => number_format($updatedBillAmounts['total_bill'], 2, '.', ''),
                    'paid_amount' => number_format($updatedBillAmounts['paid_amount'], 2, '.', ''),
                    'remaining_amount' => number_format($updatedBillAmounts['remaining_amount'], 2, '.', ''),
                    'order_status' => $order->status,
                    'order_ticket_id' => $order->order_ticket_id,
                ], 'Payment processed successfully');
            } catch (\Exception $e) {
                DB::rollBack();
                return $this->errorResponse('Failed to process payment: ' . $e->getMessage(), 500);
            }
        }
    }

    /**
     * @OA\Post(
     *     path="/pos/order/complete",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Payment"},
     *     summary="Complete Order",
     *     description="Mark an order as completed. This will update the order status to 'completed', set the table status to 'available', and mark the check as 'paid'. Use this API after all payments are processed.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "status"},
     *             @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU", description="Order ticket ID"),
     *             @OA\Property(property="status", type="string", enum={"completed"}, example="completed", description="Order status - must be 'completed'")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Order completed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Order completed successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="order", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU"),
     *                     @OA\Property(property="status", type="string", example="completed"),
     *                     @OA\Property(property="table", type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="name", type="string", example="T1"),
     *                         @OA\Property(property="status", type="string", example="available")
     *                     )
     *                 ),
     *                 @OA\Property(property="check", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="status", type="string", example="paid")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad Request - Invalid status or order already completed"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order not found"
     *     )
     * )
     */
    public function completeOrder(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'status' => 'required|string|in:completed',
        ]);

        // Find order by order_ticket_id
        $order = Order::with(['table.floor'])
            ->where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->errorResponse('Order not found', 404);
        }

        if (!$order->table || !$order->table->floor) {
            return $this->forbiddenResponse('Order does not belong to the authenticated business');
        }

        if ((int) $order->table->floor->business_id !== (int) $businessId) {
            return $this->forbiddenResponse('Order does not belong to the authenticated business');
        }

        // Check if order is already completed
        if ($order->status === 'completed') {
            return $this->errorResponse('Order is already completed', 400);
        }

        // Get check for this order
        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->errorResponse('Check not found for this order', 404);
        }

        DB::beginTransaction();
        try {
            // Update order status to completed
            $order->update(['status' => 'completed']);

            // Update table status to available and clear current_served_by_id
            if ($order->table) {
                $order->table->update([
                    'status' => 'available',
                    'current_served_by_id' => null,
                ]);
            }

            // Update check status to paid
            $check->update(['status' => 'paid']);

            // Update last order_access_log entry's end_date
            $lastLogEntry = OrderAccessLog::where('order_id', $order->id)
                ->whereNull('end_date')
                ->orderBy('start_date', 'desc')
                ->first();

            if ($lastLogEntry) {
                $lastLogEntry->update(['end_date' => now()]);
            }

            DB::commit();

            // Reload relationships
            $order->load(['table']);

            return $this->successResponse([
                'order' => [
                    'id' => $order->id,
                    'order_ticket_id' => $order->order_ticket_id,
                    'status' => $order->status,
                    'table' => $order->table ? [
                        'id' => $order->table->id,
                        'name' => $order->table->name,
                        'status' => $order->table->status,
                    ] : null,
                ],
                'check' => [
                    'id' => $check->id,
                    'status' => $check->status,
                ],
            ], 'Order completed successfully');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Failed to complete order: ' . $e->getMessage(), 500);
        }
    }

    /**
     * @OA\Post(
     *     path="/pos/order/refund",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Payment"},
     *     summary="Process Refund for Payment",
     *     description="Create a refund for a completed payment. Supports partial refunds. Multiple refunds can be processed for the same payment as long as total refunded amount does not exceed original payment amount. Tips are not refunded.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "payment_history_id", "refund_amount", "refund_reason", "payment_mode"},
     *             @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU", description="Order ticket ID"),
     *             @OA\Property(property="payment_history_id", type="integer", example=5, description="ID of the completed payment to refund"),
     *             @OA\Property(property="refund_amount", type="number", example=100.00, description="Refund amount (must be > 0 and ≤ available refund amount)"),
     *             @OA\Property(property="refund_reason", type="string", example="Customer requested refund", description="Reason for refund (required)"),
     *             @OA\Property(property="payment_mode", type="string", enum={"cash", "card", "online"}, example="cash", description="How refund is processed"),
     *             @OA\Property(property="comment", type="string", example="Customer was not satisfied with the service", description="Optional comment/notes for the refund (max 1000 characters)")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Refund processed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Refund processed successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="refund_history", type="object",
     *                     description="Refund payment history record",
     *                     @OA\Property(property="id", type="integer", example=10),
     *                     @OA\Property(property="order_id", type="integer", example=5),
     *                     @OA\Property(property="check_id", type="integer", example=3),
     *                     @OA\Property(property="employee_id", type="integer", example=2),
     *                     @OA\Property(property="amount", type="string", example="100.00", description="Refund amount"),
     *                     @OA\Property(property="payment_mode", type="string", example="cash", enum={"cash", "card", "online"}),
     *                     @OA\Property(property="status", type="string", example="refunded"),
     *                     @OA\Property(property="refunded_payment_id", type="integer", example=5, description="ID of the original payment that was refunded"),
     *                     @OA\Property(property="refund_reason", type="string", example="Customer requested refund"),
     *                     @OA\Property(property="payment_is_refund", type="boolean", example=false, description="Whether this payment has been refunded (false for refund records themselves)"),
     *                     @OA\Property(property="comment", type="string", example="Customer was not satisfied with the service", description="Optional comment/notes for the refund"),
     *                     @OA\Property(property="created_at", type="string", format="date-time", example="2025-12-24T01:37:55.000000Z"),
     *                     @OA\Property(property="employee", type="object",
     *                         @OA\Property(property="id", type="integer", example=2),
     *                         @OA\Property(property="first_name", type="string", example="John"),
     *                         @OA\Property(property="last_name", type="string", example="Doe")
     *                     )
     *                 ),
     *                 @OA\Property(property="subtotal", type="string", example="2000.00"),
     *                 @OA\Property(property="total_discount", type="string", example="200.00"),
     *                 @OA\Property(property="tax_amount", type="string", example="90.00"),
     *                 @OA\Property(property="gratuity_amount", type="string", example="189.00"),
     *                 @OA\Property(property="fee_amount", type="string", example="2.00"),
     *                 @OA\Property(property="total_bill", type="string", example="2129.00"),
     *                 @OA\Property(property="paid_amount", type="string", example="100.00", description="Net paid amount after refund (completed payments - refunds)"),
     *                 @OA\Property(property="remaining_amount", type="string", example="2029.00"),
     *                 @OA\Property(property="order_status", type="string", example="open"),
     *                 @OA\Property(property="order_ticket_id", type="string", example="ORD-20251121-XJROYU")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad Request - Validation error or invalid refund amount",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Can only refund completed payments"),
     *             @OA\Property(property="data", type="object", example=null)
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or payment not found",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Payment not found or does not belong to this order"),
     *             @OA\Property(property="data", type="object", example=null)
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Forbidden - Employee not associated with business",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Authenticated employee is not associated with a business"),
     *             @OA\Property(property="data", type="object", example=null)
     *         )
     *     ),
     *     @OA\Response(
     *         response=500,
     *         description="Internal Server Error",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Failed to process refund: Database error"),
     *             @OA\Property(property="data", type="object", example=null)
     *         )
     *     )
     * )
     */
    public function processRefund(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'payment_history_id' => 'required|integer|exists:payment_histories,id',
            'refund_amount' => 'required|numeric|min:0.01',
            'refund_reason' => 'required|string|max:500',
            'payment_mode' => 'required|string|in:cash,card,online',
            'comment' => 'nullable|string|max:1000',
        ]);

        // Find order
        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        // Find the payment to refund
        $originalPayment = PaymentHistory::where('id', $validated['payment_history_id'])
            ->where('order_id', $order->id)
            ->first();

        if (!$originalPayment) {
            return $this->notFoundResponse('Payment not found or does not belong to this order');
        }

        // Validate: Payment must be completed (cannot refund failed/cancelled/refunded payments)
        if ($originalPayment->status !== 'completed') {
            return $this->errorResponse('Can only refund completed payments', 400);
        }

        // Validate: Cannot refund a refund (refunded_payment_id must be 0)
        if ($originalPayment->refunded_payment_id != 0) {
            return $this->errorResponse('Cannot refund a refund', 400);
        }

        // Validate: Check if payment is already marked as refunded (additional safety check)
        // Note: We still allow partial refunds if there's available amount, but this prevents
        // refunding a payment that has been fully refunded
        if ($originalPayment->payment_is_refund == true) {
            // Check if there's still available amount for partial refund
            $alreadyRefundedCheck = PaymentHistory::where('refunded_payment_id', $originalPayment->id)
                ->where('status', 'refunded')
                ->sum('amount');

            $availableToRefundCheck = (float) $originalPayment->amount - $alreadyRefundedCheck;

            if ($availableToRefundCheck <= 0) {
                return $this->errorResponse('This payment has already been fully refunded and cannot be refunded again', 400);
            }
        }

        // Calculate already refunded amount for this payment
        $alreadyRefunded = PaymentHistory::where('refunded_payment_id', $originalPayment->id)
            ->where('status', 'refunded')
            ->sum('amount');

        $availableToRefund = (float) $originalPayment->amount - $alreadyRefunded;

        // Validate: Refund amount cannot exceed available amount
        if ($validated['refund_amount'] > $availableToRefund) {
            return $this->errorResponse(
                "Refund amount ({$validated['refund_amount']}) exceeds available refund amount ({$availableToRefund}). Original payment: {$originalPayment->amount}, Already refunded: {$alreadyRefunded}",
                400
            );
        }

        $check = Check::where('order_id', $order->id)->first();

        if (!$check) {
            return $this->notFoundResponse('Check not found for this order');
        }

        // Calculate current bill amounts
        $billAmounts = $this->calculateBillAmounts($order);

        DB::beginTransaction();
        try {
            // Create refund record (status='refunded', refunded_payment_id points to original payment)
            $refundHistory = PaymentHistory::create([
                'order_id' => $order->id,
                'check_id' => $check->id,
                'employee_id' => $employee->id,
                'amount' => $validated['refund_amount'],
                'tip_type' => null, // Tips are not refunded
                'tip_value' => 0,
                'tip_amount' => 0,
                'payment_mode' => $validated['payment_mode'],
                'status' => 'refunded',
                'failure_reason' => null,
                'total_bill_amount' => $billAmounts['total_bill'],
                'remaining_amount' => $billAmounts['remaining_amount'],
                'paid_amount_before' => $billAmounts['paid_amount'],
                'refunded_payment_id' => $originalPayment->id, // Link to original payment
                'refund_reason' => $validated['refund_reason'],
                'payment_is_refund' => false, // Refund records themselves are not refunded
                'comment' => $validated['comment'] ?? null,
            ]);

            // Calculate total refunded amount after this refund
            $totalRefundedAfterThis = PaymentHistory::where('refunded_payment_id', $originalPayment->id)
                ->where('status', 'refunded')
                ->sum('amount');

            // Update original payment: set payment_is_refund=true only if payment is fully refunded
            // This prevents anyone from refunding this payment again once it's fully refunded
            // Also save refund_reason and comment in the original payment record
            $isFullyRefunded = ((float) $totalRefundedAfterThis >= (float) $originalPayment->amount);

            $originalPayment->update([
                'payment_is_refund' => $isFullyRefunded, // Set to true only when fully refunded
                'refund_reason' => $validated['refund_reason'], // Save refund reason in original payment
                'comment' => $validated['comment'] ?? null, // Save comment in original payment
            ]);

            DB::commit();

            // Recalculate amounts after refund
            $updatedBillAmounts = $this->calculateBillAmounts($order);

            // Reload refund history with all fields including comment
            $refundHistory->refresh();

            // Reload original payment to get updated payment_is_refund status
            $originalPayment->refresh();

            // Format refund_history to ensure empty strings for null values
            $refundHistoryData = $refundHistory->load(['employee:id,first_name,last_name'])->toArray();
            $refundHistoryData['refund_reason'] = $refundHistoryData['refund_reason'] ?? '';
            $refundHistoryData['comment'] = $refundHistoryData['comment'] ?? '';

            return $this->successResponse([
                'refund_history' => $refundHistoryData,
                'original_payment' => [
                    'id' => $originalPayment->id,
                    'payment_is_refund' => (bool) $originalPayment->payment_is_refund,
                    'amount' => $originalPayment->amount,
                    'status' => $originalPayment->status,
                ],
                'subtotal' => number_format($updatedBillAmounts['subtotal'], 2, '.', ''),
                'total_discount' => number_format($updatedBillAmounts['total_discount'], 2, '.', ''),
                'tax_amount' => number_format($updatedBillAmounts['tax_amount'], 2, '.', ''),
                'gratuity_amount' => number_format($updatedBillAmounts['gratuity_amount'], 2, '.', ''),
                'fee_amount' => number_format($updatedBillAmounts['fee_amount'], 2, '.', ''),
                'total_bill' => number_format($updatedBillAmounts['total_bill'], 2, '.', ''),
                'paid_amount' => number_format($updatedBillAmounts['paid_amount'], 2, '.', ''),
                'remaining_amount' => number_format($updatedBillAmounts['remaining_amount'], 2, '.', ''),
                'order_status' => $order->status,
                'order_ticket_id' => $order->order_ticket_id,
            ], 'Refund processed successfully');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Failed to process refund: ' . $e->getMessage(), 500);
        }
    }

    public function releaseTable(Request $request)
    {
        $validated = $request->validate([
            'table_id' => 'required|exists:restaurant_tables,id',
        ]);

        $table = RestaurantTable::find($validated['table_id']);

        if (!$table) {
            return $this->notFoundResponse('Table not found');
        }

        $table->update(['status' => 'available']);

        return $this->successResponse($table, 'Table released successfully');
    }

    public function getOpenOrders(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $orders = Order::where('business_id', $businessId)
            ->where('status', '!=', 'completed')
            ->whereHas('table.floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->with(['table', 'createdByEmployee', 'checks.orderItems.menuItem', 'checks.orderItems.modifiers'])
            ->get();

        return $this->successResponse($orders, 'Open orders retrieved successfully');
    }

    public function getOrderHistory(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $orders = Order::where('business_id', $businessId)
            ->where('status', 'completed')
            ->whereHas('table.floor', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->with(['table', 'createdByEmployee', 'checks.orderItems.menuItem', 'checks.payments'])
            ->latest()
            ->take(50)
            ->get();

        return $this->successResponse($orders, 'Order history retrieved successfully');
    }

    public function getModifiers(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $modifiers = ModifierGroup::with('modifiers')
            ->where('business_id', $businessId)
            ->get();

        return $this->successResponse($modifiers, 'Modifiers retrieved successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/change_table",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 5"},
     *     summary="Change Table",
     *     description="Move entire order (with all merged tables) to a new table. All previously merged tables will be released and made available. The order number stays the same, only the table name in order_ticket_title changes.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "new_table_id"},
     *             @OA\Property(property="order_ticket_id", type="string", example="ORD-20251103-U9VFRB", description="Unique order ticket ID to identify the order (stays same even when table changes)"),
     *             @OA\Property(property="new_table_id", type="integer", example=1, description="New table ID where the entire order should be moved to")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Table changed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="order", type="object", description="Order object with updated table information"),
     *                 @OA\Property(property="order_ticket_title", type="string", example="20251103-01T1",
     *                     description="Updated ticket title with new table name. Order number (01) stays the same."
     *                 ),
     *                 @OA\Property(property="message", type="string", example="Table changed successfully")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad request - order is completed or new table is already occupied"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or table not found"
     *     )
     * )
     */
    public function changeTable(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'new_table_id' => 'required|exists:restaurant_tables,id',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->with('table.floor')
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        if ($order->status === 'completed') {
            return $this->errorResponse('Cannot change table for completed order', 400);
        }

        $newTable = RestaurantTable::with('floor')->find($validated['new_table_id']);

        if (!$newTable) {
            return $this->notFoundResponse('New table not found');
        }

        if ((int) ($newTable->floor->business_id ?? 0) !== (int) $businessId) {
            return $this->forbiddenResponse('New table does not belong to the authenticated business');
        }

        $newTable = RestaurantTable::with('floor')->find($validated['new_table_id']);

        if (!$newTable || (int) ($newTable->floor->business_id ?? 0) !== (int) $businessId) {
            return $this->forbiddenResponse('New table does not belong to the authenticated business');
        }

        // Check if new table is available (not occupied)
        $existingOrderOnNewTable = Order::where('business_id', $businessId)
            ->where('table_id', $validated['new_table_id'])
            ->where('status', '!=', 'completed')
            ->where('id', '!=', $order->id)
            ->first();

        if ($existingOrderOnNewTable) {
            return $this->errorResponse('New table is already occupied. Please select an available table.', 400);
        }

        // Get all merged table IDs (from merged_table_ids or just current table_id)
        $tablesToRelease = [];
        try {
            $columns = Schema::getColumnListing('orders');
            if (in_array('merged_table_ids', $columns) && !empty($order->merged_table_ids)) {
                $tablesToRelease = $order->merged_table_ids;
            } else {
                $tablesToRelease = [$order->table_id];
            }
        } catch (\Exception $e) {
            $tablesToRelease = [$order->table_id];
        }

        // When changing table, keep the original order number but update table name
        // Extract order number from existing title (format: YYYYMMDD-NNT1 or YYYYMMDD-NNT1T3)
        $existingTitle = $order->order_ticket_title;
        preg_match('/\d{8}-(\d{2})/', $existingTitle, $matches);
        $orderNumber = isset($matches[1]) ? $matches[1] : '01';

        // Update order_ticket_title with new table name but keep order number
        $orderTicketTitle = date('Ymd') . '-' . $orderNumber . $newTable->name;

        // Update order - reset merged_table_ids to single table
        $order->update([
            'table_id' => $validated['new_table_id'],
            'order_ticket_title' => $orderTicketTitle,
            'merged_table_ids' => [$validated['new_table_id']],
        ]);

        // Release all old/merged tables (make them available) - except the new table
        RestaurantTable::whereIn('id', $tablesToRelease)
            ->where('id', '!=', $validated['new_table_id'])
            ->update(['status' => 'available']);

        // Mark new table as occupied
        RestaurantTable::where('id', $validated['new_table_id'])->update(['status' => 'occupied']);

        return $this->successResponse([
            'order' => $order->load(['table', 'createdByEmployee', 'checks.orderItems']),
            'order_ticket_title' => $orderTicketTitle,
            'message' => 'Table changed successfully'
        ], 'Table changed successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/replace_table",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 5"},
     *     summary="Replace Table",
     *     description="Replace a specific table in merged tables. Only the targeted table (old_table_id) will be replaced with new_table_id. Other merged tables remain unchanged. Useful when you want to swap one table in a merged group.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "old_table_id", "new_table_id"},
     *             @OA\Property(property="order_ticket_id", type="string", example="ORD-20251103-U9VFRB", description="Unique order ticket ID to identify the order"),
     *             @OA\Property(property="old_table_id", type="integer", example=2, description="Table ID to be replaced (must be in merged_table_ids)"),
     *             @OA\Property(property="new_table_id", type="integer", example=1, description="New table ID to replace the old table")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Table replaced successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="order", type="object", description="Order object with updated table information"),
     *                 @OA\Property(property="order_ticket_title", type="string", example="20251103-01T1T3",
     *                     description="Updated ticket title reflecting the table replacement"
     *                 ),
     *                 @OA\Property(property="merged_table_ids", type="array", @OA\Items(type="integer"), example={1, 3},
     *                     description="Updated array of merged table IDs"
     *                 ),
     *                 @OA\Property(property="message", type="string", example="Table replaced successfully")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad request - order is completed, new table is already occupied, or old_table_id not found in merged tables"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order or table not found"
     *     )
     * )
     */
    public function replaceTable(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'old_table_id' => 'required|exists:restaurant_tables,id',
            'new_table_id' => 'required|exists:restaurant_tables,id',
        ]);

        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->with('table.floor')
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        if ($order->status === 'completed') {
            return $this->errorResponse('Cannot replace table for completed order', 400);
        }

        // Check if new table is available (not occupied)
        $existingOrderOnNewTable = Order::where('business_id', $businessId)
            ->where('table_id', $validated['new_table_id'])
            ->where('status', '!=', 'completed')
            ->where('id', '!=', $order->id)
            ->first();

        if ($existingOrderOnNewTable) {
            return $this->errorResponse('New table is already occupied. Please select an available table.', 400);
        }

        // Get current merged table IDs
        $mergedTableIds = [];
        try {
            $columns = Schema::getColumnListing('orders');
            if (in_array('merged_table_ids', $columns) && !empty($order->merged_table_ids)) {
                $mergedTableIds = $order->merged_table_ids;
            } else {
                $mergedTableIds = [$order->table_id];
            }
        } catch (\Exception $e) {
            $mergedTableIds = [$order->table_id];
        }

        // Check if old_table_id exists in merged tables
        if (!in_array($validated['old_table_id'], $mergedTableIds)) {
            return $this->errorResponse('Old table ID not found in merged tables. Cannot replace a table that is not part of this order.', 400);
        }

        // Replace old_table_id with new_table_id in merged_table_ids
        $mergedTableIds = array_map(function ($tableId) use ($validated) {
            return $tableId == $validated['old_table_id'] ? $validated['new_table_id'] : $tableId;
        }, $mergedTableIds);

        // Remove duplicates and sort
        $mergedTableIds = array_unique($mergedTableIds);
        sort($mergedTableIds);

        // Update main table_id if old_table_id was the main table
        $updateData = [];
        if ($order->table_id == $validated['old_table_id']) {
            $updateData['table_id'] = $validated['new_table_id'];
        }

        // Update merged_table_ids
        try {
            $columns = Schema::getColumnListing('orders');
            if (in_array('merged_table_ids', $columns)) {
                $updateData['merged_table_ids'] = $mergedTableIds;
            }
        } catch (\Exception $e) {
            // Column doesn't exist, skip it
        }

        // Update order_ticket_title with new table names
        preg_match('/\d{8}-(\d{2})/', $order->order_ticket_title, $matches);
        $orderNumber = $matches[1] ?? '01';

        $tableNames = RestaurantTable::whereIn('id', $mergedTableIds)
            ->orderBy('id')
            ->pluck('name')
            ->implode('');

        $orderTicketTitle = date('Ymd') . '-' . $orderNumber . $tableNames;
        $updateData['order_ticket_title'] = $orderTicketTitle;

        // Update order
        $order->update($updateData);

        // Release old table (make it available)
        RestaurantTable::where('id', $validated['old_table_id'])->update(['status' => 'available']);

        // Mark new table as occupied
        RestaurantTable::where('id', $validated['new_table_id'])->update(['status' => 'occupied']);

        return $this->successResponse([
            'order' => $order->load(['table', 'createdByEmployee', 'checks.orderItems']),
            'order_ticket_title' => $orderTicketTitle,
            'merged_table_ids' => $mergedTableIds,
            'message' => 'Table replaced successfully'
        ], 'Table replaced successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/merge_tables",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 5"},
     *     summary="Merge Tables",
     *     description="Merge multiple table orders into one order. You can pass an array of table IDs to merge. All order items from merged orders will be combined into the first/main order. The order_ticket_title will include all merged table names (e.g., 20251103-01T1T3 or 20251103-01T1T2T3).",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id", "table_ids"},
     *             @OA\Property(
     *                 property="order_ticket_id",
     *                 type="string",
     *                 example="ORD-20251103-U9VFRB",
     *                 description="Unique order ticket ID of the main order (this order will receive items from other tables)"
     *             ),
     *             @OA\Property(
     *                 property="table_ids",
     *                 type="array",
     *                 @OA\Items(type="integer"),
     *                 example={1, 3},
     *                 description="Array of table IDs to merge with. The order identified by order_ticket_id will receive items from these tables. Example: [1, 3] merges tables 1 and 3 into the main order."
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Tables merged successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="order", type="object", description="Main order object (first table) with all merged items"),
     *                 @OA\Property(property="order_ticket_title", type="string", example="20251103-01T1T3",
     *                     description="Updated ticket title with all merged table names (T1T3, T1T2T3, etc.)"
     *                 ),
     *                 @OA\Property(property="merged_table_ids", type="array",
     *                     @OA\Items(type="integer"),
     *                     example={1, 3},
     *                     description="Array of all table IDs that are merged in this order. Example: [1, 3] means tables T1 and T3 are merged."
     *                 ),
     *                 @OA\Property(property="merged_count", type="integer", example=2, description="Number of orders merged"),
     *                 @OA\Property(property="message", type="string", example="Tables merged successfully")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Bad request - no orders found on tables, tables already merged, or validation error"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Table not found"
     *     )
     * )
     */
    public function mergeTables(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
            'table_ids' => 'required|array|min:1',
            'table_ids.*' => 'required|exists:restaurant_tables,id',
        ]);

        // Find main order by order_ticket_id
        $mainOrder = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->where('status', '!=', 'completed')
            ->first();

        if (!$mainOrder) {
            return $this->errorResponse('Order not found or already completed', 404);
        }

        $tableIds = array_unique($validated['table_ids']);
        sort($tableIds);

        $mainTableId = $mainOrder->table_id;

        $mainCheck = Check::where('order_id', $mainOrder->id)->first();
        if (!$mainCheck) {
            return $this->errorResponse('Check not found for main order', 400);
        }

        // Get existing merged table IDs
        $allMergedTableIds = [];
        try {
            $columns = Schema::getColumnListing('orders');
            if (in_array('merged_table_ids', $columns) && !empty($mainOrder->merged_table_ids)) {
                $allMergedTableIds = $mainOrder->merged_table_ids;
            } else {
                $allMergedTableIds = [$mainOrder->table_id];
            }
        } catch (\Exception $e) {
            $allMergedTableIds = [$mainOrder->table_id];
        }

        // Process all tables to merge
        foreach ($tableIds as $tableId) {
            if ($tableId === $mainTableId) {
                continue; // Skip main table (already handled)
            }

            $table = RestaurantTable::with('floor')->find($tableId);

            if (!$table || (int) ($table->floor->business_id ?? 0) !== (int) $businessId) {
                return $this->forbiddenResponse('One or more tables do not belong to the authenticated business');
            }

            // Add table ID to merged list
            if (!in_array($tableId, $allMergedTableIds)) {
                $allMergedTableIds[] = $tableId;
            }

            // Check if this table has an order - if yes, merge items
            $orderToMerge = Order::where('business_id', $businessId)
                ->where('table_id', $tableId)
                ->where('status', '!=', 'completed')
                ->where('id', '!=', $mainOrder->id)
                ->first();

            if ($orderToMerge) {
                $check = Check::where('order_id', $orderToMerge->id)->first();
                if ($check) {
                    $orderItemIds = OrderItem::where('check_id', $check->id)->pluck('id');

                    if ($orderItemIds->isNotEmpty()) {
                        OrderItem::whereIn('id', $orderItemIds)
                            ->update([
                                'order_id' => $mainOrder->id,
                                'check_id' => $mainCheck->id,
                            ]);

                        DB::table('order_item_modifiers')
                            ->whereIn('order_item_id', $orderItemIds)
                            ->update(['order_id' => $mainOrder->id]);
                    }

                    $check->update(['status' => 'merged']);
                    $orderToMerge->delete();
                }
            }

            // Mark table as occupied (merged)
            RestaurantTable::where('id', $tableId)->update(['status' => 'occupied']);
        }

        // Sort and create title
        sort($allMergedTableIds);
        $tableNames = RestaurantTable::whereIn('id', $allMergedTableIds)
            ->orderBy('id')
            ->pluck('name')
            ->implode('');

        preg_match('/\d{8}-(\d{2})/', $mainOrder->order_ticket_title, $matches);
        $orderNumber = $matches[1] ?? '01';
        $orderTicketTitle = date('Ymd') . '-' . $orderNumber . $tableNames;

        // Update main order
        $updateData = ['order_ticket_title' => $orderTicketTitle];
        try {
            if (in_array('merged_table_ids', Schema::getColumnListing('orders'))) {
                $updateData['merged_table_ids'] = $allMergedTableIds;
            }
        } catch (\Exception $e) {
            // Skip if column doesn't exist
        }

        $mainOrder->update($updateData);
        $mainOrder->refresh();

        return $this->successResponse([
            'order' => $mainOrder->load(['table', 'createdByEmployee', 'checks.orderItems']),
            'order_ticket_title' => $orderTicketTitle,
            'merged_table_ids' => $allMergedTableIds,
            'message' => 'Tables merged successfully'
        ], 'Tables merged successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/cancel_reservation",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Step 5"},
     *     summary="Cancel Reservation",
     *     description="Cancel a reservation by removing the order entry and setting the table status back to available. This operation can only be performed if the order has no order items. If the order has items, it cannot be removed.",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"order_ticket_id"},
     *             @OA\Property(property="order_ticket_id", type="string", example="ORD-20251103-U9VFRB", description="Order ticket ID to cancel"),
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Reservation cancelled successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Reservation cancelled successfully. Order removed and table set to available.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Cannot cancel reservation - order has items",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="sorry this order consume item so can not be removed")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Order not found"
     *     )
     * )
     */
    public function cancelReservation(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'order_ticket_id' => 'required|exists:orders,order_ticket_id',
        ]);

        // Find order by order_ticket_id
        $order = Order::where('order_ticket_id', $validated['order_ticket_id'])
            ->where('business_id', $businessId)
            ->with('table')
            ->first();

        if (!$order) {
            return $this->notFoundResponse('Order not found');
        }

        // Check if order has any order items
        $hasOrderItems = OrderItem::where('order_id', $order->id)->exists();

        if ($hasOrderItems) {
            return $this->errorResponse('sorry this order consume item so can not be removed', 400);
        }

        // Get table ID before deleting order
        $tableId = $order->table_id;

        // Save order details to order_cancels table before deleting
        // Get raw gratuity_type value (null instead of empty string from getter)
        $gratuityType = $order->getAttributes()['gratuity_type'] ?? null;
        // Convert empty string to null for ENUM compatibility
        $gratuityType = ($gratuityType === '' || $gratuityType === null) ? null : $gratuityType;

        OrderCancel::create([
            'business_id' => $order->business_id,
            'order_ticket_id' => $order->order_ticket_id,
            'order_ticket_title' => $order->order_ticket_title,
            'table_id' => $order->table_id,
            'created_by_employee_id' => $order->created_by_employee_id,
            'status' => $order->status,
            'customer' => $order->customer,
            'notes' => $order->notes,
            'gratuity_key' => $order->gratuity_key,
            'gratuity_type' => $gratuityType,
            'gratuity_value' => $order->gratuity_value,
            'tax_value' => $order->tax_value ?? 0.00,
            'fee_value' => $order->fee_value ?? 0.00,
            'merged_table_ids' => $order->merged_table_ids,
        ]);

        // Delete the order (this will cascade delete checks due to foreign key constraints)
        $order->delete();

        // Set table status back to available
        RestaurantTable::where('id', $tableId)->update(['status' => 'available']);

        return $this->successResponse(null, 'Reservation cancelled successfully. Order removed and table set to available.');
    }

    /**
     * Format order bill preview for thermal printer
     */
    private function formatOrderBillPreviewForThermal($orderData, $businessName)
    {
        $lines = [];
        $lines[] = str_pad($businessName, 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad('ORDER BILL PREVIEW', 32, ' ', STR_PAD_BOTH);
        $lines[] = str_repeat('-', 32);

        $orderDate = $orderData['created_at'] ? date('m/d/Y h:i:s A', strtotime($orderData['created_at'])) : date('m/d/Y h:i:s A');
        $lines[] = 'Date: ' . $orderDate;
        $lines[] = 'Ticket ID: ' . $orderData['order_ticket_id'];
        $lines[] = 'Table: ' . ($orderData['table']['name'] ?? 'N/A');

        $serverName = $orderData['created_by_employee']
            ? ($orderData['created_by_employee']['first_name'] . ' ' . $orderData['created_by_employee']['last_name'])
            : 'N/A';
        $lines[] = 'Server: ' . $serverName;
        $lines[] = 'Guests: ' . ($orderData['customer'] ?? 1);
        $lines[] = str_repeat('-', 32);

        // Add order items
        $orderItems = $orderData['order_items'] ?? [];
        if (!empty($orderItems)) {
            $lines[] = 'ORDER ITEMS:';
            foreach ($orderItems as $item) {
                $itemLine = '  ' . $item['name'];
                if ($item['qty'] > 1) {
                    $itemLine .= ' (x' . $item['qty'] . ')';
                }
                $itemLine .= ' - $' . $item['price'];
                $lines[] = $itemLine;
            }
            $lines[] = str_repeat('-', 32);
        }

        $billing = $orderData['billing_summary'] ?? [];
        $lines[] = 'BILLING SUMMARY:';
        $lines[] = 'Subtotal: $' . number_format((float) ($billing['subtotal'] ?? 0), 2);
        $lines[] = 'Discount: $' . number_format((float) ($billing['total_discount'] ?? 0), 2);
        $lines[] = 'Tax: $' . number_format((float) ($billing['tax_amount'] ?? 0), 2);
        $lines[] = 'Gratuity: $' . number_format((float) ($billing['gratuity_amount'] ?? 0), 2);
        $lines[] = 'Fees: $' . number_format((float) ($billing['fee_amount'] ?? 0), 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'TOTAL BILL: $' . number_format((float) ($billing['total_bill'] ?? 0), 2);

        // Format paid amount with individual payments and refunds
        $paymentHistories = $orderData['payment_histories'] ?? [];
        if (!empty($paymentHistories) && count($paymentHistories) > 0) {
            foreach ($paymentHistories as $payment) {
                $paymentMode = $payment['payment_mode'] ?? 'Unknown';
                $paymentAmount = number_format((float) ($payment['amount'] ?? 0), 2);
                // Check if this is a refund record: status='refunded' OR refunded_payment_id points to another payment
                $isRefund = ($payment['status'] === 'refunded') || (($payment['refunded_payment_id'] ?? 0) !== 0);

                if ($isRefund) {
                    $lines[] = 'Refund (' . $paymentMode . '): -$' . $paymentAmount;
                } else {
                    $lines[] = 'Paid (' . $paymentMode . '): $' . $paymentAmount;
                }
            }
            $paidAmount = number_format((float) ($billing['paid_amount'] ?? 0), 2);
            $lines[] = 'Total Paid: $' . $paidAmount;
        } else {
            $paidAmount = number_format((float) ($billing['paid_amount'] ?? 0), 2);
            $lines[] = 'Paid: $' . $paidAmount;
        }

        $lines[] = 'Remaining: $' . number_format((float) ($billing['remaining_amount'] ?? 0), 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = '';
        $lines[] = str_pad('END OF BILL', 32, ' ', STR_PAD_BOTH);
        $lines[] = 'Generated: ' . date('m/d/Y h:i:s A');

        return implode("\n", $lines);
    }

    /**
     * Format billing summary for thermal printer
     */
    private function formatBillingSummaryForThermal($orders, $businessName, $startDate, $endDate)
    {
        $lines = [];
        $lines[] = str_pad($businessName, 32, ' ', STR_PAD_BOTH);
        $lines[] = str_pad('BILLING SUMMARY REPORT', 32, ' ', STR_PAD_BOTH);
        $lines[] = str_repeat('-', 32);

        $dateRange = $startDate === $endDate
            ? date('m/d/Y', strtotime($startDate))
            : date('m/d/Y', strtotime($startDate)) . ' - ' . date('m/d/Y', strtotime($endDate));
        $lines[] = 'Date Range: ' . $dateRange;
        $lines[] = 'Generated: ' . date('m/d/Y h:i:s A');
        $lines[] = 'Total Orders: ' . count($orders);
        $lines[] = str_repeat('-', 32);

        // Calculate totals
        $totalSubtotal = 0;
        $totalDiscount = 0;
        $totalTax = 0;
        $totalGratuity = 0;
        $totalFee = 0;
        $totalBill = 0;
        $totalPaid = 0;
        $totalRemaining = 0;

        foreach ($orders as $order) {
            if (isset($order['billing_summary'])) {
                $totalSubtotal += (float) $order['billing_summary']['subtotal'];
                $totalDiscount += (float) $order['billing_summary']['total_discount'];
                $totalTax += (float) $order['billing_summary']['tax_amount'];
                $totalGratuity += (float) $order['billing_summary']['gratuity_amount'];
                $totalFee += (float) $order['billing_summary']['fee_amount'];
                $totalBill += (float) $order['billing_summary']['total_bill'];
                $totalPaid += (float) $order['billing_summary']['paid_amount'];
                $totalRemaining += (float) $order['billing_summary']['remaining_amount'];
            }
        }

        $lines[] = 'SUMMARY TOTALS:';
        $lines[] = 'Subtotal: $' . number_format($totalSubtotal, 2);
        $lines[] = 'Discount: $' . number_format($totalDiscount, 2);
        $lines[] = 'Tax: $' . number_format($totalTax, 2);
        $lines[] = 'Gratuity: $' . number_format($totalGratuity, 2);
        $lines[] = 'Fees: $' . number_format($totalFee, 2);
        $lines[] = str_repeat('-', 32);
        $lines[] = 'TOTAL BILL: $' . number_format($totalBill, 2);
        $lines[] = 'TOTAL PAID: $' . number_format($totalPaid, 2);
        $lines[] = 'TOTAL REMAINING: $' . number_format($totalRemaining, 2);
        $lines[] = str_repeat('-', 32);

        // List individual orders
        if (count($orders) > 0) {
            $lines[] = '';
            $lines[] = 'ORDER DETAILS:';
            $lines[] = str_repeat('-', 32);

            foreach ($orders as $order) {
                $billing = $order['billing_summary'] ?? [];
                $lines[] = 'Ticket: ' . ($order['order_ticket_id'] ?? 'N/A');
                $lines[] = '  Table: ' . ($order['table']['name'] ?? 'N/A');
                $lines[] = '  Date: ' . ($order['created_at'] ?? 'N/A');
                $lines[] = '  Total: $' . number_format((float) ($billing['total_bill'] ?? 0), 2);
                $lines[] = '  Paid: $' . number_format((float) ($billing['paid_amount'] ?? 0), 2);
                $lines[] = '  Remaining: $' . number_format((float) ($billing['remaining_amount'] ?? 0), 2);
                $lines[] = str_repeat('-', 32);
            }
        }

        $lines[] = '';
        $lines[] = str_pad('END OF REPORT', 32, ' ', STR_PAD_BOTH);

        return implode("\n", $lines);
    }

    /**
     * Generate PDF for billing summary report
     */
    private function generateBillingSummaryPdf($orders, $businessName, $startDate, $endDate)
    {
        $dateRange = $startDate === $endDate
            ? date('m/d/Y', strtotime($startDate))
            : date('m/d/Y', strtotime($startDate)) . ' - ' . date('m/d/Y', strtotime($endDate));

        // Calculate totals
        $totalSubtotal = 0;
        $totalDiscount = 0;
        $totalTax = 0;
        $totalGratuity = 0;
        $totalFee = 0;
        $totalBill = 0;
        $totalPaid = 0;
        $totalRemaining = 0;

        foreach ($orders as $order) {
            if (isset($order['billing_summary'])) {
                $totalSubtotal += (float) $order['billing_summary']['subtotal'];
                $totalDiscount += (float) $order['billing_summary']['total_discount'];
                $totalTax += (float) $order['billing_summary']['tax_amount'];
                $totalGratuity += (float) $order['billing_summary']['gratuity_amount'];
                $totalFee += (float) $order['billing_summary']['fee_amount'];
                $totalBill += (float) $order['billing_summary']['total_bill'];
                $totalPaid += (float) $order['billing_summary']['paid_amount'];
                $totalRemaining += (float) $order['billing_summary']['remaining_amount'];
            }
        }

        // Generate HTML content for PDF
        $html = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Billing Summary Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            margin: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #000;
            padding-bottom: 10px;
        }
        .header h1 {
            margin: 0;
            font-size: 18px;
        }
        .header h2 {
            margin: 5px 0;
            font-size: 14px;
            font-weight: normal;
        }
        .info {
            margin-bottom: 20px;
        }
        .info p {
            margin: 5px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        .summary-table {
            margin-top: 20px;
        }
        .summary-table td {
            font-weight: bold;
        }
        .text-right {
            text-align: right;
        }
        .billing-details {
            font-size: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>' . htmlspecialchars($businessName) . '</h1>
        <h2>BILLING SUMMARY REPORT</h2>
        <p>Date Range: ' . htmlspecialchars($dateRange) . '</p>
        <p>Generated: ' . date('m/d/Y h:i:s A') . '</p>
    </div>

    <div class="info">
        <p><strong>Total Orders:</strong> ' . count($orders) . '</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>Order ID</th>
                <th>Table</th>
                <th>Date</th>
                <th>Server</th>
                <th>Guests</th>
                <th>Subtotal</th>
                <th>Discount</th>
                <th>Tax</th>
                <th>Gratuity</th>
                <th>Fee</th>
                <th>Total Bill</th>
                <th>Paid</th>
                <th>Remaining</th>
            </tr>
        </thead>
        <tbody>';

        foreach ($orders as $order) {
            $serverName = $order['created_by_employee']
                ? htmlspecialchars($order['created_by_employee']['first_name'] . ' ' . $order['created_by_employee']['last_name'])
                : 'N/A';

            $billing = $order['billing_summary'] ?? [];

            $html .= '<tr>
                <td>' . htmlspecialchars($order['order_ticket_id'] ?? 'N/A') . '</td>
                <td>' . htmlspecialchars($order['table']['name'] ?? 'N/A') . '</td>
                <td>' . htmlspecialchars($order['created_at'] ?? 'N/A') . '</td>
                <td>' . $serverName . '</td>
                <td>' . ($order['customer'] ?? 0) . '</td>
                <td class="text-right">$' . number_format((float) ($billing['subtotal'] ?? 0), 2) . '</td>
                <td class="text-right">$' . number_format((float) ($billing['total_discount'] ?? 0), 2) . '</td>
                <td class="text-right">$' . number_format((float) ($billing['tax_amount'] ?? 0), 2) . '</td>
                <td class="text-right">$' . number_format((float) ($billing['gratuity_amount'] ?? 0), 2) . '</td>
                <td class="text-right">$' . number_format((float) ($billing['fee_amount'] ?? 0), 2) . '</td>
                <td class="text-right"><strong>$' . number_format((float) ($billing['total_bill'] ?? 0), 2) . '</strong></td>
                <td class="text-right">$' . number_format((float) ($billing['paid_amount'] ?? 0), 2) . '</td>
                <td class="text-right">$' . number_format((float) ($billing['remaining_amount'] ?? 0), 2) . '</td>
            </tr>';
        }

        $html .= '</tbody>
        <tfoot>
            <tr class="summary-table">
                <td colspan="5" class="text-right"><strong>TOTALS:</strong></td>
                <td class="text-right"><strong>$' . number_format($totalSubtotal, 2) . '</strong></td>
                <td class="text-right"><strong>$' . number_format($totalDiscount, 2) . '</strong></td>
                <td class="text-right"><strong>$' . number_format($totalTax, 2) . '</strong></td>
                <td class="text-right"><strong>$' . number_format($totalGratuity, 2) . '</strong></td>
                <td class="text-right"><strong>$' . number_format($totalFee, 2) . '</strong></td>
                <td class="text-right"><strong>$' . number_format($totalBill, 2) . '</strong></td>
                <td class="text-right"><strong>$' . number_format($totalPaid, 2) . '</strong></td>
                <td class="text-right"><strong>$' . number_format($totalRemaining, 2) . '</strong></td>
            </tr>
        </tfoot>
    </table>
</body>
</html>';

        // Generate PDF filename
        $filename = 'billing-summary-' . $startDate . ($startDate !== $endDate ? '-' . $endDate : '') . '.pdf';

        // Generate PDF using DomPDF
        $pdf = Pdf::loadHTML($html);
        $pdf->setPaper('a4', 'landscape'); // Use landscape for wide tables
        $pdf->setOption('enable-local-file-access', true);
        $pdf->setOption('isRemoteEnabled', true);

        // Return PDF response - Flutter apps can download or view this
        // Using stream() with Attachment => false allows viewing in browser
        // Flutter apps can download it programmatically by saving the response
        return $pdf->stream($filename, [
            'Attachment' => false, // false = view in browser, Flutter can download programmatically
        ]);
    }

    /**
     * Generate PDF for single order bill preview
     */
    private function generateOrderBillPreviewPdf($orderData, $businessName)
    {
        $orderDate = $orderData['created_at'] ? date('m/d/Y h:i:s A', strtotime($orderData['created_at'])) : date('m/d/Y h:i:s A');
        $serverName = $orderData['created_by_employee']
            ? htmlspecialchars($orderData['created_by_employee']['first_name'] . ' ' . $orderData['created_by_employee']['last_name'])
            : 'N/A';

        $billing = $orderData['billing_summary'] ?? [];
        $paymentHistories = $orderData['payment_histories'] ?? [];

        // Generate HTML content for PDF
        $html = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Order Bill Preview</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            margin: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #000;
            padding-bottom: 10px;
        }
        .header h1 {
            margin: 0;
            font-size: 20px;
            font-weight: bold;
        }
        .header h2 {
            margin: 5px 0;
            font-size: 16px;
            font-weight: normal;
        }
        .order-info {
            margin-bottom: 20px;
            padding: 15px;
            background-color: #f9f9f9;
            border: 1px solid #ddd;
        }
        .order-info table {
            width: 100%;
            border-collapse: collapse;
        }
        .order-info td {
            padding: 5px;
            border: none;
        }
        .order-info td:first-child {
            font-weight: bold;
            width: 40%;
        }
        .billing-summary {
            margin-top: 20px;
        }
        .billing-summary table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .billing-summary th, .billing-summary td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: left;
        }
        .billing-summary th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        .billing-summary td:last-child {
            text-align: right;
            font-weight: bold;
        }
        .total-row {
            background-color: #f9f9f9;
            font-weight: bold;
            font-size: 14px;
        }
        .text-right {
            text-align: right;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 10px;
            color: #666;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>' . htmlspecialchars($businessName) . '</h1>
        <h2>ORDER BILL PREVIEW</h2>
        <p>Generated: ' . date('m/d/Y h:i:s A') . '</p>
    </div>

    <div class="order-info">
        <table>
            <tr>
                <td>Order Ticket ID:</td>
                <td>' . htmlspecialchars($orderData['order_ticket_id'] ?? 'N/A') . '</td>
            </tr>
            <tr>
                <td>Order Ticket Title:</td>
                <td>' . htmlspecialchars($orderData['order_ticket_title'] ?? 'N/A') . '</td>
            </tr>
            <tr>
                <td>Table:</td>
                <td>' . htmlspecialchars($orderData['table']['name'] ?? 'N/A') . '</td>
            </tr>
            <tr>
                <td>Status:</td>
                <td>' . htmlspecialchars(strtoupper($orderData['status'] ?? 'N/A')) . '</td>
            </tr>
            <tr>
                <td>Server:</td>
                <td>' . $serverName . '</td>
            </tr>
            <tr>
                <td>Guests:</td>
                <td>' . ($orderData['customer'] ?? 0) . '</td>
            </tr>
            <tr>
                <td>Order Date:</td>
                <td>' . htmlspecialchars($orderDate) . '</td>
            </tr>
        </table>
    </div>

    <div class="billing-summary">
        <h3 style="margin-bottom: 10px;">Order Items</h3>
        <table>
            <tr>
                <th>Item Name</th>
                <th class="text-right">Qty</th>
                <th class="text-right">Price</th>
            </tr>';

        $orderItems = $orderData['order_items'] ?? [];
        if (!empty($orderItems)) {
            foreach ($orderItems as $item) {
                $html .= '
            <tr>
                <td>' . htmlspecialchars($item['name']) . '</td>
                <td class="text-right">' . $item['qty'] . '</td>
                <td class="text-right">$' . $item['price'] . '</td>
            </tr>';
            }
        } else {
            $html .= '
            <tr>
                <td colspan="3" class="text-right">No items</td>
            </tr>';
        }

        $html .= '
        </table>
    </div>

    <div class="billing-summary">
        <h3 style="margin-bottom: 10px;">Billing Summary</h3>
        <table>
            <tr>
                <th>Description</th>
                <th class="text-right">Amount</th>
            </tr>
            <tr>
                <td>Subtotal</td>
                <td class="text-right">$' . number_format((float) ($billing['subtotal'] ?? 0), 2) . '</td>
            </tr>
            <tr>
                <td>Discount</td>
                <td class="text-right">-$' . number_format((float) ($billing['total_discount'] ?? 0), 2) . '</td>
            </tr>
            <tr>
                <td>Tax</td>
                <td class="text-right">$' . number_format((float) ($billing['tax_amount'] ?? 0), 2) . '</td>
            </tr>
            <tr>
                <td>Gratuity</td>
                <td class="text-right">$' . number_format((float) ($billing['gratuity_amount'] ?? 0), 2) . '</td>
            </tr>
            <tr>
                <td>Fee</td>
                <td class="text-right">$' . number_format((float) ($billing['fee_amount'] ?? 0), 2) . '</td>
            </tr>';

        // Add tip row if tip amount is greater than 0
        if ((float) ($billing['tip_amount'] ?? 0) > 0) {
            $html .= '
            <tr>
                <td>Tip</td>
                <td class="text-right">$' . number_format((float) ($billing['tip_amount'] ?? 0), 2) . '</td>
            </tr>';
        }

        $html .= '
            <tr class="total-row">
                <td><strong>Total Bill</strong></td>
                <td class="text-right"><strong>$' . number_format((float) ($billing['total_bill'] ?? 0), 2) . '</strong></td>
            </tr>';

        // Add individual payment rows
        if (!empty($paymentHistories) && count($paymentHistories) > 0) {
            foreach ($paymentHistories as $payment) {
                $paymentMode = htmlspecialchars($payment['payment_mode'] ?? 'Unknown');
                $paymentAmount = number_format((float) ($payment['amount'] ?? 0), 2);
                // Check if this is a refund record: status='refunded' OR refunded_payment_id points to another payment
                $isRefund = ($payment['status'] === 'refunded') || (($payment['refunded_payment_id'] ?? 0) !== 0);
                $html .= '
            <tr>
                <td>' . ($isRefund ? 'Refund (' : 'Paid (') . $paymentMode . ')</td>
                <td class="text-right">' . ($isRefund ? '-$' : '$') . $paymentAmount . '</td>
            </tr>';
            }
            $html .= '
            <tr>
                <td><strong>Total Paid</strong></td>
                <td class="text-right"><strong>$' . number_format((float) ($billing['paid_amount'] ?? 0), 2) . '</strong></td>
            </tr>';
        } else {
            $html .= '
            <tr>
                <td>Paid Amount</td>
                <td class="text-right">$' . number_format((float) ($billing['paid_amount'] ?? 0), 2) . '</td>
            </tr>';
        }

        $html .= '
            <tr class="total-row">
                <td><strong>Remaining Amount</strong></td>
                <td class="text-right"><strong>$' . number_format((float) ($billing['remaining_amount'] ?? 0), 2) . '</strong></td>
            </tr>
        </table>
    </div>

    <div class="footer">
        <p>This is a preview of the order bill. For payment processing, please use the payment API.</p>
    </div>
</body>
</html>';

        // Generate PDF filename
        $filename = 'order-bill-' . ($orderData['order_ticket_id'] ?? 'preview') . '.pdf';

        // Generate PDF using DomPDF
        $pdf = Pdf::loadHTML($html);
        $pdf->setPaper('a4', 'portrait');
        $pdf->setOption('enable-local-file-access', true);
        $pdf->setOption('isRemoteEnabled', true);

        // Return PDF response - Flutter apps can download or view this
        return $pdf->stream($filename, [
            'Attachment' => false, // false = view in browser, Flutter can download programmatically
        ]);
    }

    /**
     * @OA\Get(
     *     path="/pos/end-of-date",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Reports"},
     *     summary="Get End of Date Status",
     *     description="Get status of previous pending EOD dates, active orders, and days with no orders. Used to check what needs to be done before making end of day.",
     *     @OA\Parameter(
     *         name="date",
     *         in="query",
     *         required=true,
     *         @OA\Schema(type="string", format="date-time", example="2024-12-16 23:59:59"),
     *         description="Today's date with time"
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="End of date status retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="pending_eod_dates", type="array",
     *                     description="Array of dates that have no end of day completed",
     *                     @OA\Items(type="string", example="2024-12-15")
     *                 ),
     *                 @OA\Property(property="active_orders", type="array",
     *                     description="Array of active (non-completed) orders",
     *                     @OA\Items(
     *                         type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="order_ticket_id", type="string", example="ORD-20241216-ABC123"),
     *                         @OA\Property(property="status", type="string", example="open"),
     *                         @OA\Property(property="created_at", type="string", example="2024-12-16 14:30:00"),
     *                         @OA\Property(property="created_by_employee", type="object",
     *                             @OA\Property(property="id", type="integer", example=1),
     *                             @OA\Property(property="business_id", type="integer", example=1),
     *                             @OA\Property(property="first_name", type="string", example="Katheryn"),
     *                             @OA\Property(property="last_name", type="string", example="Eichmann"),
     *                             @OA\Property(property="email", type="string", example="waiter1@nadiadrestaurant.com"),
     *                             @OA\Property(property="image", type="string", example=""),
     *                             @OA\Property(property="avatar", type="string", example="http://localhost:8000/assets/img/avtar2.png"),
     *                             @OA\Property(property="is_active", type="boolean", example=true),
     *                             @OA\Property(property="created_at", type="string", example="2025-12-16T07:18:44.000000Z"),
     *                             @OA\Property(property="updated_at", type="string", example="2025-12-17T04:06:53.000000Z")
     *                         )
     *                     )
     *                 ),
     *                 @OA\Property(property="no_order_dates", type="array",
     *                     description="Array of dates with no orders placed",
     *                     @OA\Items(type="string", example="2024-12-14")
     *                 ),
     *                 @OA\Property(property="complete_order", type="boolean", example=true, description="True if at least one order is completed on the requested date")
     *             )
     *         )
     *     )
     * )
     */
    public function getEndOfDate(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'date' => 'required|date',
        ]);

        $requestedDate = \Carbon\Carbon::parse($validated['date']);
        $requestedDateStr = $requestedDate->format('Y-m-d');
        $requestedDateEnd = $requestedDate->copy()->endOfDay();

        // Get all dates that have orders up to and including the requested date
        $ordersDates = Order::where('business_id', $businessId)
            ->where('created_at', '<=', $requestedDateEnd)
            ->selectRaw('DATE(created_at) as order_date')
            ->distinct()
            ->pluck('order_date')
            ->map(function ($date) {
                // Ensure consistent date format (Y-m-d)
                if ($date instanceof \Carbon\Carbon) {
                    return $date->format('Y-m-d');
                }
                if (is_string($date)) {
                    return \Carbon\Carbon::parse($date)->format('Y-m-d');
                }
                return $date;
            })
            ->toArray();

        // Get all dates that have EOD completed up to and including the requested date
        $eodDates = EndOfDay::where('business_id', $businessId)
            ->where('status', 'completed')
            ->where('eod_date', '<=', $requestedDateStr)
            ->get()
            ->map(function ($eod) {
                // Ensure consistent date format (Y-m-d)
                $date = $eod->eod_date;
                if ($date instanceof \Carbon\Carbon || $date instanceof \DateTime) {
                    return $date->format('Y-m-d');
                }
                if (is_string($date)) {
                    return \Carbon\Carbon::parse($date)->format('Y-m-d');
                }
                return $date;
            })
            ->unique()
            ->values()
            ->toArray();

        // Find pending EOD dates (dates with orders but no EOD)
        // This includes the requested date if it has orders but no EOD
        // Convert both arrays to strings for proper comparison
        $ordersDatesStr = array_map('strval', $ordersDates);
        $eodDatesStr = array_map('strval', $eodDates);
        $pendingEodDates = array_values(array_diff($ordersDatesStr, $eodDatesStr));

        // Remove today's date from pending dates array
        $todayDateStr = now()->format('Y-m-d');
        $pendingEodDates = array_values(array_filter($pendingEodDates, function ($date) use ($todayDateStr) {
            return $date !== $todayDateStr;
        }));

        // Sort dates in ascending order
        sort($pendingEodDates);

        // Get active orders (non-completed orders) with full employee details
        $activeOrders = Order::where('business_id', $businessId)
            ->where('status', '!=', 'completed')
            ->with('createdByEmployee')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($order) {
                return [
                    'id' => $order->id,
                    'order_ticket_id' => $order->order_ticket_id,
                    'status' => $order->status,
                    'created_at' => $order->created_at ? $order->created_at->format('Y-m-d H:i:s') : null,
                    'created_by_employee' => $order->createdByEmployee ? [
                        'id' => $order->createdByEmployee->id,
                        'business_id' => $order->createdByEmployee->business_id,
                        'first_name' => $order->createdByEmployee->first_name,
                        'last_name' => $order->createdByEmployee->last_name,
                        'email' => $order->createdByEmployee->email,
                        'image' => $order->createdByEmployee->image ?? '',
                        'avatar' => $order->createdByEmployee->avatar ?? '',
                        'is_active' => (bool) $order->createdByEmployee->is_active,
                        'created_at' => $order->createdByEmployee->created_at ? $order->createdByEmployee->created_at->format('Y-m-d\TH:i:s.000000\Z') : null,
                        'updated_at' => $order->createdByEmployee->updated_at ? $order->createdByEmployee->updated_at->format('Y-m-d\TH:i:s.000000\Z') : null,
                    ] : null,
                ];
            })
            ->toArray();

        // Find dates with no orders (from first order date to requested date, excluding requested date)
        $firstOrderDate = !empty($ordersDatesStr) ? min($ordersDatesStr) : $requestedDateStr;
        $noOrderDates = [];

        if (!empty($ordersDatesStr)) {
            $startDate = \Carbon\Carbon::parse($firstOrderDate);
            $endDate = $requestedDate->copy()->subDay(); // Exclude requested date

            for ($date = $startDate->copy(); $date->lte($endDate); $date->addDay()) {
                $dateStr = $date->format('Y-m-d');
                // If date has no orders and no EOD, add to no_order_dates
                if (!in_array($dateStr, $ordersDatesStr) && !in_array($dateStr, $eodDatesStr)) {
                    $noOrderDates[] = $dateStr;
                }
            }
        }

        // Check if at least one order is completed on the requested date
        $startOfDay = \Carbon\Carbon::parse($requestedDateStr)->startOfDay();
        $endOfDay = \Carbon\Carbon::parse($requestedDateStr)->endOfDay();
        $completedOrdersCount = Order::where('business_id', $businessId)
            ->whereBetween('created_at', [$startOfDay, $endOfDay])
            ->where('status', 'completed')
            ->count();
        $completeOrder = $completedOrdersCount > 0;

        return $this->successResponse([
            'pending_eod_dates' => $pendingEodDates,
            'active_orders' => $activeOrders,
            'no_order_dates' => $noOrderDates,
            'complete_order' => $completeOrder,
        ], 'End of date status retrieved successfully');
    }

    /**
     * @OA\Post(
     *     path="/pos/make-end-of-date",
     *     security={{"bearerAuth":{}}},
     *     tags={"POS API - Reports"},
     *     summary="Make End of Date",
     *     description="Set end of day for a specific date. Creates or updates EOD record with completed status. Validation rules: 1) Cannot make EOD if there are previous dates without EOD completion. 2) Cannot make EOD if there are active (non-completed) orders on the requested date. 3) Allowed if the date has no orders (e.g., Sunday with no orders).",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"date"},
     *             @OA\Property(property="date", type="string", format="date-time", example="2024-12-16 23:59:59", description="Today's date with time"),
     *             @OA\Property(property="notes", type="string", nullable=true, example="End of day completed successfully")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="End of date created successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="business_id", type="integer", example=1),
     *                 @OA\Property(property="eod_date", type="string", format="date", example="2024-12-16"),
     *                 @OA\Property(property="completed_at", type="string", format="date-time", example="2024-12-16 23:59:59"),
     *                 @OA\Property(property="status", type="string", example="completed"),
     *                 @OA\Property(property="total_sales", type="string", example="5000.00"),
     *                 @OA\Property(property="total_orders", type="integer", example=25),
     *                 @OA\Property(property="notes", type="string", nullable=true, example="End of day completed successfully"),
     *                 @OA\Property(property="completed_by_employee", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="business_id", type="integer", example=1),
     *                     @OA\Property(property="first_name", type="string", example="Katheryn"),
     *                     @OA\Property(property="last_name", type="string", example="Eichmann"),
     *                     @OA\Property(property="email", type="string", example="waiter1@nadiadrestaurant.com"),
     *                     @OA\Property(property="image", type="string", example=""),
     *                     @OA\Property(property="avatar", type="string", example="http://localhost:8000/assets/img/avtar2.png"),
     *                     @OA\Property(property="is_active", type="boolean", example=true),
     *                     @OA\Property(property="created_at", type="string", example="2025-12-16T07:18:44.000000Z"),
     *                     @OA\Property(property="updated_at", type="string", example="2025-12-17T04:06:53.000000Z")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Validation error. Possible errors: 1) Previous dates need EOD completion. 2) Active orders exist on requested date.",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Cannot make end of day. There are previous dates that need end of day completion: 2024-12-15, 2024-12-16")
     *         )
     *     )
     * )
     */
    public function makeEndOfDate(Request $request)
    {
        $employee = $request->user();
        $businessId = $employee?->business_id;

        if (!$businessId) {
            return $this->forbiddenResponse('Authenticated employee is not associated with a business');
        }

        $validated = $request->validate([
            'date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        $eodDateTime = \Carbon\Carbon::parse($validated['date']);
        $eodDate = $eodDateTime->format('Y-m-d');
        $completedAt = $eodDateTime->format('Y-m-d H:i:s');
        $startOfDay = \Carbon\Carbon::parse($eodDate)->startOfDay();
        $endOfDay = \Carbon\Carbon::parse($eodDate)->endOfDay();
        $requestedDateEnd = $eodDateTime->copy()->endOfDay();

        // VALIDATION 1: Check if there are any pending EOD dates BEFORE the requested date
        // Get all dates that have orders up to (but not including) the requested date
        $previousOrdersDates = Order::where('business_id', $businessId)
            ->where('created_at', '<', $startOfDay)
            ->selectRaw('DATE(created_at) as order_date')
            ->distinct()
            ->pluck('order_date')
            ->map(function ($date) {
                if ($date instanceof \Carbon\Carbon) {
                    return $date->format('Y-m-d');
                }
                if (is_string($date)) {
                    return \Carbon\Carbon::parse($date)->format('Y-m-d');
                }
                return $date;
            })
            ->toArray();

        // Get all dates that have EOD completed up to (but not including) the requested date
        $previousEodDates = EndOfDay::where('business_id', $businessId)
            ->where('status', 'completed')
            ->where('eod_date', '<', $eodDate)
            ->get()
            ->map(function ($eod) {
                $date = $eod->eod_date;
                if ($date instanceof \Carbon\Carbon || $date instanceof \DateTime) {
                    return $date->format('Y-m-d');
                }
                if (is_string($date)) {
                    return \Carbon\Carbon::parse($date)->format('Y-m-d');
                }
                return $date;
            })
            ->unique()
            ->values()
            ->toArray();

        // Find pending EOD dates BEFORE the requested date
        $previousOrdersDatesStr = array_map('strval', $previousOrdersDates);
        $previousEodDatesStr = array_map('strval', $previousEodDates);
        $previousPendingEodDates = array_values(array_diff($previousOrdersDatesStr, $previousEodDatesStr));

        if (!empty($previousPendingEodDates)) {
            sort($previousPendingEodDates);
            return $this->errorResponse(
                'Cannot make end of day. There are previous dates that need end of day completion: ' . implode(', ', $previousPendingEodDates),
                422
            );
        }

        // VALIDATION 2: Check if there are any active (non-completed) orders on the requested date
        $activeOrdersOnDate = Order::where('business_id', $businessId)
            ->whereBetween('created_at', [$startOfDay, $endOfDay])
            ->where('status', '!=', 'completed')
            ->count();

        if ($activeOrdersOnDate > 0) {
            return $this->errorResponse(
                "Cannot make end of day. There are {$activeOrdersOnDate} active (non-completed) order(s) on this date. Please complete all orders first.",
                422
            );
        }

        // VALIDATION 3: Check if the date has any orders at all
        $totalOrdersOnDate = Order::where('business_id', $businessId)
            ->whereBetween('created_at', [$startOfDay, $endOfDay])
            ->count();

        // If no orders on this date, it's allowed (like Sunday with no orders)
        // If there are orders, they must all be completed (already checked above)

        // Calculate total sales and orders for the day

        $orders = Order::where('business_id', $businessId)
            ->whereBetween('created_at', [$startOfDay, $endOfDay])
            ->where('status', 'completed')
            ->get();

        $totalSales = 0;
        foreach ($orders as $order) {
            $billAmounts = $this->calculateBillAmounts($order);
            $totalSales += $billAmounts['total_bill'];
        }

        $totalOrders = $orders->count();

        // Create or update EOD record
        $endOfDay = EndOfDay::with('completedByEmployee')->updateOrCreate(
            [
                'business_id' => $businessId,
                'eod_date' => $eodDate,
            ],
            [
                'completed_at' => $completedAt,
                'completed_by_employee_id' => $employee->id,
                'status' => 'completed',
                'total_sales' => round($totalSales, 2),
                'total_orders' => $totalOrders,
                'notes' => $validated['notes'] ?? null,
            ]
        );

        // Reload to get the relationship
        $endOfDay->load('completedByEmployee');

        return $this->successResponse([
            'id' => $endOfDay->id,
            'business_id' => $endOfDay->business_id,
            'eod_date' => $endOfDay->eod_date->format('Y-m-d'),
            'completed_at' => $endOfDay->completed_at->format('Y-m-d H:i:s'),
            'status' => $endOfDay->status,
            'total_sales' => number_format($endOfDay->total_sales, 2, '.', ''),
            'total_orders' => $endOfDay->total_orders,
            'notes' => $endOfDay->notes,
            'completed_by_employee' => $endOfDay->completedByEmployee ? [
                'id' => $endOfDay->completedByEmployee->id,
                'business_id' => $endOfDay->completedByEmployee->business_id,
                'first_name' => $endOfDay->completedByEmployee->first_name,
                'last_name' => $endOfDay->completedByEmployee->last_name,
                'email' => $endOfDay->completedByEmployee->email,
                'image' => $endOfDay->completedByEmployee->image ?? '',
                'avatar' => $endOfDay->completedByEmployee->avatar ?? '',
                'is_active' => (bool) $endOfDay->completedByEmployee->is_active,
                'created_at' => $endOfDay->completedByEmployee->created_at ? $endOfDay->completedByEmployee->created_at->format('Y-m-d\TH:i:s.000000\Z') : null,
                'updated_at' => $endOfDay->completedByEmployee->updated_at ? $endOfDay->completedByEmployee->updated_at->format('Y-m-d\TH:i:s.000000\Z') : null,
            ] : null,
        ], 'End of date created successfully');
    }

    /**
     * Convert thermal format text to HTML format
     */
    private function convertThermalToHtml($thermalFormat, $businessName, $reportTitle = null)
    {
        $lines = explode("\n", $thermalFormat);
        $html = '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>' . htmlspecialchars($reportTitle ?? 'Report') . '</title>
    <style>
        body {
            font-family: monospace;
            background: #f4f4f4;
            padding: 20px;
        }
        .receipt {
            width: 380px;
            margin: auto;
            background: #fff;
            padding: 15px;
            border: 1px solid #ddd;
        }
        .center {
            text-align: center;
        }
        .line {
            border-top: 1px dashed #000;
            margin: 10px 0;
        }
        .section-title {
            font-weight: bold;
            margin-top: 10px;
        }
        .row {
            display: flex;
            justify-content: space-between;
            margin: 2px 0;
        }
        .footer {
            text-align: center;
            margin-top: 15px;
            font-weight: bold;
        }
    </style>
</head>
<body>
<div class="receipt">';

        $inHeader = true;
        $headerStarted = false;

        foreach ($lines as $index => $line) {
            $line = rtrim($line);
            $originalLine = $line;
            $trimmedLine = trim($line);

            // Skip empty lines at the start
            if ($inHeader && empty($trimmedLine)) {
                continue;
            }

            // Detect header section (centered lines with business name, report title, dates)
            if ($inHeader) {
                // Check if line is centered (padded with spaces) or contains header info
                $isCentered = (strlen($line) > 0 && preg_match('/^[\s]+.+\s+$/', $line)) ||
                    (strlen($trimmedLine) <= 32 && (
                        stripos($trimmedLine, $businessName) !== false ||
                        stripos($trimmedLine, 'REPORT') !== false ||
                        stripos($trimmedLine, 'BILL') !== false ||
                        preg_match('/\d{2}\/\d{2}\/\d{4}/', $trimmedLine) ||
                        preg_match('/\d{2}:\d{2}:\d{2}/', $trimmedLine)
                    ));

                if ($isCentered && !preg_match('/^[\-]+$/', $trimmedLine)) {
                    if (!$headerStarted) {
                        $html .= '<div class="center">';
                        $headerStarted = true;
                    }
                    if (stripos($trimmedLine, $businessName) !== false) {
                        $html .= '<h3>' . htmlspecialchars($trimmedLine) . '</h3>';
                    } elseif (stripos($trimmedLine, 'REPORT') !== false || stripos($trimmedLine, 'BILL') !== false) {
                        $html .= '<strong>' . htmlspecialchars($trimmedLine) . '</strong><br>';
                    } else {
                        $html .= '<div>' . htmlspecialchars($trimmedLine) . '</div>';
                    }
                    continue;
                }
            }

            // Close header when we hit a separator
            if ($inHeader && (strpos($line, str_repeat('-', 32)) !== false || preg_match('/^[\-]+$/', $trimmedLine))) {
                if ($headerStarted) {
                    $html .= '</div>';
                    $headerStarted = false;
                }
                $html .= '<div class="line"></div>';
                $inHeader = false;
                continue;
            }

            // Handle separator lines
            if (strpos($line, str_repeat('-', 32)) !== false || preg_match('/^[\-]+$/', $trimmedLine)) {
                $html .= '<div class="line"></div>';
                continue;
            }

            // Handle section titles (all caps, ends with colon)
            if (preg_match('/^[A-Z\s\/]+:$/', $trimmedLine)) {
                $html .= '<div class="section-title">' . htmlspecialchars($trimmedLine) . '</div>';
                continue;
            }

            // Handle lines with key: value format (e.g., "  Guests: 43")
            if (preg_match('/^[\s]*([^:]+):[\s]*(.+)$/', $line, $matches)) {
                $key = trim($matches[1]);
                $value = trim($matches[2]);
                $isBold = (stripos($key, 'total') !== false || stripos($key, 'end') !== false ||
                    stripos($key, 'TOTALS') !== false);
                $keyTag = $isBold ? '<strong>' : '<span>';
                $keyClose = $isBold ? '</strong>' : '</span>';
                $valueTag = $isBold ? '<strong>' : '<span>';
                $valueClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $keyTag . htmlspecialchars($key) . $keyClose . '<span>' . htmlspecialchars($value) . '</span></div>';
                continue;
            }

            // Handle lines with multiple values (e.g., "  Cash: QTY 0, Tips 0.00, Total 0.00")
            if (preg_match('/^[\s]*([^:]+):[\s]*(.+)$/', $line, $matches)) {
                $key = trim($matches[1]);
                $values = trim($matches[2]);
                $isBold = (stripos($key, 'total') !== false || stripos($key, 'TOTALS') !== false);
                $keyTag = $isBold ? '<strong>' : '<span>';
                $keyClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $keyTag . htmlspecialchars($key) . $keyClose . '<span>' . htmlspecialchars($values) . '</span></div>';
                continue;
            }

            // Handle lines with name and values (e.g., "  JAYESH NAKTE Sales 233.00, Tips 60.36")
            if (preg_match('/^[\s]*([A-Z\s]+)[\s]+(Sales|Tips|QTY|Total)[\s]+(.+)$/i', $line, $matches)) {
                $name = trim($matches[1]);
                $rest = trim(substr($line, strlen($matches[0]) - strlen($matches[3])));
                $isBold = (stripos($name, 'TOTALS') !== false);
                $nameTag = $isBold ? '<strong>' : '<span>';
                $nameClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $nameTag . htmlspecialchars($name) . $nameClose . '<span>' . htmlspecialchars($rest) . '</span></div>';
                continue;
            }

            // Handle lines with two parts separated by multiple spaces (left-right alignment)
            // This handles lines like "  CASH ON HAND: 1328.00" or "  TOTALS Sales 468.50, Tips 97.36"
            if (preg_match('/^[\s]*([^\s].*?)[\s]{2,}(.+)$/', $line, $matches)) {
                $left = trim($matches[1]);
                $right = trim($matches[2]);
                $isBold = (stripos($left, 'total') !== false || stripos($left, 'TOTALS') !== false ||
                    stripos($left, 'end') !== false);
                $leftTag = $isBold ? '<strong>' : '<span>';
                $leftClose = $isBold ? '</strong>' : '</span>';
                $rightTag = $isBold ? '<strong>' : '<span>';
                $rightClose = $isBold ? '</strong>' : '</span>';
                $html .= '<div class="row">' . $leftTag . htmlspecialchars($left) . $leftClose . $rightTag . htmlspecialchars($right) . $rightClose . '</div>';
                continue;
            }

            // Handle simple lines (centered footer, etc.)
            if (!empty($trimmedLine)) {
                if (stripos($trimmedLine, 'END') !== false && (stripos($trimmedLine, 'REPORT') !== false ||
                    stripos($trimmedLine, 'BILL') !== false)) {
                    $html .= '<div class="footer">' . htmlspecialchars($trimmedLine) . '</div>';
                } else {
                    $html .= '<div>' . htmlspecialchars($trimmedLine) . '</div>';
                }
            } else {
                $html .= '<br>';
            }
        }

        $html .= '</div>
</body>
</html>';

        return $html;
    }
}