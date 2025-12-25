<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>X-Report</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background: #fff;
            padding: 20px;
            margin: 0;
            color: #000;
        }

        .receipt {
            width: 380px;
            margin: auto;
            background: #fff;
            padding: 15px;
            border: 1px solid #000;
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
            color: #000;
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
            color: #000;
        }

        .total-row {
            font-weight: bold;
            border-top: 1px dashed #000;
            padding-top: 5px;
            margin-top: 5px;
            color: #000;
        }

        @media print {
            body {
                background: #fff;
            }

            .receipt {
                box-shadow: none;
                border: none;
            }

            * {
                color: #000 !important;
                background: #fff !important;
            }
        }
    </style>
</head>

<body>
    <div class="receipt">
        <div class="header">
            <h1>{{ $businessName }}</h1>
            <h2>ACTIVITY REPORT X</h2>
            <div>{{ $reportDate }}</div>
            <div>{{ $printedAt }}</div>
        </div>
        <div class="dash-line"></div>

        <div class="section-title">SALES SUMMARY:</div>
        <div class="section-title row-indent">CLOSED ORDERS:</div>
        <div class="row row-indent"><span>Guests:</span><span>{{ $salesSummary['closed_orders']['guests'] }}</span></div>
        <div class="row row-indent">
            <span>PPA:</span><span>{{ number_format((float) $salesSummary['closed_orders']['ppa'], 2) }}</span>
        </div>
        <div class="row row-indent"><span>Net
                Sales:</span><span>{{ number_format((float) $salesSummary['closed_orders']['net_sales'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Taxes:</span><span>{{ number_format((float) $salesSummary['closed_orders']['taxes'], 2) }}</span>
        </div>
        <div class="row row-indent"><span>Service
                Charge:</span><span>{{ number_format((float) $salesSummary['closed_orders']['service_charge'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Tips:</span><span>{{ number_format((float) $salesSummary['closed_orders']['tips'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Fees:</span><span>{{ number_format((float) $salesSummary['closed_orders']['fees'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Total:</span><span>{{ number_format((float) $salesSummary['closed_orders']['total'], 2) }}</span>
        </div>

        <div class="section-title row-indent">OPEN ORDERS:</div>
        <div class="row row-indent"><span>Guests:</span><span>{{ $salesSummary['open_orders']['guests'] }}</span></div>
        <div class="row row-indent">
            <span>PPA:</span><span>{{ number_format((float) $salesSummary['open_orders']['ppa'], 2) }}</span>
        </div>
        <div class="row row-indent"><span>Net
                Sales:</span><span>{{ number_format((float) $salesSummary['open_orders']['net_sales'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Taxes:</span><span>{{ number_format((float) $salesSummary['open_orders']['taxes'], 2) }}</span>
        </div>
        <div class="row row-indent"><span>Service
                Charge:</span><span>{{ number_format((float) $salesSummary['open_orders']['service_charge'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Tips:</span><span>{{ number_format((float) $salesSummary['open_orders']['tips'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Fees:</span><span>{{ number_format((float) $salesSummary['open_orders']['fees'], 2) }}</span>
        </div>
        <div class="row row-indent">
            <span>Total:</span><span>{{ number_format((float) $salesSummary['open_orders']['total'], 2) }}</span>
        </div>

        <div class="section-title row-indent">TOTAL SALES:</div>
        <div class="row row-indent"><span>Guests:</span><span>{{ $salesSummary['total_sales']['guests'] }}</span></div>
        <div class="row row-indent">
            <span>PPA:</span><span>{{ number_format((float) $salesSummary['total_sales']['ppa'], 2) }}</span>
        </div>
        <div class="row row-indent"><span>Total
                Amount:</span><span>{{ number_format((float) $salesSummary['total_sales']['total_amount'], 2) }}</span>
        </div>

        <div class="dash-line"></div>

        <div class="section-title">PAYMENTS:</div>
        <div class="row row-indent"><span>Cash: QTY {{ $payments['payments']['cash']['qty'] }}, Tips
                {{ number_format((float) $payments['payments']['cash']['tips'], 2) }}, Total
                {{ number_format((float) $payments['payments']['cash']['total'], 2) }}</span></div>
        <div class="row row-indent"><span>Card: QTY {{ $payments['payments']['card']['qty'] }}, Tips
                {{ number_format((float) $payments['payments']['card']['tips'], 2) }}, Total
                {{ number_format((float) $payments['payments']['card']['total'], 2) }}</span></div>
        <div class="row row-indent"><span>Online: QTY {{ $payments['payments']['online']['qty'] }}, Tips
                {{ number_format((float) $payments['payments']['online']['tips'], 2) }}, Total
                {{ number_format((float) $payments['payments']['online']['total'], 2) }}</span></div>
        <div class="row row-indent total-row"><span>TOTALS: Tips
                {{ number_format((float) $payments['totals']['tips'], 2) }}, Total
                {{ number_format((float) $payments['totals']['total'], 2) }}</span></div>

        <div class="dash-line"></div>

        <div class="section-title">CASH SUMMARY | AMOUNT</div>
        <table>
            <tr>
                <th>Item</th>
                <th style="text-align: right;">Amount</th>
            </tr>
            <tr>
                <td>CLOSED ORDERS |</td>
                <td style="text-align: right;">{{ number_format((float) $cashSummary['closed_orders'], 2) }}</td>
            </tr>
            <tr>
                <td>OPEN ORDERS |</td>
                <td style="text-align: right;">{{ number_format((float) $cashSummary['open_orders'], 2) }}</td>
            </tr>
            <tr>
                <td>PREPAID LOAD |</td>
                <td style="text-align: right;">{{ number_format((float) $cashSummary['prepaid_load'], 2) }}</td>
            </tr>
            <tr>
                <td>PAY-IN / PAY-OUT |</td>
                <td style="text-align: right;">{{ number_format((float) $cashSummary['pay_in_pay_out'], 2) }}</td>
            </tr>
            <tr class="total-row">
                <td><strong>CASH ON HAND TOTAL |</strong></td>
                <td style="text-align: right;">
                    <strong>{{ number_format((float) $cashSummary['cash_on_hand_total'], 2) }}</strong>
                </td>
            </tr>
        </table>

        <div class="dash-line"></div>

        <div class="section-title">CASH BALANCE | AMOUNT</div>
        <table>
            <tr>
                <th>Item</th>
                <th style="text-align: right;">Amount</th>
            </tr>
            <tr>
                <td>CASH ON HAND |</td>
                <td style="text-align: right;">{{ number_format((float) $cashBalance['cash_on_hand'], 2) }}</td>
            </tr>
            <tr>
                <td>CREDIT TIPS |</td>
                <td style="text-align: right;">{{ number_format((float) $cashBalance['credit_tips'], 2) }}</td>
            </tr>
            <tr>
                <td>SERVICE CHARGE |</td>
                <td style="text-align: right;">{{ number_format((float) $cashBalance['service_charge'], 2) }}</td>
            </tr>
            <tr class="total-row">
                <td><strong>TOTAL CASH |</strong></td>
                <td style="text-align: right;">
                    <strong>{{ number_format((float) $cashBalance['total_cash'], 2) }}</strong>
                </td>
            </tr>
        </table>

        @if (!empty($serverSalesTips['servers']))
            <div class="dash-line"></div>
            <div class="section-title">SERVER NAME (Sales & Tips):</div>
            @foreach ($serverSalesTips['servers'] as $server)
                <div class="row row-indent"><span>{{ $server['name'] }}</span><span>Sales {{ $server['sales'] }}, Tips
                        {{ $server['tips'] }}</span></div>
            @endforeach
            @if (isset($serverSalesTips['totals']))
                <div class="row row-indent total-row"><span>TOTALS</span><span>Sales
                        {{ $serverSalesTips['totals']['sales'] }}, Tips
                        {{ $serverSalesTips['totals']['tips'] }}</span></div>
            @endif
        @endif

        <div class="dash-line"></div>
        <div class="footer">END OF REPORT</div>
    </div>
</body>

</html>
