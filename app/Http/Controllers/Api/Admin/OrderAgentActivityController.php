<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Admin\BaseAdminController;
use App\Models\Business;
use App\Models\Employee;
use App\Models\Order;
use App\Models\OrderAccessLog;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\View;
use Barryvdh\DomPDF\Facade\Pdf;

class OrderAgentActivityController extends BaseAdminController
{
    use ApiResponse;

    /**
     * Generate Order Agent Activity Summary Report
     *
     * This report shows employee activity on orders including:
     * - Total orders accessed per employee
     * - Active orders (currently being served)
     * - Total time spent on orders
     * - Average time per order
     * - Orders by status
     */
    public function summary(Request $request)
    {
        $businessId = $this->currentBusinessId($request);

        $validated = $request->validate([
            'date' => 'nullable|date_format:Y-m-d',
            'employee_id' => 'nullable|integer|exists:employees,id',
            'format' => 'nullable|string|in:json,html,pdf',
        ]);

        $reportDate = $validated['date'] ?? now()->format('Y-m-d');
        $employeeId = $validated['employee_id'] ?? null;
        $format = $validated['format'] ?? 'json';

        $business = Business::find($businessId);
        $businessName = $business->name ?? 'Restaurant';

        // Get date range for the report
        $startOfDay = Carbon::parse($reportDate)->startOfDay();
        $endOfDay = Carbon::parse($reportDate)->endOfDay();

        // Build base query for order_access_logs
        $logsQuery = OrderAccessLog::with([
            'employee',
            'order.table',
            'order.createdByEmployee',
            'order.checks.orderItems.menuItem',
            'order.paymentHistories.employee'
        ])
            ->whereHas('order', function ($query) use ($businessId) {
                $query->where('business_id', $businessId);
            })
            ->whereBetween('start_date', [$startOfDay, $endOfDay]);

        if ($employeeId) {
            $logsQuery->where('employee_id', $employeeId);
        }

        $logs = $logsQuery->get();

        // Group by employee
        $employeeActivity = [];
        $totalOrders = 0;
        $totalActiveOrders = 0;
        $totalTimeMinutes = 0;
        $totalCompletedSessions = 0;

        foreach ($logs as $log) {
            $empId = $log->employee_id;
            $empName = $log->employee
                ? trim($log->employee->first_name . ' ' . $log->employee->last_name)
                : 'Unknown Employee';

            if (!isset($employeeActivity[$empId])) {
                $employeeActivity[$empId] = [
                    'employee_id' => $empId,
                    'employee_name' => $empName,
                    'total_orders' => 0,
                    'active_orders' => 0,
                    'completed_sessions' => 0,
                    'total_time_minutes' => 0,
                    'avg_time_per_order' => 0,
                    'orders' => [],
                ];
            }

            // Count unique orders
            $orderId = $log->order_id;
            if (!in_array($orderId, $employeeActivity[$empId]['orders'])) {
                $employeeActivity[$empId]['orders'][] = $orderId;
                $employeeActivity[$empId]['total_orders']++;
                $totalOrders++;
            }

            // Check if active (end_date is null)
            if ($log->end_date === null) {
                $employeeActivity[$empId]['active_orders']++;
                $totalActiveOrders++;
            } else {
                // Calculate time spent for completed sessions
                $startTime = Carbon::parse($log->start_date);
                $endTime = Carbon::parse($log->end_date);
                $minutes = $startTime->diffInMinutes($endTime);

                $employeeActivity[$empId]['completed_sessions']++;
                $employeeActivity[$empId]['total_time_minutes'] += $minutes;
                $totalTimeMinutes += $minutes;
                $totalCompletedSessions++;
            }
        }

        // Calculate averages and format data
        $result = [];
        foreach ($employeeActivity as $empId => $data) {
            $avgTime = $data['completed_sessions'] > 0
                ? $data['total_time_minutes'] / $data['completed_sessions']
                : 0;

            $result[] = [
                'employee_id' => $data['employee_id'],
                'employee_name' => $data['employee_name'],
                'total_orders' => $data['total_orders'],
                'active_orders' => $data['active_orders'],
                'total_time_minutes' => number_format($data['total_time_minutes'], 2, '.', ''),
            ];
        }

        // Sort by total_orders descending
        usort($result, function ($a, $b) {
            return $b['total_orders'] - $a['total_orders'];
        });

        // Calculate totals
        $avgTimeOverall = $totalCompletedSessions > 0
            ? $totalTimeMinutes / $totalCompletedSessions
            : 0;

        $totals = [
            'total_employees' => count($result),
            'total_orders' => $totalOrders,
            'total_active_orders' => $totalActiveOrders,
            'total_completed_sessions' => $totalCompletedSessions,
            'total_time_minutes' => number_format($totalTimeMinutes, 2, '.', ''),
            'total_time_hours' => number_format($totalTimeMinutes / 60, 2, '.', ''),
            'avg_time_per_session_minutes' => number_format($avgTimeOverall, 2, '.', ''),
            'avg_time_per_session_hours' => number_format($avgTimeOverall / 60, 2, '.', ''),
        ];

        // Get detailed order list grouped by status (open first, then closed)
        $orderDetails = $this->getOrderDetailsByStatus($logs, $businessId);

        // Check if there's any activity
        $hasActivity = count($result) > 0 || count($orderDetails['open_orders']) > 0 || count($orderDetails['closed_orders']) > 0;

        // Prepare data for view
        $viewData = [
            'businessName' => $businessName,
            'issuedAt' => now()->format('m/d/Y h:i A'),
            'businessDates' => Carbon::parse($reportDate)->format('m/d/Y'),
            'hasActivity' => $hasActivity,
            'employeeActivity' => $result,
            'totals' => $totals,
            'orderDetails' => $orderDetails,
            'isPdf' => $format === 'pdf',
        ];

        // Handle different response formats
        if ($format === 'html') {
            $html = View::make('reports.html.order-agent-activity', $viewData)->render();
            return response($html, 200)
                ->header('Content-Type', 'text/html; charset=utf-8');
        } elseif ($format === 'pdf') {
            $html = View::make('reports.html.order-agent-activity', $viewData)->render();
            // Remove any leading/trailing whitespace that could cause blank pages
            $html = trim($html);
            $pdf = Pdf::loadHTML($html);
            $pdf->setPaper('a4', 'portrait');
            $pdf->setOption('enable-local-file-access', true);
            $pdf->setOption('isRemoteEnabled', true);
            $pdf->setOption('margin-top', 10);
            $pdf->setOption('margin-bottom', 10);
            $pdf->setOption('margin-left', 10);
            $pdf->setOption('margin-right', 10);
            $pdf->setOption('dpi', 150);

            $filename = 'order-agent-activity-report-' . $reportDate . '.pdf';
            return $pdf->stream($filename, ['Attachment' => false]);
        }

        // Default: return JSON response
        return $this->successResponse([
            'business_name' => $businessName,
            'report_date' => Carbon::parse($reportDate)->format('m/d/Y'),
            'issued_at' => now()->format('m/d/Y h:i A'),
            'business_dates' => Carbon::parse($reportDate)->format('m/d/Y'),
            'has_activity' => $hasActivity,
            'employee_activity' => $result,
            'totals' => $totals,
            'order_details' => $orderDetails,
            'html_view' => View::make('reports.html.order-agent-activity', $viewData)->render(),
        ], 'Order Agent Activity Summary Report generated successfully');
    }

    /**
     * Get detailed order information grouped by status (open first, then closed)
     */
    private function getOrderDetailsByStatus($logs, $businessId)
    {
        $ordersData = [];
        $openOrders = [];
        $closedOrders = [];

        // Group logs by order
        foreach ($logs as $log) {
            $order = $log->order;
            if (!$order) {
                continue;
            }

            $orderId = $order->id;

            if (!isset($ordersData[$orderId])) {
                // Calculate order total from order items
                $orderTotal = 0;
                $orderItemsCount = 0;
                foreach ($order->checks as $check) {
                    foreach ($check->orderItems as $item) {
                        if ($item->order_status != 3) { // Not voided
                            $itemTotal = (float) $item->unit_price * (int) $item->qty;
                            $discountAmount = (float) ($item->discount_amount ?? 0);
                            $orderTotal += ($itemTotal - $discountAmount);
                            $orderItemsCount++;
                        }
                    }
                }

                // Calculate payment total and format payment histories
                $paymentTotal = 0;
                $paymentHistoriesList = [];

                // Get payment histories sorted by created_at (chronological order)
                $paymentHistories = $order->paymentHistories->sortBy('created_at');

                foreach ($paymentHistories as $payment) {
                    $amount = (float) ($payment->amount ?? 0);
                    $paymentTotal += $amount;

                    $mode = strtolower($payment->payment_mode ?? '');
                    $paymentLabel = ucfirst($mode);
                    if ($mode === 'card') {
                        $paymentLabel = 'Card';
                    } elseif ($mode === 'cash') {
                        $paymentLabel = 'Cash';
                    } elseif ($mode === 'online') {
                        $paymentLabel = 'Online';
                    }

                    // Check if this is a refund: status='refunded' OR refunded_payment_id points to another payment
                    $isRefund = ($payment->status === 'refunded') || (($payment->refunded_payment_id ?? 0) !== 0);

                    // Get employee who processed the payment/refund
                    $paymentEmployee = $payment->employee;
                    $paymentEmployeeName = $paymentEmployee
                        ? trim($paymentEmployee->first_name . ' ' . $paymentEmployee->last_name)
                        : 'Unknown';

                    $paymentHistoriesList[] = [
                        'id' => $payment->id,
                        'payment_mode' => $paymentLabel,
                        'amount' => number_format($amount, 2, '.', ''),
                        'tip_amount' => number_format((float) ($payment->tip_amount ?? 0), 2, '.', ''),
                        'status' => $payment->status,
                        'is_refund' => $isRefund,
                        'payment_is_refund' => (bool) ($payment->payment_is_refund ?? false),
                        'refunded_payment_id' => $payment->refunded_payment_id ?? 0,
                        'refund_reason' => $payment->refund_reason ?? '',
                        'comment' => $payment->comment ?? '',
                        'employee_id' => $payment->employee_id,
                        'employee_name' => $paymentEmployeeName,
                        'created_at' => Carbon::parse($payment->created_at)->format('m/d/Y h:i A'),
                    ];
                }

                // Determine simplified status
                $simpleStatus = ($order->status === 'completed' || $order->status === 'closed') ? 'Closed' : 'Open';

                $ordersData[$orderId] = [
                    'order_id' => $order->id,
                    'order_ticket_id' => $order->order_ticket_id,
                    'order_ticket_title' => $order->order_ticket_title,
                    'status' => $simpleStatus,
                    'original_status' => $order->status,
                    'created_at' => Carbon::parse($order->created_at)->format('m/d/Y h:i A'),
                    'created_by_employee' => $order->createdByEmployee
                        ? trim($order->createdByEmployee->first_name . ' ' . $order->createdByEmployee->last_name)
                        : 'Unknown',
                    'table_name' => $order->table ? $order->table->name : 'N/A',
                    'customer_count' => $order->customer ?? 0,
                    'order_items_count' => $orderItemsCount,
                    'order_total' => number_format($orderTotal, 2, '.', ''),
                    'payment_total' => number_format($paymentTotal, 2, '.', ''),
                    'payment_histories' => $paymentHistoriesList,
                    'employee_activities' => [],
                ];
            }

            // Add employee activity for this order
            $employee = $log->employee;
            $empName = $employee
                ? trim($employee->first_name . ' ' . $employee->last_name)
                : 'Unknown Employee';

            $startTime = Carbon::parse($log->start_date);
            $endTime = $log->end_date ? Carbon::parse($log->end_date) : null;
            $durationMinutes = $endTime ? $startTime->diffInMinutes($endTime) : null;

            // Get individual order items for this employee (items where employee_id matches)
            // order_status: 0=HOLD, 1=FIRE, 2=TEMP (not needed), 3=VOID
            // Group items by name to avoid duplicates
            $sessionOrderItemsGrouped = [];

            foreach ($order->checks as $check) {
                foreach ($check->orderItems as $item) {
                    // Get items where employee_id matches this session's employee
                    if ($item->employee_id == $log->employee_id) {
                        $itemStatus = (int) $item->order_status;

                        // Skip TEMP status (2)
                        if ($itemStatus == 2) {
                            continue;
                        }

                        $itemName = $item->menuItem ? $item->menuItem->name : 'Unknown Item';
                        $itemQty = (int) $item->qty;

                        // Calculate amount
                        $itemTotal = (float) $item->unit_price * $itemQty;
                        $discountAmount = (float) ($item->discount_amount ?? 0);
                        $itemAmount = $itemStatus != 3 ? ($itemTotal - $discountAmount) : 0;

                        // Determine status flags
                        $isHold = $itemStatus == 0 ? 'yes' : '-';
                        $isFire = $itemStatus == 1 ? 'yes' : '-';
                        $isVoid = $itemStatus == 3 ? 'yes' : '-';

                        // Group by item name - combine quantities and amounts
                        if (!isset($sessionOrderItemsGrouped[$itemName])) {
                            $sessionOrderItemsGrouped[$itemName] = [
                                'item_name' => $itemName,
                                'qty' => 0,
                                'hold' => '-',
                                'fire' => '-',
                                'void' => '-',
                                'amount' => 0,
                            ];
                        }

                        // Combine quantities
                        $sessionOrderItemsGrouped[$itemName]['qty'] += $itemQty;

                        // Set status flags (if any is 'yes', keep it as 'yes')
                        if ($isHold === 'yes') {
                            $sessionOrderItemsGrouped[$itemName]['hold'] = 'yes';
                        }
                        if ($isFire === 'yes') {
                            $sessionOrderItemsGrouped[$itemName]['fire'] = 'yes';
                        }
                        if ($isVoid === 'yes') {
                            $sessionOrderItemsGrouped[$itemName]['void'] = 'yes';
                        }

                        // Combine amounts
                        $sessionOrderItemsGrouped[$itemName]['amount'] += $itemAmount;
                    }
                }
            }

            // Convert grouped array to list and format amounts
            $sessionOrderItems = [];
            foreach ($sessionOrderItemsGrouped as $itemName => $itemData) {
                $sessionOrderItems[] = [
                    'item_name' => $itemData['item_name'],
                    'qty' => $itemData['qty'],
                    'hold' => $itemData['hold'],
                    'fire' => $itemData['fire'],
                    'void' => $itemData['void'],
                    'amount' => number_format($itemData['amount'], 2, '.', ''),
                ];
            }


            $ordersData[$orderId]['employee_activities'][] = [
                'employee_id' => $log->employee_id,
                'employee_name' => $empName,
                'start_date' => $startTime->format('m/d/Y h:i A'),
                'end_date' => $endTime ? $endTime->format('m/d/Y h:i A') : 'Active',
                'duration_minutes' => $durationMinutes ? (int) round($durationMinutes) : 0,
                'duration_hours' => $durationMinutes ? number_format($durationMinutes / 60, 2, '.', '') : 'N/A',
                'is_active' => $log->end_date === null,
                'order_items' => $sessionOrderItems,
            ];
        }

        // Separate into open and closed orders
        foreach ($ordersData as $orderId => $orderData) {
            if ($orderData['status'] === 'Closed') {
                $closedOrders[] = $orderData;
            } else {
                $openOrders[] = $orderData;
            }
        }

        // Sort open orders by created_at (newest first)
        usort($openOrders, function ($a, $b) {
            return strtotime($b['created_at']) - strtotime($a['created_at']);
        });

        // Sort closed orders by created_at (newest first)
        usort($closedOrders, function ($a, $b) {
            return strtotime($b['created_at']) - strtotime($a['created_at']);
        });

        return [
            'open_orders' => $openOrders,
            'closed_orders' => $closedOrders,
            'total_open_orders' => count($openOrders),
            'total_closed_orders' => count($closedOrders),
        ];
    }
}