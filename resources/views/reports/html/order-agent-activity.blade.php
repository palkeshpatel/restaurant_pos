<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order Agent Activity Summary Report - {{ $businessName }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            line-height: 1.4;
            color: #000;
            background: #fff;
            padding: 10px;
            margin: 0;
        }
        .header {
            text-align: center;
            margin-bottom: 15px;
            border-bottom: 2px solid #000;
            padding: 10px 0;
            page-break-after: avoid;
        }
        .header h1 {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .header .info {
            font-size: 11px;
            margin: 3px 0;
        }
        .section {
            margin-bottom: 25px;
            page-break-inside: avoid;
        }
        .section-title {
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 10px;
            padding: 5px;
            background: #f0f0f0;
            border-bottom: 1px solid #000;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
            font-size: 11px;
        }
        table th {
            background: #f0f0f0;
            font-weight: bold;
            padding: 6px 4px;
            text-align: left;
            border: 1px solid #000;
        }
        table td {
            padding: 5px 4px;
            border: 1px solid #000;
            text-align: right;
        }
        table td:first-child {
            text-align: left;
        }
        table tfoot td {
            font-weight: bold;
            background: #f0f0f0;
        }
        .text-right {
            text-align: right;
        }
        .text-left {
            text-align: left;
        }
        .text-center {
            text-align: center;
        }
        .status-open {
            color: #28a745;
            font-weight: bold;
        }
        .status-closed {
            color: #dc3545;
            font-weight: bold;
        }
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 5px;
        }
        .status-indicator.open {
            background-color: #28a745;
        }
        .status-indicator.closed {
            background-color: #dc3545;
        }
        .chart-container {
            width: 100%;
            max-width: 500px;
            margin: 20px auto;
            page-break-inside: avoid;
        }
        .chart-wrapper {
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 20px 0;
        }
        @media print {
            body {
                padding: 0;
                margin: 0;
            }
            .header {
                margin-top: 0;
                padding-top: 5px;
                margin-bottom: 10px;
            }
            .section {
                page-break-inside: avoid;
            }
            .section-title {
                page-break-after: avoid;
            }
        }
    </style>
</head>
<body style="margin: 0; padding: 10px;">
    <div class="header">
        <h1>Order Agent Activity Summary Report</h1>
        <div class="info">{{ $businessName }}</div>
        <div class="info">Issued: {{ $issuedAt }}</div>
        <div class="info">Business dates: {{ $businessDates }}</div>
    </div>

    @if(isset($hasActivity) && !$hasActivity)
    <div class="section" style="text-align: center; padding: 40px 20px;">
        <p style="font-size: 14px; color: #666;">No order activity found for the selected date.</p>
    </div>
    @else
    <!-- Open Orders -->
    @if(isset($orderDetails['open_orders']) && count($orderDetails['open_orders']) > 0)
    <div class="section">
        <div class="section-title">Open Orders ({{ $orderDetails['total_open_orders'] }})</div>
        @foreach($orderDetails['open_orders'] as $order)
        <div style="margin-bottom: 20px; border: 1px solid #ddd; padding: 10px; page-break-inside: avoid;">
            <div style="margin-bottom: 10px;">
                <strong>Order #{{ $order['order_ticket_id'] }}</strong> - {{ $order['order_ticket_title'] }}
                <br>
                <small>
                    Table: {{ $order['table_name'] }} | Created: {{ $order['created_at'] }} | Created By: {{ $order['created_by_employee'] }} | Guests: {{ $order['customer_count'] }} | 
                    Status: <span class="status-indicator open"></span><span class="status-open">{{ $order['status'] }}</span> | 
                    Order Items: {{ $order['order_items_count'] }} | 
                    Order Total: ${{ $order['order_total'] }} | 
                    Payment Total: ${{ $order['payment_total'] }}
                </small>
            </div>
            
            @if(isset($order['payment_histories']) && count($order['payment_histories']) > 0)
            <div style="margin-bottom: 15px; padding: 10px; background: #f9f9f9; border: 1px solid #ddd; border-radius: 4px;">
                <div style="font-weight: bold; margin-bottom: 8px; font-size: 11px;">Payment & Refund Activity:</div>
                <table style="font-size: 10px; width: 100%; margin-bottom: 0;">
                    <thead>
                        <tr>
                            <th style="text-align: left; padding: 4px;">Type</th>
                            <th style="text-align: left; padding: 4px;">Payment Mode</th>
                            <th style="text-align: right; padding: 4px;">Amount</th>
                            <th style="text-align: right; padding: 4px;">Tip</th>
                            <th style="text-align: left; padding: 4px;">Agent</th>
                            <th style="text-align: left; padding: 4px;">Date/Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($order['payment_histories'] as $payment)
                        @php
                            $isRefund = $payment['is_refund'] ?? false;
                        @endphp
                        <tr>
                            <td style="text-align: left; padding: 4px;">
                                @if($isRefund)
                                    <span style="color: #dc3545; font-weight: bold;">Refund</span>
                                @else
                                    <span style="color: #28a745; font-weight: bold;">Payment</span>
                                @endif
                            </td>
                            <td style="text-align: left; padding: 4px;">{{ $payment['payment_mode'] }}</td>
                            <td style="text-align: right; padding: 4px; @if($isRefund) color: #dc3545; @endif">
                                @if($isRefund)
                                    -${{ $payment['amount'] }}
                                @else
                                    ${{ $payment['amount'] }}
                                @endif
                            </td>
                            <td style="text-align: right; padding: 4px;">${{ $payment['tip_amount'] }}</td>
                            <td style="text-align: left; padding: 4px;">{{ $payment['employee_name'] }}</td>
                            <td style="text-align: left; padding: 4px;">{{ $payment['created_at'] }}</td>
                        </tr>
                        @if(!empty($payment['refund_reason']) || !empty($payment['comment']))
                        <tr>
                            <td colspan="6" style="text-align: left; padding: 2px 4px; font-size: 9px; color: #666; font-style: italic;">
                                @if(!empty($payment['refund_reason']))
                                    Reason: {{ $payment['refund_reason'] }}
                                @endif
                                @if(!empty($payment['refund_reason']) && !empty($payment['comment']))
                                    | 
                                @endif
                                @if(!empty($payment['comment']))
                                    Comment: {{ $payment['comment'] }}
                                @endif
                            </td>
                        </tr>
                        @endif
                        @endforeach
                    </tbody>
                </table>
            </div>
            @endif
            @foreach($order['employee_activities'] as $activity)
            <div style="margin-bottom: 15px; border-left: 3px solid #007bff; padding-left: 10px;">
                <div style="margin-bottom: 8px;">
                    <strong>{{ $activity['employee_name'] }}</strong>
                    <span style="margin-left: 15px; font-size: 9px; color: #666;">
                        Start: {{ $activity['start_date'] }} | 
                        End: {{ $activity['end_date'] }} | 
                        @if($activity['duration_minutes'] > 0)
                        Spent Time: {{ $activity['duration_minutes'] }} minutes
                        @else
                        Spent Time: N/A
                        @endif
                    </span>
                </div>
                @if(count($activity['order_items']) > 0)
                <table style="font-size: 10px; width: 100%;">
                    <thead>
                        <tr>
                            <th style="text-align: left;">Item Name</th>
                            <th class="text-center">Qty</th>
                            <th class="text-center">Hold</th>
                            <th class="text-center">Fire</th>
                            <th class="text-center">Void</th>
                            <th class="text-right">Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($activity['order_items'] as $item)
                        <tr>
                            <td>{{ $item['item_name'] }}</td>
                            <td class="text-center">{{ $item['qty'] }}</td>
                            <td class="text-center">{{ $item['hold'] }}</td>
                            <td class="text-center">{{ $item['fire'] }}</td>
                            <td class="text-center">{{ $item['void'] }}</td>
                            <td class="text-right">${{ $item['amount'] }}</td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
                @else
                <div style="font-size: 10px; color: #999; font-style: italic;">No order items</div>
                @endif
            </div>
            @endforeach
        </div>
        @endforeach
    </div>
    @endif

    <!-- Closed Orders -->
    @if(isset($orderDetails['closed_orders']) && count($orderDetails['closed_orders']) > 0)
    <div class="section">
        <div class="section-title">Closed Orders ({{ $orderDetails['total_closed_orders'] }})</div>
        @foreach($orderDetails['closed_orders'] as $order)
        <div style="margin-bottom: 20px; border: 1px solid #ddd; padding: 10px; page-break-inside: avoid;">
            <div style="margin-bottom: 10px;">
                <strong>Order #{{ $order['order_ticket_id'] }}</strong> - {{ $order['order_ticket_title'] }}
                <br>
                <small>
                    Table: {{ $order['table_name'] }} | Created: {{ $order['created_at'] }} | Created By: {{ $order['created_by_employee'] }} | Guests: {{ $order['customer_count'] }} | 
                    Status: <span class="status-indicator closed"></span><span class="status-closed">{{ $order['status'] }}</span> | 
                    Order Items: {{ $order['order_items_count'] }} | 
                    Order Total: ${{ $order['order_total'] }} | 
                    Payment Total: ${{ $order['payment_total'] }}
                </small>
            </div>
            
            @if(isset($order['payment_histories']) && count($order['payment_histories']) > 0)
            <div style="margin-bottom: 15px; padding: 10px; background: #f9f9f9; border: 1px solid #ddd; border-radius: 4px;">
                <div style="font-weight: bold; margin-bottom: 8px; font-size: 11px;">Payment & Refund Activity:</div>
                <table style="font-size: 10px; width: 100%; margin-bottom: 0;">
                    <thead>
                        <tr>
                            <th style="text-align: left; padding: 4px;">Type</th>
                            <th style="text-align: left; padding: 4px;">Payment Mode</th>
                            <th style="text-align: right; padding: 4px;">Amount</th>
                            <th style="text-align: right; padding: 4px;">Tip</th>
                            <th style="text-align: left; padding: 4px;">Agent</th>
                            <th style="text-align: left; padding: 4px;">Date/Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($order['payment_histories'] as $payment)
                        @php
                            $isRefund = $payment['is_refund'] ?? false;
                        @endphp
                        <tr>
                            <td style="text-align: left; padding: 4px;">
                                @if($isRefund)
                                    <span style="color: #dc3545; font-weight: bold;">Refund</span>
                                @else
                                    <span style="color: #28a745; font-weight: bold;">Payment</span>
                                @endif
                            </td>
                            <td style="text-align: left; padding: 4px;">{{ $payment['payment_mode'] }}</td>
                            <td style="text-align: right; padding: 4px; @if($isRefund) color: #dc3545; @endif">
                                @if($isRefund)
                                    -${{ $payment['amount'] }}
                                @else
                                    ${{ $payment['amount'] }}
                                @endif
                            </td>
                            <td style="text-align: right; padding: 4px;">${{ $payment['tip_amount'] }}</td>
                            <td style="text-align: left; padding: 4px;">{{ $payment['employee_name'] }}</td>
                            <td style="text-align: left; padding: 4px;">{{ $payment['created_at'] }}</td>
                        </tr>
                        @if(!empty($payment['refund_reason']) || !empty($payment['comment']))
                        <tr>
                            <td colspan="6" style="text-align: left; padding: 2px 4px; font-size: 9px; color: #666; font-style: italic;">
                                @if(!empty($payment['refund_reason']))
                                    Reason: {{ $payment['refund_reason'] }}
                                @endif
                                @if(!empty($payment['refund_reason']) && !empty($payment['comment']))
                                    | 
                                @endif
                                @if(!empty($payment['comment']))
                                    Comment: {{ $payment['comment'] }}
                                @endif
                            </td>
                        </tr>
                        @endif
                        @endforeach
                    </tbody>
                </table>
            </div>
            @endif
            @foreach($order['employee_activities'] as $activity)
            <div style="margin-bottom: 15px; border-left: 3px solid #007bff; padding-left: 10px;">
                <div style="margin-bottom: 8px;">
                    <strong>{{ $activity['employee_name'] }}</strong>
                    <span style="margin-left: 15px; font-size: 9px; color: #666;">
                        Start: {{ $activity['start_date'] }} | 
                        End: {{ $activity['end_date'] }} | 
                        @if($activity['duration_minutes'] > 0)
                        Spent Time: {{ $activity['duration_minutes'] }} minutes
                        @else
                        Spent Time: N/A
                        @endif
                    </span>
                </div>
                @if(count($activity['order_items']) > 0)
                <table style="font-size: 10px; width: 100%;">
                    <thead>
                        <tr>
                            <th style="text-align: left;">Item Name</th>
                            <th class="text-center">Qty</th>
                            <th class="text-center">Hold</th>
                            <th class="text-center">Fire</th>
                            <th class="text-center">Void</th>
                            <th class="text-right">Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($activity['order_items'] as $item)
                        <tr>
                            <td>{{ $item['item_name'] }}</td>
                            <td class="text-center">{{ $item['qty'] }}</td>
                            <td class="text-center">{{ $item['hold'] }}</td>
                            <td class="text-center">{{ $item['fire'] }}</td>
                            <td class="text-center">{{ $item['void'] }}</td>
                            <td class="text-right">${{ $item['amount'] }}</td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
                @else
                <div style="font-size: 10px; color: #999; font-style: italic;">No order items</div>
                @endif
            </div>
            @endforeach
        </div>
        @endforeach
    </div>
    @endif

    <!-- Employee Activity Summary -->
    @if(isset($employeeActivity) && count($employeeActivity) > 0)
    <div class="section">
        <div class="section-title">Employee Activity Summary</div>
        
        <!-- Pie Chart for Time Spent (only for HTML, not PDF) -->
        @if(count($employeeActivity) > 0 && !isset($isPdf))
        <div class="chart-wrapper">
            <div class="chart-container" style="width: 500px; height: 400px;">
                <canvas id="timeSpentChart" width="500" height="400"></canvas>
            </div>
        </div>
        @endif
        
        <!-- Time Distribution Summary for PDF -->
        @if(count($employeeActivity) > 0 && isset($isPdf) && $isPdf)
        <div style="margin-bottom: 15px; padding: 10px; background: #f9f9f9; border: 1px solid #ddd;">
            <div style="font-weight: bold; margin-bottom: 10px;">Time Spent Distribution:</div>
            @php
                $totalMinutes = 0;
                foreach($employeeActivity as $emp) {
                    $totalMinutes += (float) $emp['total_time_minutes'];
                }
            @endphp
            @foreach($employeeActivity as $employee)
                @php
                    $empMinutes = (float) $employee['total_time_minutes'];
                    $percentage = $totalMinutes > 0 ? (($empMinutes / $totalMinutes) * 100) : 0;
                @endphp
                <div style="margin-bottom: 5px; font-size: 11px;">
                    <strong>{{ $employee['employee_name'] }}:</strong> 
                    {{ number_format($empMinutes, 0) }} minutes 
                    ({{ number_format($percentage, 1) }}%) - 
                    {{ number_format($empMinutes / 60, 2) }} hours
                </div>
            @endforeach
            <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid #ddd; font-weight: bold; font-size: 11px;">
                Total Time: {{ number_format($totalMinutes, 0) }} minutes ({{ number_format($totalMinutes / 60, 2) }} hours)
            </div>
        </div>
        @endif
        
        <table>
            <thead>
                <tr>
                    <th>Employee Name</th>
                    <th class="text-right">Total Orders</th>
                    <th class="text-right">Active Orders</th>
                </tr>
            </thead>
            <tbody>
                @foreach($employeeActivity as $employee)
                <tr>
                    <td>{{ $employee['employee_name'] }}</td>
                    <td class="text-right">{{ $employee['total_orders'] }}</td>
                    <td class="text-right">{{ $employee['active_orders'] }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    
    @endif
    @endif
</body>
</html>