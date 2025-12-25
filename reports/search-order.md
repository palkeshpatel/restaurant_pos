# Search Order Report

**Endpoint:** `GET /api/pos/search-order?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`

**Purpose:** Search and retrieve orders by date range. Returns list of orders with billing summaries.

## Query Parameters

- **start_date** (optional): Start date (YYYY-MM-DD). If only this is provided, returns single day. Default: today
- **end_date** (optional): End date (YYYY-MM-DD). If provided, returns date range. Default: same as start_date
- **status** (optional): Filter by status (`open`, `completed`, `hold`, `cancelled`)
- **order_ticket_id** (optional): Search by order ticket ID
- **table_id** (optional): Filter by table ID
- **employee_id** (optional): Filter by employee ID
- **search** (optional): Search in order_ticket_id, order_ticket_title, or table name
- **per_page** (optional): Pagination limit (default: 50, max: 100)
- **page** (optional): Page number (default: 1)
- **pdf** (optional): If `true`, returns PDF document with billing summary for completed orders. Default: `false`

## Response Fields

For each order in the response:

- **id**: Order ID
  - **Source**: `orders.id`

- **order_ticket_id**: Unique order identifier
  - **Source**: `orders.order_ticket_id`

- **order_ticket_title**: Short order identifier
  - **Source**: `orders.order_ticket_title`

- **status**: Order status
  - **Source**: `orders.status`

- **customer**: Number of guests
  - **Source**: `orders.customer`

- **created_at**: Order creation date
  - **Source**: `orders.created_at`

- **table**: Table information
  - **id**: Table ID
  - **name**: Table name
  - **Source**: `restaurant_tables` via `orders.table_id`

- **created_by_employee**: Employee information
  - **id**: Employee ID
  - **first_name**: Employee first name
  - **last_name**: Employee last name
  - **Source**: `employees` via `orders.created_by_employee_id`

- **billing_summary**: Same structure as Bill Preview Report
  - **subtotal**: Sum of item prices + modifiers
    - **Calculation**: See [Bill Preview Documentation](./bill-preview.md)
  - **total_discount**: Sum of discounts
    - **Source**: Sum of `order_items.discount_amount`
  - **tax_amount**: Tax value
    - **Source**: `orders.tax_value`
  - **gratuity_amount**: Service charge
    - **Calculation**: See [X-Report Documentation](./x-report.md)
  - **fee_amount**: Fees
    - **Source**: `orders.fee_value`
  - **tip_amount**: Tips
    - **Source**: Sum of `payment_histories.tip_amount` where `status = 'completed'`
  - **total_bill**: Total amount
    - **Calculation**: `subtotal - total_discount + tax_amount + gratuity_amount + fee_amount + tip_amount`
  - **paid_amount**: Amount paid
    - **Source**: Sum of `payment_histories.amount` where `status = 'completed'`
  - **remaining_amount**: Amount remaining
    - **Calculation**: `total_bill - paid_amount`

- **thermal_format**: Formatted text for thermal printer (32-character width)
  - **Note**: Only included for completed orders

- **thermal_format_html**: HTML formatted version
  - **Note**: Only included for completed orders

## Pagination

If `per_page` or `page` is provided, response includes pagination info:

```json
{
  "success": true,
  "data": {
    "orders": [...],
    "total": 150,
    "pagination": {
      "current_page": 1,
      "per_page": 50,
      "total": 150,
      "last_page": 3,
      "from": 1,
      "to": 50
    }
  }
}
```

## Calculation Logic

Same as Bill Preview Report for each order's billing summary.

See [Bill Preview Documentation](./bill-preview.md) for detailed calculation explanations.

## Example Requests

### Single Day
```bash
GET /api/pos/search-order?start_date=2025-11-05
```

### Date Range
```bash
GET /api/pos/search-order?start_date=2025-11-01&end_date=2025-11-05
```

### With Filters
```bash
GET /api/pos/search-order?start_date=2025-11-05&status=completed&employee_id=1&per_page=20&page=1
```

### Search by Text
```bash
GET /api/pos/search-order?start_date=2025-11-05&search=ORD-20251105
```

### Get PDF
```bash
GET /api/pos/search-order?start_date=2025-11-05&end_date=2025-11-05&pdf=true
```

## Example Response Structure

```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": 1,
        "order_ticket_id": "ORD-20251105-ABC123",
        "order_ticket_title": "20251105-01T1",
        "status": "completed",
        "customer": 2,
        "created_at": "2025-11-05 14:30:00",
        "table": {
          "id": 1,
          "name": "T1"
        },
        "created_by_employee": {
          "id": 1,
          "first_name": "John",
          "last_name": "Doe"
        },
        "billing_summary": {
          "subtotal": "1000.00",
          "total_discount": "50.00",
          "tax_amount": "95.00",
          "gratuity_amount": "100.00",
          "fee_amount": "5.50",
          "tip_amount": "20.00",
          "total_bill": "1270.50",
          "paid_amount": "1270.50",
          "remaining_amount": "0.00"
        },
        "thermal_format": "...",
        "thermal_format_html": "..."
      }
    ],
    "total": 1
  }
}
```

## Notes

- Default behavior: If no dates provided, returns today's orders
- If only `start_date` is provided, returns single day (start_date = end_date)
- Voided items (`order_status = 3`) are excluded from calculations
- Only completed payments (`status = 'completed'`) are included in billing summary
- Search parameter searches in: `order_ticket_id`, `order_ticket_title`, and table `name`
- PDF format includes billing summary for all completed orders in the date range
- Report filters by `business_id` from authenticated employee
- All date filtering uses `orders.created_at` field

