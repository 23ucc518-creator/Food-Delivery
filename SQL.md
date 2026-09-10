# 🚴 Food Delivery Analytics — SQL Case Study

The dataset was imported from CSV into MySQL Workbench, where the 5 tables below were formed for analysis.

## 🗂️ Table Structure

| Table Name | Description | Key Columns |
|---|---|---|
| `orders` | Fact table — one row per order, with item, timing, status, and amount details | `order_id` (PK), `customer_id` (FK), `restaurant_id` (FK), `order_item`, `order_date`, `order_time`, `order_status`, `total_amount` |
| `deliveries` | Fact table — one row per delivery attempt, linked to an order and a rider | `delivery_id` (PK), `order_id` (FK), `delivery_status`, `delivery_time`, `rider_id` (FK) |
| `customers` | Customer registration details | `customer_id` (PK), `customer_name`, `reg_date` |
| `restaurants` | Restaurant details | `restaurant_id` (PK), `restaurant_name`, `city`, `opening_hour` |
| `riders` | Rider signup details | `rider_id` (PK), `rider_name`, `sign_up` |

**Schema:** `orders` and `deliveries` are the two fact tables. `orders` links to `customers` and `restaurants` via foreign keys; `deliveries` links to `orders` and `riders`.

## 🖇️ ER Diagram

![ER Diagram](<img width="1247" height="867" alt="image" src="https://github.com/user-attachments/assets/9a944b7a-a9d7-4a60-9b75-a68b253c06dd" />
)

*(Add the ER diagram image to your repo and update the path above — e.g. `images/er_diagram.png`.)*

## 🧹 Data Cleaning & Validation

Before analysis, two data quality checks were run on the `deliveries` table:

- **`delivery_status` contained an unexpected third value, `'Order'`**, alongside `Delivered` and `Not Delivered`. Investigation showed `'Order'` rows had `delivery_time = 00:00:00` (a placeholder, same as `Not Delivered`), had a `rider_id` assigned, and appeared across every rider in proportions consistent with their overall delivery volume — indicating inconsistent labeling of the same failure outcome rather than a genuine third state. These rows were consolidated into `Not Delivered`.
- **`order_status` and `delivery_status` were confirmed to represent two separate, sequential pipeline stages, not overlapping data.** A `LEFT JOIN` between `orders` and `deliveries` showed that all 250 orders with `order_status = 'Not Fulfilled'` had no corresponding row in `deliveries` at all — meaning a delivery is never attempted for an order the restaurant never fulfilled. This confirms a two-stage funnel: **restaurant fulfillment → delivery execution.**

```
Total Orders (9,926)
   ├── Not Fulfilled (250, ~2.5%) — restaurant-side, order never handed off
   └── Completed (9,676, ~97.5%) — passed to delivery stage
          ├── Delivered (8,885, ~91.8% of completed)
          └── Not Delivered (791, ~8.2% of completed)
```

## ❓ Business Questions Answered




```
