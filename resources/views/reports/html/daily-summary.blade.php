<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daily Summary Report - {{ $businessName }}</title>
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
            padding: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #000;
            padding-bottom: 10px;
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
        @media print {
            body {
                padding: 10px;
            }
            .section {
                page-break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ $businessName }}</h1>
        <div class="info">Issued: {{ $issuedAt }}</div>
        <div class="info">Business dates: {{ $businessDates }}</div>
    </div>

    @if(isset($hasActivity) && !$hasActivity)
    <div class="section" style="text-align: center; padding: 40px 20px;">
        <div style="font-size: 18px; color: #666; margin-bottom: 10px;">
            No orders completed on that day
        </div>
        <div style="font-size: 14px; color: #999;">
            Please select a different date to view the report.
        </div>
    </div>
    @elseif(isset($salesByDept) && !empty($salesByDept['departments']))
    <div class="section">
        <div class="section-title">Sales (by Dept/Sub dept.)</div>
        <table>
            <thead>
                <tr>
                    <th>Dept/Sub dept.</th>
                    <th>Gross Sales</th>
                    <th>% of Gross Sales</th>
                    <th>Net Sales</th>
                    <th>% of Net Sales</th>
                    <th>Tax</th>
                    <th>Comps</th>
                    <th>Voids</th>
                </tr>
            </thead>
            <tbody>
                @foreach($salesByDept['departments'] as $dept)
                <tr>
                    <td><strong>{{ $dept['name'] }}</strong></td>
                    <td>${{ $dept['gross_sales'] }}</td>
                    <td>{{ $dept['gross_sales_percent'] }}%</td>
                    <td>${{ $dept['net_sales'] }}</td>
                    <td>{{ $dept['net_sales_percent'] }}%</td>
                    <td>${{ $dept['tax'] }}</td>
                    <td>${{ $dept['comps'] }}</td>
                    <td>${{ $dept['voids'] }}</td>
                </tr>
                @if(!empty($dept['sub_departments']))
                    @foreach($dept['sub_departments'] as $subDept)
                    <tr>
                        <td style="padding-left: 20px;">{{ $subDept['name'] }}</td>
                        <td>${{ $subDept['gross_sales'] }}</td>
                        <td>-</td>
                        <td>${{ $subDept['net_sales'] }}</td>
                        <td>-</td>
                        <td>${{ $subDept['tax'] }}</td>
                        <td>${{ $subDept['comps'] }}</td>
                        <td>-</td>
                    </tr>
                    @endforeach
                @endif
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td><strong>Total</strong></td>
                    <td><strong>${{ $salesByDept['totals']['gross_sales'] }}</strong></td>
                    <td><strong>{{ $salesByDept['totals']['gross_sales_percent'] }}%</strong></td>
                    <td><strong>${{ $salesByDept['totals']['net_sales'] }}</strong></td>
                    <td><strong>{{ $salesByDept['totals']['net_sales_percent'] }}%</strong></td>
                    <td><strong>${{ $salesByDept['totals']['tax'] }}</strong></td>
                    <td><strong>${{ $salesByDept['totals']['comps'] }}</strong></td>
                    <td><strong>${{ $salesByDept['totals']['voids'] }}</strong></td>
                </tr>
            </tfoot>
        </table>
    </div>
    @endif

    @if(isset($salesByDaypart) && !empty($salesByDaypart['dayparts']))
    <div class="section">
        <div class="section-title">Sales by Daypart/Shift</div>
        <table>
            <thead>
                <tr>
                    <th>Shifts</th>
                    <th>Gross Sales</th>
                    <th>% of Gross Sales</th>
                    <th>Comps</th>
                    <th>Net Sales</th>
                    <th>% of Net Sales</th>
                    <th>Fees</th>
                    <th>Sales + Fees</th>
                    <th>Orders</th>
                    <th>Avg. Order</th>
                    <th>Guests</th>
                    <th>PPA</th>
                </tr>
            </thead>
            <tbody>
                @foreach($salesByDaypart['dayparts'] as $daypart)
                <tr>
                    <td>{{ $daypart['name'] }}</td>
                    <td>${{ $daypart['gross_sales'] }}</td>
                    <td>{{ $daypart['gross_sales_percent'] }}%</td>
                    <td>${{ $daypart['comps'] }}</td>
                    <td>${{ $daypart['net_sales'] }}</td>
                    <td>{{ $daypart['net_sales_percent'] }}%</td>
                    <td>${{ $daypart['fees'] }}</td>
                    <td>${{ $daypart['sales_plus_fees'] }}</td>
                    <td>{{ $daypart['orders'] }}</td>
                    <td>${{ $daypart['avg_order'] }}</td>
                    <td>{{ $daypart['guests'] }}</td>
                    <td>${{ $daypart['ppa'] }}</td>
                </tr>
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td><strong>Total</strong></td>
                    <td><strong>${{ $salesByDaypart['totals']['gross_sales'] }}</strong></td>
                    <td><strong>{{ $salesByDaypart['totals']['gross_sales_percent'] }}%</strong></td>
                    <td><strong>${{ $salesByDaypart['totals']['comps'] }}</strong></td>
                    <td><strong>${{ $salesByDaypart['totals']['net_sales'] }}</strong></td>
                    <td><strong>{{ $salesByDaypart['totals']['net_sales_percent'] }}%</strong></td>
                    <td><strong>${{ $salesByDaypart['totals']['fees'] }}</strong></td>
                    <td><strong>${{ $salesByDaypart['totals']['sales_plus_fees'] }}</strong></td>
                    <td><strong>{{ $salesByDaypart['totals']['orders'] }}</strong></td>
                    <td><strong>${{ $salesByDaypart['totals']['avg_order'] }}</strong></td>
                    <td><strong>{{ $salesByDaypart['totals']['guests'] }}</strong></td>
                    <td><strong>${{ $salesByDaypart['totals']['ppa'] }}</strong></td>
                </tr>
            </tfoot>
        </table>
    </div>
    @endif

    @if(isset($revenueCenters) && !empty($revenueCenters['revenue_centers']))
    <div class="section">
        <div class="section-title">Revenue Centers</div>
        <table>
            <thead>
                <tr>
                    <th>Revenue Centers</th>
                    <th>Gross Sales</th>
                    <th>Comps</th>
                    <th>Net Sales</th>
                    <th>% of Sales</th>
                    <th>Fees</th>
                    <th>Sales + Fees</th>
                    <th>Orders</th>
                    <th>Avg. Order</th>
                    <th>Guests</th>
                    <th>PPA</th>
                </tr>
            </thead>
            <tbody>
                @foreach($revenueCenters['revenue_centers'] as $center)
                <tr>
                    <td>{{ $center['name'] }}</td>
                    <td>${{ $center['gross_sales'] }}</td>
                    <td>${{ $center['comps'] }}</td>
                    <td>${{ $center['net_sales'] }}</td>
                    <td>{{ $center['sales_percent'] }}%</td>
                    <td>${{ $center['fees'] }}</td>
                    <td>${{ $center['sales_plus_fees'] }}</td>
                    <td>{{ $center['orders'] }}</td>
                    <td>${{ $center['avg_order'] }}</td>
                    <td>{{ $center['guests'] }}</td>
                    <td>${{ $center['ppa'] }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($orderType) && !empty($orderType['order_types']))
    <div class="section">
        <div class="section-title">Order Type</div>
        <table>
            <thead>
                <tr>
                    <th>Order Type</th>
                    <th>Gross Sales</th>
                    <th>% of Gross Sales</th>
                    <th>Comps</th>
                    <th>Net Sales</th>
                    <th>% of Net Sales</th>
                    <th>Fees</th>
                    <th>Sales + Fees</th>
                    <th>Orders</th>
                    <th>Avg. Order</th>
                    <th>Guests</th>
                    <th>PPA</th>
                </tr>
            </thead>
            <tbody>
                @foreach($orderType['order_types'] as $type)
                <tr>
                    <td>{{ $type['name'] }}</td>
                    <td>${{ $type['gross_sales'] }}</td>
                    <td>{{ $type['gross_sales_percent'] }}%</td>
                    <td>${{ $type['comps'] }}</td>
                    <td>${{ $type['net_sales'] }}</td>
                    <td>{{ $type['net_sales_percent'] }}%</td>
                    <td>${{ $type['fees'] }}</td>
                    <td>${{ $type['sales_plus_fees'] }}</td>
                    <td>{{ $type['orders'] }}</td>
                    <td>${{ $type['avg_order'] }}</td>
                    <td>{{ $type['guests'] }}</td>
                    <td>${{ $type['ppa'] }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($exceptions) && !empty($exceptions['exceptions']))
    <div class="section">
        <div class="section-title">Exceptions</div>
        <table>
            <thead>
                <tr>
                    <th>Reductions</th>
                    <th>Number of Actions</th>
                    <th>Reduction Amount</th>
                    <th>Percentage from Gross</th>
                    <th>Percentage from Net</th>
                </tr>
            </thead>
            <tbody>
                @foreach($exceptions['exceptions'] as $exception)
                <tr>
                    <td>{{ $exception['name'] }}</td>
                    <td>{{ $exception['actions'] }}</td>
                    <td>${{ $exception['amount'] }}</td>
                    <td>{{ $exception['percent_from_gross'] }}%</td>
                    <td>{{ $exception['percent_from_net'] }}%</td>
                </tr>
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td><strong>Total</strong></td>
                    <td><strong>{{ $exceptions['totals']['actions'] }}</strong></td>
                    <td><strong>${{ $exceptions['totals']['amount'] }}</strong></td>
                    <td><strong>{{ $exceptions['totals']['percent_from_gross'] }}%</strong></td>
                    <td><strong>{{ $exceptions['totals']['percent_from_net'] }}%</strong></td>
                </tr>
            </tfoot>
        </table>
    </div>
    @endif

    @if(isset($payments) && !empty($payments['payment_methods']))
    <div class="section">
        <div class="section-title">Payments</div>
        <table>
            <thead>
                <tr>
                    <th>Payment Method</th>
                    <th>Payment #</th>
                    <th>Payment Amount</th>
                    <th>Refund #</th>
                    <th>Refund Amount</th>
                    <th>Total Amount</th>
                </tr>
            </thead>
            <tbody>
                @foreach($payments['payment_methods'] as $payment)
                <tr>
                    <td>{{ $payment['name'] }}</td>
                    <td>{{ $payment['payment_count'] }}</td>
                    <td>${{ $payment['payment_amount'] }}</td>
                    <td>{{ $payment['refund_count'] }}</td>
                    <td>${{ $payment['refund_amount'] }}</td>
                    <td>${{ $payment['total_amount'] }}</td>
                </tr>
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td><strong>Total Payments</strong></td>
                    <td><strong>{{ $payments['totals']['payment_count'] }}</strong></td>
                    <td><strong>${{ $payments['totals']['payment_amount'] }}</strong></td>
                    <td><strong>{{ $payments['totals']['refund_count'] }}</strong></td>
                    <td><strong>${{ $payments['totals']['refund_amount'] }}</strong></td>
                    <td><strong>${{ $payments['totals']['total_amount'] }}</strong></td>
                </tr>
            </tfoot>
        </table>
    </div>
    @endif

    @if(isset($tipsCashBalance))
    <div class="section">
        <div class="section-title">Tips & Cash Balance</div>
        <table>
            <tbody>
                <tr>
                    <td>Total Cash Balance</td>
                    <td>${{ $tipsCashBalance['total_cash_balance'] }}</td>
                </tr>
                <tr>
                    <td>Cash On Hand</td>
                    <td>${{ $tipsCashBalance['cash_on_hand'] }}</td>
                </tr>
                <tr>
                    <td>SubTotal (Tips & Service Charge)</td>
                    <td>${{ $tipsCashBalance['subtotal_tips_service_charge'] }}</td>
                </tr>
                <tr>
                    <td>Service Charge</td>
                    <td>${{ $tipsCashBalance['service_charge'] }}</td>
                </tr>
                <tr>
                    <td>Tips</td>
                    <td>${{ $tipsCashBalance['tips'] }}</td>
                </tr>
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($taxSummary))
    <div class="section">
        <div class="section-title">Tax Summary</div>
        <table>
            <thead>
                <tr>
                    <th></th>
                    <th>Taxable Amount</th>
                    <th>Non Taxable Amount</th>
                    <th>Total Amount</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>Total</strong></td>
                    <td>${{ $taxSummary['total']['taxable_amount'] }}</td>
                    <td>${{ $taxSummary['total']['non_taxable_amount'] }}</td>
                    <td>${{ $taxSummary['total']['total_amount'] }}</td>
                </tr>
                <tr>
                    <td>Sales</td>
                    <td>${{ $taxSummary['sales']['taxable_amount'] }}</td>
                    <td>${{ $taxSummary['sales']['non_taxable_amount'] }}</td>
                    <td>${{ $taxSummary['sales']['total_amount'] }}</td>
                </tr>
                <tr>
                    <td>Service Charge</td>
                    <td>${{ $taxSummary['service_charge']['taxable_amount'] }}</td>
                    <td>${{ $taxSummary['service_charge']['non_taxable_amount'] }}</td>
                    <td>${{ $taxSummary['service_charge']['total_amount'] }}</td>
                </tr>
                <tr>
                    <td>Fees</td>
                    <td>${{ $taxSummary['fees']['taxable_amount'] }}</td>
                    <td>${{ $taxSummary['fees']['non_taxable_amount'] }}</td>
                    <td>${{ $taxSummary['fees']['total_amount'] }}</td>
                </tr>
            </tbody>
        </table>
    </div>
    @endif

</body>
</html>

