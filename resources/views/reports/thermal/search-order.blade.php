@php
    $width = 32;
    $dashLine = str_repeat('-', $width);
@endphp
{{ str_pad($businessName, $width, ' ', STR_PAD_BOTH) }}
{{ str_pad('ORDER BILL PREVIEW', $width, ' ', STR_PAD_BOTH) }}
{{ $dashLine }}
Date: {{ $orderDate }}
Ticket ID: {{ $orderData['order_ticket_id'] }}
Table: {{ $orderData['table']['name'] ?? 'N/A' }}
Server: {{ $serverName }}
Guests: {{ $orderData['customer'] ?? 1 }}
{{ $dashLine }}
@if(!empty($orderItems))
ORDER ITEMS:
@foreach($orderItems as $item)
  {{ $item['name'] }}{{ $item['qty'] > 1 ? ' (x' . $item['qty'] . ')' : '' }} - ${{ $item['price'] }}
@endforeach
{{ $dashLine }}
@endif
@if(!empty($billing) && isset($billing['total_bill']))
BILLING SUMMARY:
Subtotal: ${{ number_format((float)($billing['subtotal'] ?? 0), 2) }}
Discount: ${{ number_format((float)($billing['total_discount'] ?? 0), 2) }}
Tax: ${{ number_format((float)($billing['tax_amount'] ?? 0), 2) }}
Gratuity: ${{ number_format((float)($billing['gratuity_amount'] ?? 0), 2) }}
Fees: ${{ number_format((float)($billing['fee_amount'] ?? 0), 2) }}
@if((float)($billing['tip_amount'] ?? 0) > 0)
Tip: ${{ number_format((float)($billing['tip_amount'] ?? 0), 2) }}
@endif
{{ $dashLine }}
TOTAL BILL: ${{ number_format((float)($billing['total_bill'] ?? 0), 2) }}
@php
    $paymentHistories = $paymentHistories ?? [];
@endphp
@if(!empty($paymentHistories) && count($paymentHistories) > 0)
@foreach($paymentHistories as $index => $payment)
@php
    $isRefund = ($payment['status'] === 'refunded') || (($payment['refunded_payment_id'] ?? 0) !== 0);
@endphp
@if($isRefund)
Refund ({{ $payment['payment_mode'] }}): -${{ number_format((float)($payment['amount'] ?? 0), 2) }}
@else
Paid ({{ $payment['payment_mode'] }}): ${{ number_format((float)($payment['amount'] ?? 0), 2) }}
@endif
@endforeach
Total Paid: ${{ number_format((float)($billing['paid_amount'] ?? 0), 2) }}
@elseif((float)($billing['paid_amount'] ?? 0) > 0)
Paid: ${{ number_format((float)($billing['paid_amount'] ?? 0), 2) }}
@endif
Remaining: ${{ number_format((float)($billing['remaining_amount'] ?? 0), 2) }}
{{ $dashLine }}
@endif

{{ str_pad('END OF BILL', $width, ' ', STR_PAD_BOTH) }}
Generated: {{ date('m/d/Y h:i:s A') }}

