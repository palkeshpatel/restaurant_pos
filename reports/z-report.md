# Z-Report (Daily Report)

**Endpoint:** `GET /api/pos/reports/z-report`

**Purpose:** End-of-day summary report. Shows complete daily totals and is typically printed at closing time.

## Query Parameters

- `date` (optional): Date for the report in `YYYY-MM-DD` format. Defaults to today if not provided.
- `employee_id` (optional): Filter by specific employee/server ID. If not provided, shows all employees.
- `format` (optional): Response format - `json` (default), `text`, or `pdf`

## Report Sections

### 1. Sales Summary
Same structure as X-Report (Closed Orders, Open Orders, Total Sales)

See [X-Report Documentation](./x-report.md) for detailed field definitions.

### 2. Payments
Same structure as X-Report

See [X-Report Documentation](./x-report.md) for detailed field definitions.

### 3. Cash Out

- **Credit Tips**: Tips from card/online payments
  - **Source**: `PaymentHistory::where('payment_mode', '!=', 'cash')->where('status', 'completed')->sum('tip_amount')`

- **Service Charge**: Total service charge for the day
  - **Source**: Calculated from all orders (same as X-Report)
  - **Calculation**: See X-Report Service Charge calculation

- **Cash On Hand**: Total cash payments
  - **Source**: `PaymentHistory::where('payment_mode', 'cash')->where('status', 'completed')->sum('amount')`

### 4. Total Owed to Restaurant

- **Calculation**: `Cash On Hand - (Credit Tips + Service Charge)`
- **Meaning**: Amount that should remain in the cash drawer after paying out tips and service charge
- **Purpose**: Helps determine how much cash should be left in the drawer at end of day

### 5. Total Tips

- **Calculation**: `Cash Tips + Credit Tips`
- **Source**: 
  - Cash Tips: `PaymentHistory::where('payment_mode', 'cash')->where('status', 'completed')->sum('tip_amount')`
  - Credit Tips: `PaymentHistory::where('payment_mode', '!=', 'cash')->where('status', 'completed')->sum('tip_amount')`

### 6. Suggested Tip Out

Breakdown by role (Bar, Busser, Runner, Bar Back):

- **Role**: Employee role name
- **Percentage**: Tip out percentage (e.g., 10% for Bar, 3% for Busser)
  - **Default Percentages**:
    - Bar: 10%
    - Busser: 3%
    - Runner: 3%
    - Bar Back: 3%
- **Base Amount**: Net sales from closed orders
  - **Source**: `$salesSummary['closed_orders']['net_sales']`
- **Tip Out**: Calculated tip out amount
  - **Calculation**: `(Base Amount * Percentage) / 100`
  - **Example**: If net sales = $1000, Bar (10%) = $100

### 7. Server Sales & Tips
Same as X-Report

See [X-Report Documentation](./x-report.md) for detailed field definitions.

### 8. Report Number

- **Format**: `YEAR-DAYOFYEAR` (e.g., 2025-307)
- **Calculation**: 
  - Year: `Carbon::parse($reportDate)->format('Y')`
  - Day of Year: `Carbon::parse($reportDate)->format('z') + 1` (0-based, so add 1)
- **Purpose**: Unique identifier for each daily Z-Report

## Response Format

The report can be returned in three formats:

1. **JSON** (default): Full data structure with all calculations
2. **Text**: Plain text thermal format (32-character width) for direct printing
3. **PDF**: PDF document (currently returns text format)

## Example Request

```bash
GET /api/pos/reports/z-report?date=2025-11-03&employee_id=1&format=json
```

## Notes

- Z-Report is typically printed once per day at closing time
- All calculations are based on completed orders for the specified date
- Items with `order_status = 3` (voided) are excluded from all calculations
- Only payments with `status = 'completed'` are included
- Report filters by `business_id` from authenticated employee
- Optional `employee_id` parameter filters by `created_by_employee_id`

## Differences from X-Report

1. **Cash Out Section**: Shows breakdown of what needs to be paid out
2. **Total Owed to Restaurant**: Calculates remaining cash after payouts
3. **Total Tips**: Combined cash and credit tips
4. **Suggested Tip Out**: Calculates tip distribution by role
5. **Report Number**: Unique identifier for each daily report

