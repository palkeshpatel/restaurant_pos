# X-Report (Activity Report)

**Endpoint:** `GET /api/pos/reports/x-report`

**Purpose:** Shows current shift activity without resetting counters. Used during the day to check current sales status.

## Query Parameters

- `date` (optional): Date for the report in `YYYY-MM-DD` format. Defaults to today if not provided.
- `employee_id` (optional): Filter by specific employee/server ID. If not provided, shows all employees.
- `format` (optional): Response format - `json` (default), `text`, or `pdf`

## Report Sections

### 1. Sales Summary

#### Closed Orders
- **Guests**: Total number of customers from all completed orders
  - **Source**: Sum of `orders.customer` field where `status = 'completed'`
  - **Calculation**: `$closedOrders->sum('customer')`

- **PPA (Per Person Average)**: Average spending per guest
  - **Calculation**: `Net Sales / Guests`
  - **Formula**: `$closedData['net_sales'] / $closedData['guests']`

- **Net Sales**: Total sales after discounts, excluding taxes, fees, tips
  - **Source**: Sum of all order items from completed orders
  - **Calculation**: 
    ```
    For each order item:
      itemTotal = (unit_price * qty) + modifiers - discount_amount
      netSales += itemTotal
    ```

- **Taxes**: Total tax amount from completed orders
  - **Source**: Sum of `orders.tax_value` where `status = 'completed'`
  - **Calculation**: `$order->tax_value ?? 0`

- **Service Charge**: Total gratuity/service charge
  - **Source**: Calculated from `orders.gratuity_key`, `gratuity_type`, `gratuity_value`
  - **Calculation**:
    - If `gratuity_key = 'NotApplicable'`: 0
    - If `gratuity_key = 'Manual'`:
      - If `gratuity_type = 'percentage'`: `(netSales + taxes) * gratuity_value / 100`
      - If `gratuity_type = 'fixed'`: `gratuity_value`
    - If `gratuity_key = 'Auto'`: Uses `gratuity_settings` table
      - If `gratuity_type = 'percentage'`: `(netSales + taxes) * gratuity_value / 100`
      - If `gratuity_type = 'fixed'`: `gratuity_value`

- **Tips**: Total tips from payment history
  - **Source**: `payment_histories` table where `status = 'completed'`
  - **Calculation**: `PaymentHistory::where('order_id', $order->id)->where('status', 'completed')->sum('tip_amount')`

- **Fees**: Total fees from completed orders
  - **Source**: Sum of `orders.fee_value` where `status = 'completed'`
  - **Calculation**: `$order->fee_value ?? 0`

- **Total**: Sum of all above
  - **Calculation**: `Net Sales + Taxes + Service Charge + Tips + Fees`

#### Open Orders
- Same fields as Closed Orders, but for orders where `status != 'completed'`
- Includes pending, in-progress, or hold orders

#### Total Sales
- **Guests**: Combined guests from closed + open orders
- **PPA**: Combined PPA from closed + open orders
- **Total Amount**: Combined total from closed + open orders

### 2. Payments

Breakdown by payment method (Cash, Card, Online):

- **Qty**: Number of payments for this method
  - **Source**: Count of `payment_histories` where `payment_mode = 'cash'/'card'/'online'` and `status = 'completed'`

- **Tips**: Total tips from this payment method
  - **Source**: Sum of `payment_histories.tip_amount` where `payment_mode = method` and `status = 'completed'`

- **Total**: Total payment amount for this method
  - **Source**: Sum of `payment_histories.amount` where `payment_mode = method` and `status = 'completed'`

- **Totals**: Combined totals across all payment methods

### 3. Cash Summary

- **Closed Orders**: Cash payments from completed orders
  - **Source**: `PaymentHistory::where('payment_mode', 'cash')->where('status', 'completed')->sum('amount')` for closed orders

- **Open Orders**: Cash payments from open orders
  - **Source**: Same as above but for open orders

- **Prepaid Load**: Currently same as closed orders cash (can be customized)

- **Pay In/Pay Out**: Currently 0.00 (can be customized for drawer operations)

- **Cash On Hand Total**: Sum of closed + open cash payments

### 4. Cash Balance

- **Cash On Hand**: Total cash payments (from Cash Summary)
- **Credit Tips**: Tips from non-cash payments (card, online)
  - **Source**: `PaymentHistory::where('payment_mode', '!=', 'cash')->where('status', 'completed')->sum('tip_amount')`
- **Service Charge**: Total service charge (same as in Sales Summary)
- **Total Cash**: `Cash On Hand + Credit Tips + Service Charge`

### 5. Server Sales & Tips

Individual breakdown per server/employee:

- **Name**: Employee full name (`first_name + last_name`)
- **Sales**: Net sales for orders created by this employee
  - **Source**: Sum of net sales from `orders` where `created_by_employee_id = employee_id`
- **Tips**: Total tips from orders created by this employee
  - **Source**: Sum of tips from `payment_histories` for orders created by this employee

- **Totals**: Combined sales and tips across all servers

## Response Format

The report can be returned in three formats:

1. **JSON** (default): Full data structure with all calculations
2. **Text**: Plain text thermal format (32-character width) for direct printing
3. **PDF**: PDF document (currently returns text format)

## Example Request

```bash
GET /api/pos/reports/x-report?date=2025-11-05&employee_id=1&format=json
```

## Notes

- Only orders with `status = 'completed'` are included in closed order calculations
- Items with `order_status = 3` (voided) are excluded from all calculations
- Only payments with `status = 'completed'` are included
- Report filters by `business_id` from authenticated employee
- Optional `employee_id` parameter filters by `created_by_employee_id`

