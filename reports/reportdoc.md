# Reports Documentation

This document explains all reports in the POS system, including what each field represents and how values are calculated.

---

## Table of Contents

1. [X-Report (Activity Report)](#x-report-activity-report)
2. [Z-Report (Daily Report)](#z-report-daily-report)
3. [Bill Preview Report](#bill-preview-report)
4. [Search Order Report](#search-order-report)
5. [End of Date Report](#end-of-date-report)
6. [Daily Summary Report (Admin)](#daily-summary-report-admin)

---

## X-Report (Activity Report)

**Endpoint:** `GET /api/pos/reports/x-report`

**Purpose:** Shows current shift activity without resetting counters. Used during the day to check current sales status.

### Report Sections

#### 1. Sales Summary

##### Closed Orders
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

##### Open Orders
- Same fields as Closed Orders, but for orders where `status != 'completed'`
- Includes pending, in-progress, or hold orders

##### Total Sales
- **Guests**: Combined guests from closed + open orders
- **PPA**: Combined PPA from closed + open orders
- **Total Amount**: Combined total from closed + open orders

#### 2. Payments

Breakdown by payment method (Cash, Card, Online):

- **Qty**: Number of payments for this method
  - **Source**: Count of `payment_histories` where `payment_mode = 'cash'/'card'/'online'` and `status = 'completed'`

- **Tips**: Total tips from this payment method
  - **Source**: Sum of `payment_histories.tip_amount` where `payment_mode = method` and `status = 'completed'`

- **Total**: Total payment amount for this method
  - **Source**: Sum of `payment_histories.amount` where `payment_mode = method` and `status = 'completed'`

- **Totals**: Combined totals across all payment methods

#### 3. Cash Summary

- **Closed Orders**: Cash payments from completed orders
  - **Source**: `PaymentHistory::where('payment_mode', 'cash')->where('status', 'completed')->sum('amount')` for closed orders

- **Open Orders**: Cash payments from open orders
  - **Source**: Same as above but for open orders

- **Prepaid Load**: Currently same as closed orders cash (can be customized)

- **Pay In/Pay Out**: Currently 0.00 (can be customized for drawer operations)

- **Cash On Hand Total**: Sum of closed + open cash payments

#### 4. Cash Balance

- **Cash On Hand**: Total cash payments (from Cash Summary)
- **Credit Tips**: Tips from non-cash payments (card, online)
  - **Source**: `PaymentHistory::where('payment_mode', '!=', 'cash')->where('status', 'completed')->sum('tip_amount')`
- **Service Charge**: Total service charge (same as in Sales Summary)
- **Total Cash**: `Cash On Hand + Credit Tips + Service Charge`

#### 5. Server Sales & Tips

Individual breakdown per server/employee:

- **Name**: Employee full name (`first_name + last_name`)
- **Sales**: Net sales for orders created by this employee
  - **Source**: Sum of net sales from `orders` where `created_by_employee_id = employee_id`
- **Tips**: Total tips from orders created by this employee
  - **Source**: Sum of tips from `payment_histories` for orders created by this employee

- **Totals**: Combined sales and tips across all servers

---

## Z-Report (Daily Report)

**Endpoint:** `GET /api/pos/reports/z-report`

**Purpose:** End-of-day summary report. Shows complete daily totals and is typically printed at closing time.

### Report Sections

#### 1. Sales Summary
Same structure as X-Report (Closed Orders, Open Orders, Total Sales)

#### 2. Payments
Same structure as X-Report

#### 3. Cash Out

- **Credit Tips**: Tips from card/online payments
  - **Source**: `PaymentHistory::where('payment_mode', '!=', 'cash')->where('status', 'completed')->sum('tip_amount')`

- **Service Charge**: Total service charge for the day
  - **Source**: Calculated from all orders (same as X-Report)

- **Cash On Hand**: Total cash payments
  - **Source**: `PaymentHistory::where('payment_mode', 'cash')->where('status', 'completed')->sum('amount')`

#### 4. Total Owed to Restaurant

- **Calculation**: `Cash On Hand - (Credit Tips + Service Charge)`
- **Meaning**: Amount that should remain in the cash drawer after paying out tips and service charge

#### 5. Total Tips

- **Calculation**: `Cash Tips + Credit Tips`
- **Source**: 
  - Cash Tips: `PaymentHistory::where('payment_mode', 'cash')->sum('tip_amount')`
  - Credit Tips: `PaymentHistory::where('payment_mode', '!=', 'cash')->sum('tip_amount')`

#### 6. Suggested Tip Out

Breakdown by role (Bar, Busser, Runner, Bar Back):

- **Role**: Employee role name
- **Percentage**: Tip out percentage (e.g., 10% for Bar, 3% for Busser)
- **Base Amount**: Net sales from closed orders
  - **Source**: `$salesSummary['closed_orders']['net_sales']`
- **Tip Out**: Calculated tip out amount
  - **Calculation**: `(Base Amount * Percentage) / 100`
  - **Example**: If net sales = $1000, Bar (10%) = $100

#### 7. Server Sales & Tips
Same as X-Report

#### 8. Report Number

- **Format**: `YEAR-DAYOFYEAR` (e.g., 2025-307)
- **Calculation**: 
  - Year: `Carbon::parse($reportDate)->format('Y')`
  - Day of Year: `Carbon::parse($reportDate)->format('z') + 1` (0-based, so add 1)

---

## Bill Preview Report

**Endpoint:** `GET /api/pos/order/bill-preview?order_ticket_id=ORD-XXX`

**Purpose:** Shows detailed billing breakdown for a specific order. Used to preview bill before payment.

### Report Fields

#### Order Information

- **Order Ticket ID**: Unique order identifier (e.g., `ORD-20251103-U9VFRB`)
  - **Source**: `orders.order_ticket_id`

- **Order Ticket Title**: Short order identifier (e.g., `20251103-01T1`)
  - **Source**: `orders.order_ticket_title`

- **Status**: Order status (`open` or `completed`)
  - **Source**: `orders.status`

- **Date**: Order creation date and time
  - **Source**: `orders.created_at`

- **Table**: Table name
  - **Source**: `restaurant_tables.name` via `orders.table_id`

- **Server**: Employee who created the order
  - **Source**: `employees.first_name + last_name` via `orders.created_by_employee_id`

- **Guests**: Number of customers
  - **Source**: `orders.customer`

#### Order Items

Each item shows:
- **Name**: Menu item name
  - **Source**: `menu_items.name` via `order_items.menu_item_id`
- **Qty**: Quantity ordered
  - **Source**: `order_items.qty`
- **Price**: Total price for this item
  - **Calculation**: `(unit_price * qty) + modifiers - discount_amount`
  - **Modifiers**: Sum of `modifier_order_item.price * modifier_order_item.qty`
- **Unit Price**: Price per unit
  - **Source**: `order_items.unit_price`

#### Billing Summary

- **Subtotal**: Total before discount (sum of all item prices including modifiers)
  - **Calculation**: 
    ```
    For each order item:
      itemTotal = (unit_price * qty) + modifiers
      subtotal += itemTotal
    ```

- **Total Discount**: Total discount amount applied
  - **Source**: Sum of `order_items.discount_amount`
  - **Calculation**: `$item->discount_amount ?? 0` for all items

- **Tax Amount**: Tax calculated on food items
  - **Source**: `orders.tax_value`
  - **Note**: Tax is typically applied on `(subtotal - discount)`

- **Gratuity Amount**: Service charge/gratuity
  - **Calculation**: Same as X-Report (based on `gratuity_key`, `gratuity_type`, `gratuity_value`)
  - **Applied On**: `(subtotal - discount + tax)`

- **Fee Amount**: Additional fees
  - **Source**: `orders.fee_value`
  - **Calculation**: Percentage from `fees` table applied to `(subtotal - discount)`

- **Tip Amount**: Tips from payment history
  - **Source**: Sum of `payment_histories.tip_amount` where `status = 'completed'`

- **Total Bill**: Final amount
  - **Calculation**: `Subtotal - Total Discount + Tax Amount + Gratuity Amount + Fee Amount + Tip Amount`

- **Paid Amount**: Total paid so far
  - **Source**: Sum of `payment_histories.amount` where `status = 'completed'`

- **Remaining Amount**: Amount still to pay
  - **Calculation**: `Total Bill - Paid Amount`

---

## Search Order Report

**Endpoint:** `GET /api/pos/search-order?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`

**Purpose:** Search and retrieve orders by date range. Returns list of orders with billing summaries.

### Query Parameters

- **start_date**: Start date (YYYY-MM-DD). If only this is provided, returns single day
- **end_date**: End date (YYYY-MM-DD). If provided, returns date range
- **status**: Filter by status (`open`, `completed`, `hold`, `cancelled`)
- **order_ticket_id**: Search by order ticket ID
- **table_id**: Filter by table
- **employee_id**: Filter by employee
- **search**: Search in order_ticket_id, order_ticket_title, or table name
- **per_page**: Pagination limit (default: 50)
- **page**: Page number (default: 1)
- **pdf**: If `true`, returns PDF document

### Response Fields

For each order:

- **id**: Order ID
- **order_ticket_id**: Unique order identifier
- **order_ticket_title**: Short order identifier
- **status**: Order status
- **customer**: Number of guests
- **created_at**: Order creation date
- **table**: Table information (id, name)
- **created_by_employee**: Employee information (id, first_name, last_name)
- **billing_summary**: Same structure as Bill Preview Report
  - **subtotal**: Sum of item prices + modifiers
  - **total_discount**: Sum of discounts
  - **tax_amount**: Tax value
  - **gratuity_amount**: Service charge
  - **fee_amount**: Fees
  - **tip_amount**: Tips
  - **total_bill**: Total amount
  - **paid_amount**: Amount paid
  - **remaining_amount**: Amount remaining
- **thermal_format**: Formatted text for thermal printer
- **thermal_format_html**: HTML formatted version

### Calculation Logic

Same as Bill Preview Report for each order's billing summary.

---

## End of Date Report

**Endpoint:** 
- `GET /api/pos/end-of-date?date=YYYY-MM-DD` - Check EOD status
- `POST /api/pos/make-end-of-date` - Create/complete EOD

**Purpose:** Mark end of day and track daily completion status.

### GET End of Date Status

Returns:
- **date**: Date checked
- **has_eod**: Whether EOD exists for this date
- **eod_status**: Status (`pending` or `completed`)
- **eod_data**: EOD record if exists
  - **id**: EOD record ID
  - **eod_date**: Date
  - **completed_at**: Completion timestamp
  - **completed_by_employee_id**: Employee who completed
  - **status**: Status
  - **total_sales**: Total sales for the day
  - **total_orders**: Total orders for the day
  - **notes**: Notes

### POST Make End of Date

**Validation Rules:**
1. Cannot make EOD if there are previous dates without EOD completion
2. Cannot make EOD if there are active (non-completed) orders on the requested date
3. Allowed if the date has no orders (e.g., Sunday with no orders)

**Request Body:**
- **date**: Date with time (e.g., `2024-12-16 23:59:59`)
- **notes**: Optional notes

**Response:**
- **id**: EOD record ID
- **business_id**: Business ID
- **eod_date**: Date
- **completed_at**: Completion timestamp
- **status**: `completed`
- **total_sales**: Calculated total sales
  - **Source**: Sum of `total_bill` from all completed orders for the date
  - **Calculation**: For each completed order, calculate bill amounts using `calculateBillAmounts()` method
- **total_orders**: Count of completed orders
  - **Source**: Count of `orders` where `status = 'completed'` and date matches
- **notes**: Notes provided
- **completed_by_employee**: Employee information

---

## Daily Summary Report (Admin)

**Endpoint:** `GET /api/admin/reports/daily-summary?date=YYYY-MM-DD`

**Purpose:** Comprehensive business report for admin dashboard. Shows detailed breakdown by department, daypart, revenue centers, etc.

### Report Sections

#### 1. Sales by Department/Sub-department

Groups sales by menu category hierarchy:

- **Department**: Parent category name (or category name if no parent)
- **Sub-department**: Child category name (if exists)

For each department:
- **Gross Sales**: Total before discounts
  - **Calculation**: Sum of `(unit_price * qty)` for all items in this category
- **Net Sales**: Total after discounts
  - **Calculation**: `Gross Sales - discount_amount`
- **Tax**: Tax amount (proportionally distributed)
  - **Calculation**: `(department_gross_sales / total_gross_sales) * total_tax`
- **Comps**: Total discounts/comps
  - **Source**: Sum of `order_items.discount_amount`
- **Voids**: Voided items amount
  - **Source**: Items where `order_status = 3`
- **Gross Sales %**: Percentage of total gross sales
- **Net Sales %**: Percentage of total net sales

#### 2. Sales by Daypart/Shift

Groups sales by time of day:

- **Dayparts**: Breakfast (6-11), Lunch (11-16), Dinner (16-23), Late Night (23-6)
- **Determination**: Based on `orders.created_at` hour

For each daypart:
- **Gross Sales**: Total before discounts
- **Net Sales**: Total after discounts
- **Comps**: Discounts
- **Fees**: Fees
- **Sales Plus Fees**: `Net Sales + Fees`
- **Orders**: Count of orders
- **Avg Order**: `Net Sales / Orders`
- **Guests**: Total guests
- **PPA**: `Net Sales / Guests`
- **Gross Sales %**: Percentage of total
- **Net Sales %**: Percentage of total

#### 3. Revenue Centers

Currently shows single "Restaurant (default)" center with totals:
- Same fields as Sales by Daypart

#### 4. Order Type

Breakdown by order type (Seated, TA, Delivery):
- Same fields as Sales by Daypart
- Currently defaults to "Seated" for all orders

#### 5. Exceptions

- **Marketing Comps**: Discounts/comps
  - **Source**: Items with `discount_amount > 0`
- **Organizational**: Currently 0 (can be customized)
- **Voids**: Voided items
  - **Source**: Items where `order_status = 3`
- **Actions**: Count of exceptions
- **Amount**: Total amount
- **% from Gross**: `(Amount / Total Gross Sales) * 100`
- **% from Net**: `(Amount / Total Net Sales) * 100`

#### 6. Payments Breakdown

For each payment method:
- **Payment Count**: Number of payments
- **Payment Amount**: Total payment amount
- **Refund Count**: Number of refunds
- **Refund Amount**: Total refund amount
- **Total Amount**: `Payment Amount - Refund Amount`

#### 7. Cash Summary

- **Drawers**: Drawer operations (currently empty, can be customized)
- **Totals**: Total actions and amount

#### 8. Tips & Cash Balance

- **Total Cash Balance**: Total cash on hand
- **Cash On Hand**: Cash payments
- **Subtotal Tips Service Charge**: `Tips + Service Charge`
- **Service Charge**: Total service charge
- **Tips**: Total tips

#### 9. Taxes

For each tax rate:
- **Rate**: Tax rate (e.g., "6.625%")
- **Taxable Amount**: Amount subject to tax
- **Tax Collected**: Tax amount collected

#### 10. Tax Summary

- **Total**:
  - **Taxable Amount**: Sales subject to tax
  - **Non-Taxable Amount**: Service charge + fees
  - **Total Amount**: `Taxable + Non-Taxable`
- **Sales**: Taxable sales
- **Service Charge**: Non-taxable
- **Fees**: Non-taxable

#### 11. Tax Exemptions

- **Exemptions**: List of tax-exempt orders (currently empty)
- **Totals**: Count and amount

---

## Common Calculations

### Net Sales Calculation

```
For each order:
  For each check:
    For each order item (excluding voided):
      itemTotal = (unit_price * qty)
      
      // Add modifiers
      For each modifier:
        itemTotal += (modifier_price * modifier_qty)
      
      // Subtract discount
      itemTotal -= discount_amount
      
      netSales += itemTotal
```

### Tax Calculation

- Tax is stored at order level in `orders.tax_value`
- Typically calculated as: `(subtotal - discount) * tax_rate / 100`

### Gratuity/Service Charge Calculation

1. Check `orders.gratuity_key`:
   - `'NotApplicable'`: Return 0
   - `'Manual'`: Use `gratuity_type` and `gratuity_value` from order
   - `'Auto'`: Look up `gratuity_settings` table for business

2. Calculate base amount: `netSales + taxes`

3. Apply gratuity:
   - If `gratuity_type = 'percentage'`: `base_amount * gratuity_value / 100`
   - If `gratuity_type = 'fixed'`: `gratuity_value`

### Fee Calculation

- Stored in `orders.fee_value`
- Typically calculated as percentage from `fees` table
- Applied to: `(subtotal - discount)`

### Tips Calculation

- Source: `payment_histories` table
- Sum of `tip_amount` where `status = 'completed'`
- Can be filtered by payment method (cash vs credit)

---

## Data Sources

### Main Tables

- **orders**: Order information
  - `id`, `order_ticket_id`, `order_ticket_title`, `status`, `customer`, `created_at`, `business_id`, `created_by_employee_id`, `tax_value`, `fee_value`, `gratuity_key`, `gratuity_type`, `gratuity_value`

- **order_items**: Order line items
  - `id`, `order_id`, `check_id`, `menu_item_id`, `qty`, `unit_price`, `discount_amount`, `order_status`, `customer_no`

- **checks**: Order checks (for split bills)
  - `id`, `order_id`, `type`

- **payment_histories**: Payment records
  - `id`, `order_id`, `payment_mode`, `amount`, `tip_amount`, `status`, `created_at`

- **menu_items**: Menu items
  - `id`, `name`, `menu_category_id`

- **menu_categories**: Menu categories
  - `id`, `name`, `parent_id`

- **employees**: Employees
  - `id`, `first_name`, `last_name`, `business_id`

- **restaurant_tables**: Tables
  - `id`, `name`, `floor_id`

- **modifier_order_item**: Modifiers on items (pivot table)
  - `order_item_id`, `modifier_id`, `price`, `qty`

- **gratuity_settings**: Gratuity settings
  - `id`, `business_id`, `gratuity_type`, `gratuity_value`

- **end_of_days**: End of day records
  - `id`, `business_id`, `eod_date`, `completed_at`, `completed_by_employee_id`, `status`, `total_sales`, `total_orders`, `notes`

---

## Notes

1. **Voided Items**: Items with `order_status = 3` are excluded from calculations
2. **Completed Orders**: Only orders with `status = 'completed'` are included in closed order calculations
3. **Payment Status**: Only payments with `status = 'completed'` are included
4. **Date Filtering**: All reports filter by date range using `created_at` field
5. **Business Filtering**: All reports filter by `business_id` from authenticated employee
6. **Employee Filtering**: Optional `employee_id` parameter filters by `created_by_employee_id`
7. **Format Options**: Reports support `format=json`, `format=text`, `format=pdf` (where applicable)

---

## API Endpoints Summary

| Report | Endpoint | Method |
|--------|----------|--------|
| X-Report | `/api/pos/reports/x-report` | GET |
| Z-Report | `/api/pos/reports/z-report` | GET |
| Bill Preview | `/api/pos/order/bill-preview` | GET |
| Search Order | `/api/pos/search-order` | GET |
| End of Date Status | `/api/pos/end-of-date` | GET |
| Make End of Date | `/api/pos/make-end-of-date` | POST |
| Daily Summary (Admin) | `/api/admin/reports/daily-summary` | GET |

---

**Last Updated**: 2025-01-XX

