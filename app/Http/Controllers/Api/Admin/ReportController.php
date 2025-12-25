<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\Admin\BaseAdminController;
use App\Models\Business;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\PaymentHistory;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\View;
use Barryvdh\DomPDF\Facade\Pdf;

class ReportController extends BaseAdminController
{
    use ApiResponse;

    /**
     * Generate Daily Summary Report
     *
     * This is a comprehensive business report (not a thermal receipt) that includes:
     * - Sales by Department/Sub-department
     * - Sales by Daypart/Shift
     * - Revenue Centers
     * - Order Type breakdown
     * - Exceptions (Comps, Voids)
     * - Payments breakdown
     * - Cash Summary
     * - Tips & Cash Balance
     * - Taxes
     */
    public function dailySummary(Request $request)
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

        // Build base query
        $ordersQuery = Order::where('business_id', $businessId)
            ->whereBetween('created_at', [$startOfDay, $endOfDay]);

        if ($employeeId) {
            $ordersQuery->where('created_by_employee_id', $employeeId);
        }

        $orders = $ordersQuery->with([
            'checks.orderItems' => function ($query) {
                $query->where('order_status', '!=', 3); // Exclude voided items
            },
            'checks.orderItems.modifiers',
            'checks.orderItems.menuItem.menuCategory',
            'createdByEmployee',
            'paymentHistories',
        ])->get();

        $closedOrders = $orders->where('status', 'completed');
        $openOrders = $orders->where('status', '!=', 'completed');

        // Check if there are any completed orders
        $hasCompletedOrders = $closedOrders->count() > 0;

        // Calculate all report sections
        $salesByDept = $this->calculateSalesByDepartment($orders);
        $salesByDaypart = $this->calculateSalesByDaypart($orders);
        $revenueCenters = $this->calculateRevenueCenters($orders);
        $orderType = $this->calculateOrderType($orders);
        $exceptions = $this->calculateExceptions($orders);
        $payments = $this->calculatePaymentsDetailed($orders);
        $cashSummary = $this->calculateCashSummaryDetailed($orders);
        $tipsCashBalance = $this->calculateTipsCashBalance($orders);
        $taxes = $this->calculateTaxes($orders);
        $taxSummary = $this->calculateTaxSummary($orders);
        $taxExemptions = $this->calculateTaxExemptions($orders);

        // Check if all values are zero (no activity)
        $hasActivity = $hasCompletedOrders ||
            (float) str_replace(',', '', $salesByDept['totals']['gross_sales']) > 0 ||
            (float) str_replace(',', '', $salesByDaypart['totals']['gross_sales']) > 0;

        // Prepare data for view
        $viewData = [
            'businessName' => $businessName,
            'issuedAt' => now()->format('m/d/Y h:i A'),
            'businessDates' => Carbon::parse($reportDate)->format('m/d/Y'),
            'hasActivity' => $hasActivity,
            'salesByDept' => $salesByDept,
            'salesByDaypart' => $salesByDaypart,
            'revenueCenters' => $revenueCenters,
            'orderType' => $orderType,
            'exceptions' => $exceptions,
            'payments' => $payments,
            'cashSummary' => $cashSummary,
            'tipsCashBalance' => $tipsCashBalance,
            'taxes' => $taxes,
            'taxSummary' => $taxSummary,
            'taxExemptions' => $taxExemptions,
        ];

        // Handle different response formats
        if ($format === 'html') {
            $html = View::make('reports.html.daily-summary', $viewData)->render();
            return response($html, 200)
                ->header('Content-Type', 'text/html; charset=utf-8');
        } elseif ($format === 'pdf') {
            $html = View::make('reports.html.daily-summary', $viewData)->render();
            $pdf = Pdf::loadHTML($html);
            $pdf->setPaper('a4', 'portrait');
            $pdf->setOption('enable-local-file-access', true);
            $pdf->setOption('isRemoteEnabled', true);

            $filename = 'daily-summary-report-' . $reportDate . '.pdf';
            return $pdf->stream($filename, ['Attachment' => false]);
        }

        // Default: return JSON response
        return $this->successResponse([
            'business_name' => $businessName,
            'report_date' => Carbon::parse($reportDate)->format('m/d/Y'),
            'issued_at' => now()->format('m/d/Y h:i A'),
            'business_dates' => Carbon::parse($reportDate)->format('m/d/Y'),
            'has_activity' => $hasActivity,
            'sales_by_dept' => $salesByDept,
            'sales_by_daypart' => $salesByDaypart,
            'revenue_centers' => $revenueCenters,
            'order_type' => $orderType,
            'exceptions' => $exceptions,
            'payments' => $payments,
            'cash_summary' => $cashSummary,
            'tips_cash_balance' => $tipsCashBalance,
            'taxes' => $taxes,
            'tax_summary' => $taxSummary,
            'tax_exemptions' => $taxExemptions,
            'html_view' => View::make('reports.html.daily-summary', $viewData)->render(),
        ], 'Daily Summary Report generated successfully');
    }

    /**
     * Calculate Sales by Department/Sub-department
     */
    private function calculateSalesByDepartment($orders)
    {
        $deptData = [];
        $totalGrossSales = 0;
        $totalNetSales = 0;
        $totalTax = 0;
        $totalComps = 0;
        $totalVoids = 0;

        // Get all order items with their categories
        foreach ($orders as $order) {
            foreach ($order->checks as $check) {
                foreach ($check->orderItems as $item) {
                    if ($item->order_status == 3) { // Voided
                        $voidAmount = (float) $item->unit_price * (int) $item->qty;
                        $totalVoids += $voidAmount;
                        continue;
                    }

                    $category = $item->menuItem->menuCategory ?? null;
                    $deptName = $category ? ($category->parent ? $category->parent->name : $category->name) : 'Uncategorized';
                    $subDeptName = $category && $category->parent ? $category->name : null;

                    $itemTotal = (float) $item->unit_price * (int) $item->qty;
                    $discountAmount = (float) ($item->discount_amount ?? 0);
                    $netSales = $itemTotal - $discountAmount;

                    if (!isset($deptData[$deptName])) {
                        $deptData[$deptName] = [
                            'name' => $deptName,
                            'gross_sales' => 0,
                            'net_sales' => 0,
                            'tax' => 0,
                            'comps' => 0,
                            'voids' => 0,
                            'sub_departments' => [],
                        ];
                    }

                    $deptData[$deptName]['gross_sales'] += $itemTotal;
                    $deptData[$deptName]['net_sales'] += $netSales;
                    $deptData[$deptName]['comps'] += $discountAmount;

                    if ($subDeptName) {
                        if (!isset($deptData[$deptName]['sub_departments'][$subDeptName])) {
                            $deptData[$deptName]['sub_departments'][$subDeptName] = [
                                'name' => $subDeptName,
                                'gross_sales' => 0,
                                'net_sales' => 0,
                                'tax' => 0,
                                'comps' => 0,
                            ];
                        }
                        $deptData[$deptName]['sub_departments'][$subDeptName]['gross_sales'] += $itemTotal;
                        $deptData[$deptName]['sub_departments'][$subDeptName]['net_sales'] += $netSales;
                        $deptData[$deptName]['sub_departments'][$subDeptName]['comps'] += $discountAmount;
                    }

                    $totalGrossSales += $itemTotal;
                    $totalNetSales += $netSales;
                    $totalComps += $discountAmount;
                }
            }
        }

        // Calculate tax (assuming tax is on order level)
        foreach ($orders as $order) {
            if ($order->status == 'completed') {
                $taxAmount = (float) ($order->tax_value ?? 0);
                $totalTax += $taxAmount;
                // Distribute tax proportionally (simplified)
                foreach ($deptData as $deptName => &$dept) {
                    if ($totalGrossSales > 0) {
                        $dept['tax'] += ($dept['gross_sales'] / $totalGrossSales) * $taxAmount;
                    }
                }
            }
        }

        // Format data
        $result = [];
        foreach ($deptData as $deptName => $dept) {
            $grossSales = (float) $dept['gross_sales'];
            $netSales = (float) $dept['net_sales'];
            $tax = (float) $dept['tax'];
            $comps = (float) $dept['comps'];
            $voids = (float) $dept['voids'];

            $formattedDept = [
                'name' => $deptName,
                'gross_sales' => number_format($grossSales, 2, '.', ''),
                'net_sales' => number_format($netSales, 2, '.', ''),
                'tax' => number_format($tax, 2, '.', ''),
                'comps' => number_format($comps, 2, '.', ''),
                'voids' => number_format($voids, 2, '.', ''),
                'gross_sales_percent' => $totalGrossSales > 0 ? number_format(($grossSales / $totalGrossSales) * 100, 2, '.', '') : '0.00',
                'net_sales_percent' => $totalNetSales > 0 ? number_format(($netSales / $totalNetSales) * 100, 2, '.', '') : '0.00',
            ];

            // Format sub-departments
            $subDepts = [];
            foreach ($dept['sub_departments'] as $subDeptName => $subDept) {
                $subDepts[] = [
                    'name' => $subDeptName,
                    'gross_sales' => number_format((float) $subDept['gross_sales'], 2, '.', ''),
                    'net_sales' => number_format((float) $subDept['net_sales'], 2, '.', ''),
                    'tax' => number_format((float) $subDept['tax'], 2, '.', ''),
                    'comps' => number_format((float) $subDept['comps'], 2, '.', ''),
                ];
            }
            $formattedDept['sub_departments'] = $subDepts;
            $result[] = $formattedDept;
        }

        return [
            'departments' => $result,
            'totals' => [
                'gross_sales' => number_format($totalGrossSales, 2, '.', ''),
                'net_sales' => number_format($totalNetSales, 2, '.', ''),
                'tax' => number_format($totalTax, 2, '.', ''),
                'comps' => number_format($totalComps, 2, '.', ''),
                'voids' => number_format($totalVoids, 2, '.', ''),
                'gross_sales_percent' => '100.00',
                'net_sales_percent' => '100.00',
            ],
        ];
    }

    /**
     * Calculate Sales by Daypart/Shift
     */
    private function calculateSalesByDaypart($orders)
    {
        $dayparts = [
            'Lunch' => ['start' => 11, 'end' => 16],
            'Dinner' => ['start' => 16, 'end' => 23],
            'Breakfast' => ['start' => 6, 'end' => 11],
            'Late Night' => ['start' => 23, 'end' => 6],
        ];

        $daypartData = [];
        $totalGrossSales = 0;
        $totalNetSales = 0;
        $totalComps = 0;
        $totalOrders = 0;
        $totalGuests = 0;
        $totalFees = 0;

        foreach ($orders as $order) {
            $orderHour = Carbon::parse($order->created_at)->hour;
            $daypartName = 'Dinner'; // Default

            foreach ($dayparts as $name => $times) {
                if ($times['start'] < $times['end']) {
                    if ($orderHour >= $times['start'] && $orderHour < $times['end']) {
                        $daypartName = $name;
                        break;
                    }
                } else {
                    // Late Night spans midnight
                    if ($orderHour >= $times['start'] || $orderHour < $times['end']) {
                        $daypartName = $name;
                        break;
                    }
                }
            }

            if (!isset($daypartData[$daypartName])) {
                $daypartData[$daypartName] = [
                    'name' => $daypartName,
                    'gross_sales' => 0,
                    'net_sales' => 0,
                    'comps' => 0,
                    'fees' => 0,
                    'orders' => 0,
                    'guests' => 0,
                ];
            }

            $orderGross = $this->calculateOrderGross($order);
            $orderNet = $this->calculateOrderNet($order);
            $orderComps = $this->calculateOrderComps($order);
            $orderFees = (float) ($order->fee_value ?? 0);

            $daypartData[$daypartName]['gross_sales'] += $orderGross;
            $daypartData[$daypartName]['net_sales'] += $orderNet;
            $daypartData[$daypartName]['comps'] += $orderComps;
            $daypartData[$daypartName]['fees'] += $orderFees;
            $daypartData[$daypartName]['orders']++;
            $daypartData[$daypartName]['guests'] += $this->getOrderGuests($order);

            $totalGrossSales += $orderGross;
            $totalNetSales += $orderNet;
            $totalComps += $orderComps;
            $totalFees += $orderFees;
            $totalOrders++;
            $totalGuests += $this->getOrderGuests($order);
        }

        // Format data
        $result = [];
        foreach ($daypartData as $daypart) {
            $daypart['gross_sales'] = number_format($daypart['gross_sales'], 2, '.', '');
            $daypart['net_sales'] = number_format($daypart['net_sales'], 2, '.', '');
            $daypart['comps'] = number_format($daypart['comps'], 2, '.', '');
            $daypart['fees'] = number_format($daypart['fees'], 2, '.', '');
            $daypart['sales_plus_fees'] = number_format($daypart['net_sales'] + $daypart['fees'], 2, '.', '');
            $daypart['avg_order'] = $daypart['orders'] > 0 ? number_format($daypart['net_sales'] / $daypart['orders'], 2, '.', '') : '0.00';
            $daypart['ppa'] = $daypart['guests'] > 0 ? number_format($daypart['net_sales'] / $daypart['guests'], 2, '.', '') : '0.00';
            $daypart['gross_sales_percent'] = $totalGrossSales > 0 ? number_format(($daypart['gross_sales'] / $totalGrossSales) * 100, 2, '.', '') : '0.00';
            $daypart['net_sales_percent'] = $totalNetSales > 0 ? number_format(($daypart['net_sales'] / $totalNetSales) * 100, 2, '.', '') : '0.00';
            $result[] = $daypart;
        }

        return [
            'dayparts' => $result,
            'totals' => [
                'gross_sales' => number_format($totalGrossSales, 2, '.', ''),
                'net_sales' => number_format($totalNetSales, 2, '.', ''),
                'comps' => number_format($totalComps, 2, '.', ''),
                'fees' => number_format($totalFees, 2, '.', ''),
                'sales_plus_fees' => number_format($totalNetSales + $totalFees, 2, '.', ''),
                'orders' => $totalOrders,
                'avg_order' => $totalOrders > 0 ? number_format($totalNetSales / $totalOrders, 2, '.', '') : '0.00',
                'guests' => $totalGuests,
                'ppa' => $totalGuests > 0 ? number_format($totalNetSales / $totalGuests, 2, '.', '') : '0.00',
                'gross_sales_percent' => '100.00',
                'net_sales_percent' => '100.00',
            ],
        ];
    }

    /**
     * Calculate Revenue Centers
     */
    private function calculateRevenueCenters($orders)
    {
        $totalGrossSales = 0;
        $totalNetSales = 0;
        $totalComps = 0;
        $totalFees = 0;
        $totalOrders = 0;
        $totalGuests = 0;

        foreach ($orders as $order) {
            $orderGross = $this->calculateOrderGross($order);
            $orderNet = $this->calculateOrderNet($order);
            $orderComps = $this->calculateOrderComps($order);
            $orderFees = (float) ($order->fee_value ?? 0);

            $totalGrossSales += $orderGross;
            $totalNetSales += $orderNet;
            $totalComps += $orderComps;
            $totalFees += $orderFees;
            $totalOrders++;
            $totalGuests += $this->getOrderGuests($order);
        }

        return [
            'revenue_centers' => [
                [
                    'name' => 'Restaurant (default)',
                    'gross_sales' => number_format($totalGrossSales, 2, '.', ''),
                    'net_sales' => number_format($totalNetSales, 2, '.', ''),
                    'comps' => number_format($totalComps, 2, '.', ''),
                    'fees' => number_format($totalFees, 2, '.', ''),
                    'sales_plus_fees' => number_format($totalNetSales + $totalFees, 2, '.', ''),
                    'orders' => $totalOrders,
                    'avg_order' => $totalOrders > 0 ? number_format($totalNetSales / $totalOrders, 2, '.', '') : '0.00',
                    'guests' => $totalGuests,
                    'ppa' => $totalGuests > 0 ? number_format($totalNetSales / $totalGuests, 2, '.', '') : '0.00',
                    'sales_percent' => '100.00',
                ],
            ],
            'totals' => [
                'gross_sales' => number_format($totalGrossSales, 2, '.', ''),
                'net_sales' => number_format($totalNetSales, 2, '.', ''),
                'comps' => number_format($totalComps, 2, '.', ''),
                'fees' => number_format($totalFees, 2, '.', ''),
                'sales_plus_fees' => number_format($totalNetSales + $totalFees, 2, '.', ''),
                'orders' => $totalOrders,
                'avg_order' => $totalOrders > 0 ? number_format($totalNetSales / $totalOrders, 2, '.', '') : '0.00',
                'guests' => $totalGuests,
                'ppa' => $totalGuests > 0 ? number_format($totalNetSales / $totalGuests, 2, '.', '') : '0.00',
                'sales_percent' => '100.00',
            ],
        ];
    }

    /**
     * Calculate Order Type breakdown
     */
    private function calculateOrderType($orders)
    {
        // For now, assume all orders are "Seated" unless we have order_type field
        // This can be extended based on your Order model structure
        $orderTypes = [
            'Seated' => ['gross_sales' => 0, 'net_sales' => 0, 'comps' => 0, 'fees' => 0, 'orders' => 0, 'guests' => 0],
            'TA' => ['gross_sales' => 0, 'net_sales' => 0, 'comps' => 0, 'fees' => 0, 'orders' => 0, 'guests' => 0],
            'Delivery' => ['gross_sales' => 0, 'net_sales' => 0, 'comps' => 0, 'fees' => 0, 'orders' => 0, 'guests' => 0],
        ];

        foreach ($orders as $order) {
            // Default to Seated - you can modify this based on your Order model
            $orderType = 'Seated';

            $orderGross = $this->calculateOrderGross($order);
            $orderNet = $this->calculateOrderNet($order);
            $orderComps = $this->calculateOrderComps($order);
            $orderFees = (float) ($order->fee_value ?? 0);

            $orderTypes[$orderType]['gross_sales'] += $orderGross;
            $orderTypes[$orderType]['net_sales'] += $orderNet;
            $orderTypes[$orderType]['comps'] += $orderComps;
            $orderTypes[$orderType]['fees'] += $orderFees;
            $orderTypes[$orderType]['orders']++;
            $orderTypes[$orderType]['guests'] += $this->getOrderGuests($order);
        }

        $totalGrossSales = array_sum(array_column($orderTypes, 'gross_sales'));
        $totalNetSales = array_sum(array_column($orderTypes, 'net_sales'));
        $totalComps = array_sum(array_column($orderTypes, 'comps'));
        $totalFees = array_sum(array_column($orderTypes, 'fees'));
        $totalOrders = array_sum(array_column($orderTypes, 'orders'));
        $totalGuests = array_sum(array_column($orderTypes, 'guests'));

        $result = [];
        foreach ($orderTypes as $type => $data) {
            $result[] = [
                'name' => $type,
                'gross_sales' => number_format($data['gross_sales'], 2, '.', ''),
                'net_sales' => number_format($data['net_sales'], 2, '.', ''),
                'comps' => number_format($data['comps'], 2, '.', ''),
                'fees' => number_format($data['fees'], 2, '.', ''),
                'sales_plus_fees' => number_format($data['net_sales'] + $data['fees'], 2, '.', ''),
                'orders' => $data['orders'],
                'avg_order' => $data['orders'] > 0 ? number_format($data['net_sales'] / $data['orders'], 2, '.', '') : '0.00',
                'guests' => $data['guests'],
                'ppa' => $data['guests'] > 0 ? number_format($data['net_sales'] / $data['guests'], 2, '.', '') : '0.00',
                'gross_sales_percent' => $totalGrossSales > 0 ? number_format(($data['gross_sales'] / $totalGrossSales) * 100, 2, '.', '') : '0.00',
                'net_sales_percent' => $totalNetSales > 0 ? number_format(($data['net_sales'] / $totalNetSales) * 100, 2, '.', '') : '0.00',
            ];
        }

        return [
            'order_types' => $result,
            'totals' => [
                'gross_sales' => number_format($totalGrossSales, 2, '.', ''),
                'net_sales' => number_format($totalNetSales, 2, '.', ''),
                'comps' => number_format($totalComps, 2, '.', ''),
                'fees' => number_format($totalFees, 2, '.', ''),
                'sales_plus_fees' => number_format($totalNetSales + $totalFees, 2, '.', ''),
                'orders' => $totalOrders,
                'avg_order' => $totalOrders > 0 ? number_format($totalNetSales / $totalOrders, 2, '.', '') : '0.00',
                'guests' => $totalGuests,
                'ppa' => $totalGuests > 0 ? number_format($totalNetSales / $totalGuests, 2, '.', '') : '0.00',
                'gross_sales_percent' => '100.00',
                'net_sales_percent' => '100.00',
            ],
        ];
    }

    /**
     * Calculate Exceptions (Comps, Voids)
     */
    private function calculateExceptions($orders)
    {
        $exceptions = [
            'Marketing Comps' => ['actions' => 0, 'amount' => 0],
            'Organizational' => ['actions' => 0, 'amount' => 0],
            'Voids' => ['actions' => 0, 'amount' => 0],
        ];

        $totalGrossSales = 0;
        $totalNetSales = 0;

        foreach ($orders as $order) {
            $orderGross = $this->calculateOrderGross($order);
            $orderNet = $this->calculateOrderNet($order);
            $totalGrossSales += $orderGross;
            $totalNetSales += $orderNet;

            // Count voids
            foreach ($order->checks as $check) {
                foreach ($check->orderItems as $item) {
                    if ($item->order_status == 3) { // Voided
                        $voidAmount = (float) $item->unit_price * (int) $item->qty;
                        $exceptions['Voids']['actions']++;
                        $exceptions['Voids']['amount'] += $voidAmount;
                    }
                }
            }

            // Count comps (discounts)
            foreach ($order->checks as $check) {
                foreach ($check->orderItems as $item) {
                    $discountAmount = (float) ($item->discount_amount ?? 0);
                    if ($discountAmount > 0) {
                        // Assume marketing comps for now - you can categorize based on discount_reason
                        $exceptions['Marketing Comps']['actions']++;
                        $exceptions['Marketing Comps']['amount'] += $discountAmount;
                    }
                }
            }
        }

        $totalActions = array_sum(array_column($exceptions, 'actions'));
        $totalAmount = array_sum(array_column($exceptions, 'amount'));

        $result = [];
        foreach ($exceptions as $name => $data) {
            $result[] = [
                'name' => $name,
                'actions' => $data['actions'],
                'amount' => number_format($data['amount'], 2, '.', ''),
                'percent_from_gross' => $totalGrossSales > 0 ? number_format(($data['amount'] / $totalGrossSales) * 100, 2, '.', '') : '0.00',
                'percent_from_net' => $totalNetSales > 0 ? number_format(($data['amount'] / $totalNetSales) * 100, 2, '.', '') : '0.00',
            ];
        }

        return [
            'exceptions' => $result,
            'totals' => [
                'actions' => $totalActions,
                'amount' => number_format($totalAmount, 2, '.', ''),
                'percent_from_gross' => $totalGrossSales > 0 ? number_format(($totalAmount / $totalGrossSales) * 100, 2, '.', '') : '0.00',
                'percent_from_net' => $totalNetSales > 0 ? number_format(($totalAmount / $totalNetSales) * 100, 2, '.', '') : '0.00',
            ],
        ];
    }

    /**
     * Calculate Payments breakdown
     */
    private function calculatePaymentsDetailed($orders)
    {
        $paymentMethods = [];
        $totalPayments = 0;
        $totalRefunds = 0;

        foreach ($orders as $order) {
            foreach ($order->paymentHistories as $payment) {
                $method = $payment->payment_mode ?? 'Unknown';
                $amount = (float) ($payment->amount ?? 0);

                if (!isset($paymentMethods[$method])) {
                    $paymentMethods[$method] = [
                        'name' => $method,
                        'payment_count' => 0,
                        'payment_amount' => 0,
                        'refund_count' => 0,
                        'refund_amount' => 0,
                    ];
                }

                if ($amount >= 0) {
                    $paymentMethods[$method]['payment_count']++;
                    $paymentMethods[$method]['payment_amount'] += $amount;
                    $totalPayments += $amount;
                } else {
                    $paymentMethods[$method]['refund_count']++;
                    $paymentMethods[$method]['refund_amount'] += abs($amount);
                    $totalRefunds += abs($amount);
                }
            }
        }

        $result = [];
        foreach ($paymentMethods as $method => $data) {
            $result[] = [
                'name' => $method,
                'payment_count' => $data['payment_count'],
                'payment_amount' => number_format($data['payment_amount'], 2, '.', ''),
                'refund_count' => $data['refund_count'],
                'refund_amount' => number_format($data['refund_amount'], 2, '.', ''),
                'total_amount' => number_format($data['payment_amount'] - $data['refund_amount'], 2, '.', ''),
            ];
        }

        return [
            'payment_methods' => $result,
            'totals' => [
                'payment_count' => array_sum(array_column($paymentMethods, 'payment_count')),
                'payment_amount' => number_format($totalPayments, 2, '.', ''),
                'refund_count' => array_sum(array_column($paymentMethods, 'refund_count')),
                'refund_amount' => number_format($totalRefunds, 2, '.', ''),
                'total_amount' => number_format($totalPayments - $totalRefunds, 2, '.', ''),
            ],
        ];
    }

    /**
     * Calculate Cash Summary
     */
    private function calculateCashSummaryDetailed($orders)
    {
        // This would need drawer/action tracking - simplified for now
        return [
            'drawers' => [],
            'totals' => [
                'actions' => 0,
                'amount' => '0.00',
            ],
        ];
    }

    /**
     * Calculate Tips & Cash Balance
     */
    private function calculateTipsCashBalance($orders)
    {
        $totalTips = 0;
        $totalServiceCharge = 0;
        $totalCashOnHand = 0;

        foreach ($orders as $order) {
            if ($order->status == 'completed') {
                $serviceCharge = (float) ($order->gratuity_value ?? 0);
                $totalServiceCharge += $serviceCharge;

                // Calculate tips from payment histories
                foreach ($order->paymentHistories as $payment) {
                    $tipAmount = (float) ($payment->tip_amount ?? 0);
                    $totalTips += $tipAmount;

                    // Cash payments contribute to cash on hand
                    if (strtolower($payment->payment_mode ?? '') == 'cash') {
                        $totalCashOnHand += (float) ($payment->amount ?? 0);
                    }
                }
            }
        }

        return [
            'total_cash_balance' => number_format($totalCashOnHand, 2, '.', ''),
            'cash_on_hand' => number_format($totalCashOnHand, 2, '.', ''),
            'subtotal_tips_service_charge' => number_format($totalTips + $totalServiceCharge, 2, '.', ''),
            'service_charge' => number_format($totalServiceCharge, 2, '.', ''),
            'tips' => number_format($totalTips, 2, '.', ''),
        ];
    }

    /**
     * Calculate Taxes
     */
    private function calculateTaxes($orders)
    {
        $taxRates = [];
        $totalTax = 0;

        foreach ($orders as $order) {
            if ($order->status == 'completed') {
                $taxAmount = (float) ($order->tax_value ?? 0);
                $taxRate = '6.625%'; // Default - you can calculate from order items

                if (!isset($taxRates[$taxRate])) {
                    $taxRates[$taxRate] = [
                        'rate' => $taxRate,
                        'taxable_amount' => 0,
                        'tax_collected' => 0,
                    ];
                }

                $orderNet = $this->calculateOrderNet($order);
                $taxRates[$taxRate]['taxable_amount'] += $orderNet;
                $taxRates[$taxRate]['tax_collected'] += $taxAmount;
                $totalTax += $taxAmount;
            }
        }

        $result = [];
        foreach ($taxRates as $rate => $data) {
            $result[] = [
                'rate' => $rate,
                'taxable_amount' => number_format($data['taxable_amount'], 2, '.', ''),
                'tax_collected' => number_format($data['tax_collected'], 2, '.', ''),
            ];
        }

        return [
            'tax_rates' => $result,
            'total_tax' => number_format($totalTax, 2, '.', ''),
        ];
    }

    /**
     * Calculate Tax Summary
     */
    private function calculateTaxSummary($orders)
    {
        $totalSales = 0;
        $totalServiceCharge = 0;
        $totalFees = 0;
        $taxableSales = 0;
        $nonTaxableSales = 0;

        foreach ($orders as $order) {
            if ($order->status == 'completed') {
                $orderNet = $this->calculateOrderNet($order);
                $serviceCharge = (float) ($order->gratuity_value ?? 0);
                $fees = (float) ($order->fee_value ?? 0);

                $totalSales += $orderNet;
                $totalServiceCharge += $serviceCharge;
                $totalFees += $fees;
                $taxableSales += $orderNet; // Sales are taxable
                // Service charge and fees are typically non-taxable
                $nonTaxableSales += $serviceCharge + $fees;
            }
        }

        return [
            'total' => [
                'taxable_amount' => number_format($taxableSales, 2, '.', ''),
                'non_taxable_amount' => number_format($nonTaxableSales, 2, '.', ''),
                'total_amount' => number_format($totalSales + $totalServiceCharge + $totalFees, 2, '.', ''),
            ],
            'sales' => [
                'taxable_amount' => number_format($taxableSales, 2, '.', ''),
                'non_taxable_amount' => '0.00',
                'total_amount' => number_format($totalSales, 2, '.', ''),
            ],
            'service_charge' => [
                'taxable_amount' => '0.00',
                'non_taxable_amount' => number_format($totalServiceCharge, 2, '.', ''),
                'total_amount' => number_format($totalServiceCharge, 2, '.', ''),
            ],
            'fees' => [
                'taxable_amount' => '0.00',
                'non_taxable_amount' => number_format($totalFees, 2, '.', ''),
                'total_amount' => number_format($totalFees, 2, '.', ''),
            ],
        ];
    }

    /**
     * Calculate Tax Exemptions
     */
    private function calculateTaxExemptions($orders)
    {
        // This would track tax-exempt orders - simplified for now
        return [
            'exemptions' => [],
            'totals' => [
                'orders' => 0,
                'amount' => '0.00',
            ],
        ];
    }

    // Helper methods

    private function calculateOrderGross($order)
    {
        $total = 0;
        foreach ($order->checks as $check) {
            foreach ($check->orderItems as $item) {
                if ($item->order_status != 3) { // Not voided
                    $total += (float) $item->unit_price * (int) $item->qty;
                }
            }
        }
        return $total;
    }

    private function calculateOrderNet($order)
    {
        $total = 0;
        foreach ($order->checks as $check) {
            foreach ($check->orderItems as $item) {
                if ($item->order_status != 3) { // Not voided
                    $itemTotal = (float) $item->unit_price * (int) $item->qty;
                    $discount = (float) ($item->discount_amount ?? 0);
                    $total += $itemTotal - $discount;
                }
            }
        }
        return $total;
    }

    private function calculateOrderComps($order)
    {
        $total = 0;
        foreach ($order->checks as $check) {
            foreach ($check->orderItems as $item) {
                $total += (float) ($item->discount_amount ?? 0);
            }
        }
        return $total;
    }

    private function getOrderGuests($order)
    {
        // Count unique customer numbers or use a default
        $guests = 0;
        foreach ($order->checks as $check) {
            $customerNos = $check->orderItems->pluck('customer_no')->unique()->count();
            $guests += max($customerNos, 1); // At least 1 guest per check
        }
        return $guests > 0 ? $guests : 1; // Default to 1 if no guests found
    }
}