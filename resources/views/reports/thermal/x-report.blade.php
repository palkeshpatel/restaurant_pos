@php
    $width = 32;
    $dashLine = str_repeat('-', $width);
@endphp
{{ str_pad($businessName, $width, ' ', STR_PAD_BOTH) }}
{{ str_pad('ACTIVITY REPORT X', $width, ' ', STR_PAD_BOTH) }}
{{ str_pad($reportDate, $width, ' ', STR_PAD_BOTH) }}
{{ str_pad($printedAt, $width, ' ', STR_PAD_BOTH) }}
{{ $dashLine }}
SALES SUMMARY:
CLOSED ORDERS:
  Guests: {{ $salesSummary['closed_orders']['guests'] }}
  PPA: {{ number_format((float)$salesSummary['closed_orders']['ppa'], 2) }}
  Net Sales: {{ number_format((float)$salesSummary['closed_orders']['net_sales'], 2) }}
  Taxes: {{ number_format((float)$salesSummary['closed_orders']['taxes'], 2) }}
  Service Charge: {{ number_format((float)$salesSummary['closed_orders']['service_charge'], 2) }}
  Tips: {{ number_format((float)$salesSummary['closed_orders']['tips'], 2) }}
  Fees: {{ number_format((float)$salesSummary['closed_orders']['fees'], 2) }}
  Total: {{ number_format((float)$salesSummary['closed_orders']['total'], 2) }}

OPEN ORDERS:
  Guests: {{ $salesSummary['open_orders']['guests'] }}
  PPA: {{ number_format((float)$salesSummary['open_orders']['ppa'], 2) }}
  Net Sales: {{ number_format((float)$salesSummary['open_orders']['net_sales'], 2) }}
  Taxes: {{ number_format((float)$salesSummary['open_orders']['taxes'], 2) }}
  Service Charge: {{ number_format((float)$salesSummary['open_orders']['service_charge'], 2) }}
  Tips: {{ number_format((float)$salesSummary['open_orders']['tips'], 2) }}
  Fees: {{ number_format((float)$salesSummary['open_orders']['fees'], 2) }}
  Total: {{ number_format((float)$salesSummary['open_orders']['total'], 2) }}

TOTAL SALES:
  Guests: {{ $salesSummary['total_sales']['guests'] }}
  PPA: {{ number_format((float)$salesSummary['total_sales']['ppa'], 2) }}
  Total Amount: {{ number_format((float)$salesSummary['total_sales']['total_amount'], 2) }}
{{ $dashLine }}
PAYMENTS:
  Cash: QTY {{ $payments['payments']['cash']['qty'] }}, Tips {{ number_format((float)$payments['payments']['cash']['tips'], 2) }}, Total {{ number_format((float)$payments['payments']['cash']['total'], 2) }}
  Card: QTY {{ $payments['payments']['card']['qty'] }}, Tips {{ number_format((float)$payments['payments']['card']['tips'], 2) }}, Total {{ number_format((float)$payments['payments']['card']['total'], 2) }}
  Online: QTY {{ $payments['payments']['online']['qty'] }}, Tips {{ number_format((float)$payments['payments']['online']['tips'], 2) }}, Total {{ number_format((float)$payments['payments']['online']['total'], 2) }}
  TOTALS: Tips {{ number_format((float)$payments['totals']['tips'], 2) }}, Total {{ number_format((float)$payments['totals']['total'], 2) }}
{{ $dashLine }}
CASH SUMMARY | AMOUNT
{{ $dashLine }}
CLOSED ORDERS |{{ str_pad(number_format((float)$cashSummary['closed_orders'], 2), $width - 16, ' ', STR_PAD_LEFT) }}
OPEN ORDERS |{{ str_pad(number_format((float)$cashSummary['open_orders'], 2), $width - 13, ' ', STR_PAD_LEFT) }}
PREPAID LOAD |{{ str_pad(number_format((float)$cashSummary['prepaid_load'], 2), $width - 14, ' ', STR_PAD_LEFT) }}
PAY-IN / PAY-OUT |{{ str_pad(number_format((float)$cashSummary['pay_in_pay_out'], 2), $width - 18, ' ', STR_PAD_LEFT) }}
{{ $dashLine }}
CASH ON HAND TOTAL |{{ str_pad(number_format((float)$cashSummary['cash_on_hand_total'], 2), $width - 20, ' ', STR_PAD_LEFT) }}
{{ $dashLine }}
CASH BALANCE | AMOUNT
{{ $dashLine }}
CASH ON HAND |{{ str_pad(number_format((float)$cashBalance['cash_on_hand'], 2), $width - 14, ' ', STR_PAD_LEFT) }}
CREDIT TIPS |{{ str_pad(number_format((float)$cashBalance['credit_tips'], 2), $width - 13, ' ', STR_PAD_LEFT) }}
SERVICE CHARGE |{{ str_pad(number_format((float)$cashBalance['service_charge'], 2), $width - 16, ' ', STR_PAD_LEFT) }}
{{ $dashLine }}
TOTAL CASH |{{ str_pad(number_format((float)$cashBalance['total_cash'], 2), $width - 12, ' ', STR_PAD_LEFT) }}
@if(!empty($serverSalesTips['servers']))
{{ $dashLine }}
SERVER NAME (Sales & Tips):
@foreach($serverSalesTips['servers'] as $server)
  {{ str_pad($server['name'], 20) }} Sales {{ $server['sales'] }}, Tips {{ $server['tips'] }}
@endforeach
@if(isset($serverSalesTips['totals']))
  {{ str_pad('TOTALS', 20) }} Sales {{ $serverSalesTips['totals']['sales'] }}, Tips {{ $serverSalesTips['totals']['tips'] }}
@endif
@endif
{{ $dashLine }}

{{ str_pad('END OF REPORT', $width, ' ', STR_PAD_BOTH) }}

