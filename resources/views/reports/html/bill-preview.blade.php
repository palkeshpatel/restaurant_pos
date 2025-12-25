<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>Order Bill Preview</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background: #f4f4f4;
            padding: 20px;
            margin: 0;
        }

        .receipt {
            width: 380px;
            margin: auto;
            background: #fff;
            padding: 15px;
            border: 1px solid #ddd;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .header {
            text-align: center;
            margin-bottom: 15px;
            background: #fff;
            color: #000;
        }

        .header h1 {
            margin: 5px 0;
            font-size: 18px;
            font-weight: bold;
            color: #000;
        }

        .header h2 {
            margin: 3px 0;
            font-size: 14px;
            color: #000;
        }

        .header div {
            color: #000;
        }

        .dash-line {
            border-top: 1px dashed #000;
            margin: 10px 0;
        }

        .section-title {
            font-weight: bold;
            margin-top: 10px;
            margin-bottom: 5px;
        }

        .row {
            display: flex;
            justify-content: space-between;
            margin: 2px 0;
            font-size: 12px;
        }

        .row-indent {
            padding-left: 15px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 10px 0;
        }

        table th,
        table td {
            padding: 4px;
            text-align: left;
            border-bottom: 1px dotted #000;
            border-right: 1px dotted #000;
            font-size: 12px;
        }

        table th:last-child,
        table td:last-child {
            border-right: none;
        }

        table th {
            font-weight: bold;
            border-bottom: 1px dashed #000;
            color: #000;
            background: #fff;
        }

        table td:last-child {
            text-align: right;
            color: #000;
        }

        .footer {
            text-align: center;
            margin-top: 15px;
            font-weight: bold;
        }

        .total-row {
            font-weight: bold;
            border-top: 1px dashed #000;
            padding-top: 5px;
            margin-top: 5px;
        }
    </style>
</head>

<body>
    <div class="receipt">
        <div class="header">
            <h1>{{ $businessName }}</h1>
            <h2>ORDER BILL PREVIEW</h2>
        </div>
        <div class="dash-line"></div>

        <div class="row"><span>Date:</span><span>{{ $orderDate }}</span></div>
        <div class="row"><span>Ticket ID:</span><span>{{ $orderData['order_ticket_id'] }}</span></div>
        <div class="row"><span>Table:</span><span>{{ $orderData['table']['name'] ?? 'N/A' }}</span></div>
        <div class="row"><span>Server:</span><span>{{ $serverName }}</span></div>
        <div class="row"><span>Guests:</span><span>{{ $orderData['customer'] ?? 1 }}</span></div>

        <div class="dash-line"></div>

        @if (!empty($orderItems))
            <div class="section-title">ORDER ITEMS:</div>
            <table>
                <tr>
                    <th>Item</th>
                    <th style="text-align: right;">Price</th>
                </tr>
                @foreach ($orderItems as $item)
                    <tr>
                        <td>{{ $item['name'] }}{{ $item['qty'] > 1 ? ' (x' . $item['qty'] . ')' : '' }}</td>
                        <td style="text-align: right;">${{ $item['price'] }}</td>
                    </tr>
                @endforeach
            </table>
            <div class="dash-line"></div>
        @endif

        <div class="section-title">BILLING SUMMARY:</div>
        <table>
            <tr>
                <th>Item</th>
                <th style="text-align: right;">Amount</th>
            </tr>
            <tr>
                <td>Subtotal</td>
                <td style="text-align: right;">${{ number_format((float) ($billing['subtotal'] ?? 0), 2) }}</td>
            </tr>
            <tr>
                <td>Discount</td>
                <td style="text-align: right;">${{ number_format((float) ($billing['total_discount'] ?? 0), 2) }}</td>
            </tr>
            <tr>
                <td>Tax</td>
                <td style="text-align: right;">${{ number_format((float) ($billing['tax_amount'] ?? 0), 2) }}</td>
            </tr>
            <tr>
                <td>Gratuity</td>
                <td style="text-align: right;">${{ number_format((float) ($billing['gratuity_amount'] ?? 0), 2) }}</td>
            </tr>
            <tr>
                <td>Fees</td>
                <td style="text-align: right;">${{ number_format((float) ($billing['fee_amount'] ?? 0), 2) }}</td>
            </tr>
            @if ((float) ($billing['tip_amount'] ?? 0) > 0)
                <tr>
                    <td>Tip</td>
                    <td style="text-align: right;">${{ number_format((float) ($billing['tip_amount'] ?? 0), 2) }}</td>
                </tr>
            @endif
            <tr class="total-row">
                <td><strong>TOTAL BILL</strong></td>
                <td style="text-align: right;">
                    <strong>${{ number_format((float) ($billing['total_bill'] ?? 0), 2) }}</strong>
                </td>
            </tr>
            @php
                $paymentHistories = $paymentHistories ?? [];
            @endphp
            @if(!empty($paymentHistories) && count($paymentHistories) > 0)
                @foreach($paymentHistories as $index => $payment)
                @php
                    $isRefund = ($payment['status'] === 'refunded') || (($payment['refunded_payment_id'] ?? 0) !== 0);
                @endphp
                <tr>
                    <td>
                        @if($isRefund)
                            Refund ({{ $payment['payment_mode'] }})
                        @else
                            Paid ({{ $payment['payment_mode'] }})
                        @endif
                    </td>
                    <td style="text-align: right;">
                        @if($isRefund)
                            -${{ number_format((float)($payment['amount'] ?? 0), 2) }}
                        @else
                            ${{ number_format((float)($payment['amount'] ?? 0), 2) }}
                        @endif
                    </td>
                </tr>
                @endforeach
                <tr>
                    <td><strong>Total Paid</strong></td>
                    <td style="text-align: right;"><strong>${{ number_format((float)($billing['paid_amount'] ?? 0), 2) }}</strong></td>
                </tr>
            @elseif((float)($billing['paid_amount'] ?? 0) > 0)
                <tr>
                    <td>Paid</td>
                    <td style="text-align: right;">${{ number_format((float)($billing['paid_amount'] ?? 0), 2) }}</td>
                </tr>
            @endif
            <tr>
                <td>Remaining</td>
                <td style="text-align: right;">${{ number_format((float) ($billing['remaining_amount'] ?? 0), 2) }}
                </td>
            </tr>
        </table>

        <div class="dash-line"></div>
        <div class="footer">END OF BILL</div>
        <div style="text-align: center; font-size: 11px; margin-top: 5px;">Generated: {{ date('m/d/Y h:i:s A') }}</div>
    </div>
</body>

</html>
