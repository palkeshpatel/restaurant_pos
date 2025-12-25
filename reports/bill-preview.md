# Bill Preview Report

**Endpoint:** `GET /api/pos/order/bill-preview?order_ticket_id=ORD-XXX`

**Purpose:** Shows detailed billing breakdown for a specific order. Used to preview bill before payment.

## Query Parameters

- `order_ticket_id` (required): Unique order identifier (e.g., `ORD-20251103-U9VFRB`)
- `pdf` (optional): If `true`, returns PDF document. Default: `false` (returns JSON)

## Report Fields

### Order Information

- **Order Ticket ID**: Unique order identifier (e.g., `ORD-20251103-U9VFRB`)
  - **Source**: `orders.order_ticket_id`

- **Order Ticket Title**: Short order identifier (e.g., `20251103-01T1`)
  - **Source**: `orders.order_ticket_title`

- **Status**: Order status (`open` or `completed`)
  - **Source**: `orders.status`

- **Date**: Order creation date and time
  - **Source**: `orders.created_at`
  - **Format**: `Y-m-d H:i:s`

- **Table**: Table name
  - **Source**: `restaurant_tables.name` via `orders.table_id`

- **Server**: Employee who created the order
  - **Source**: `employees.first_name + last_name` via `orders.created_by_employee_id`

- **Guests**: Number of customers
  - **Source**: `orders.customer`

### Order Items

Each item shows:
- **Name**: Menu item name
  - **Source**: `menu_items.name` via `order_items.menu_item_id`

- **Qty**: Quantity ordered
  - **Source**: `order_items.qty`

- **Price**: Total price for this item
  - **Calculation**: `(unit_price * qty) + modifiers - discount_amount`
  - **Modifiers**: Sum of `modifier_order_item.price * modifier_order_item.qty`
  - **Example**: 
    ```
    Item: $10.00, Qty: 2, Modifier: $2.00, Discount: $1.00
    Price = (10.00 * 2) + 2.00 - 1.00 = $21.00
    ```

- **Unit Price**: Price per unit
  - **Source**: `order_items.unit_price`

### Billing Summary

- **Subtotal**: Total before discount (sum of all item prices including modifiers)
  - **Calculation**: 
    ```
    For each order item:
      itemTotal = (unit_price * qty) + modifiers
      subtotal += itemTotal
    ```
  - **Note**: Does NOT include discounts, taxes, fees, or tips

- **Total Discount**: Total discount amount applied
  - **Source**: Sum of `order_items.discount_amount` for all items
  - **Calculation**: `$item->discount_amount ?? 0` for all items

- **Tax Amount**: Tax calculated on food items
  - **Source**: `orders.tax_value`
  - **Note**: Tax is typically applied on `(subtotal - discount)`

- **Gratuity Amount**: Service charge/gratuity
  - **Calculation**: Same as X-Report (based on `gratuity_key`, `gratuity_type`, `gratuity_value`)
  - **Applied On**: `(subtotal - discount + tax)`
  - **See**: [X-Report Documentation](./x-report.md) for detailed gratuity calculation

- **Fee Amount**: Additional fees
  - **Source**: `orders.fee_value`
  - **Calculation**: Percentage from `fees` table applied to `(subtotal - discount)`

- **Tip Amount**: Tips from payment history
  - **Source**: Sum of `payment_histories.tip_amount` where `status = 'completed'` and `order_id = order.id`

- **Total Bill**: Final amount
  - **Calculation**: `Subtotal - Total Discount + Tax Amount + Gratuity Amount + Fee Amount + Tip Amount`
  - **Formula**: 
    ```
    total_bill = subtotal - total_discount + tax_amount + gratuity_amount + fee_amount + tip_amount
    ```

- **Paid Amount**: Total paid so far
  - **Source**: Sum of `payment_histories.amount` where `status = 'completed'` and `order_id = order.id`

- **Remaining Amount**: Amount still to pay
  - **Calculation**: `Total Bill - Paid Amount`
  - **Note**: Can be negative if overpaid

## Payment Method Information

The report also includes payment method text showing how payments were made:
- **Payment Method Text**: Comma-separated list of payment methods used
  - **Source**: `payment_histories.payment_mode` where `status = 'completed'`
  - **Examples**: "Cash Payment", "Card Payment", "Cash Payment + Card Payment"

## Response Format

The report can be returned in two formats:

1. **JSON** (default): Full data structure with:
   - Order information
   - Order items array
   - Billing summary
   - Thermal format (plain text)
   - Thermal format HTML (for browser display)

2. **PDF**: PDF document with formatted bill

## Example Request

```bash
GET /api/pos/order/bill-preview?order_ticket_id=ORD-20251103-U9VFRB&pdf=false
```

## Example Response Structure

```json
{
  "success": true,
  "data": {
    "order_ticket_id": "ORD-20251103-U9VFRB",
    "order_ticket_title": "20251103-01T1",
    "status": "open",
    "customer": 2,
    "created_at": "2024-11-03 14:30:00",
    "table": {
      "id": 1,
      "name": "T1"
    },
    "created_by_employee": {
      "id": 1,
      "first_name": "John",
      "last_name": "Doe"
    },
    "order_items": [
      {
        "name": "Grilled Chicken",
        "price": "25.50",
        "qty": 2,
        "unit_price": "12.75"
      }
    ],
    "billing_summary": {
      "subtotal": "1000.00",
      "total_discount": "50.00",
      "tax_amount": "95.00",
      "gratuity_amount": "100.00",
      "fee_amount": "5.50",
      "tip_amount": "0.00",
      "total_bill": "1250.50",
      "paid_amount": "600.00",
      "remaining_amount": "650.50"
    },
    "thermal_format": "...",
    "thermal_format_html": "..."
  }
}
```

## Notes

- Voided items (`order_status = 3`) are excluded from calculations
- Only completed payments (`status = 'completed'`) are included in paid amount
- The report can be generated for both open and completed orders
- Thermal format is optimized for 32-character wide thermal printers
- HTML format can be viewed in browser or embedded in iframe

