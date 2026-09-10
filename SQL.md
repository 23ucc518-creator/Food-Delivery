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


<img width="800" height="500" alt="image" src="https://github.com/user-attachments/assets/b8b65ad3-cc24-4e0e-a629-02b91778be20" />



## 🧹 Data Cleaning & Validation

Before analysis, two data quality checks were run on the `deliveries` table:

- **`delivery_status` contained an unexpected third value, `'Order'`**, alongside `Delivered` and `Not Delivered`. Investigation showed `'Order'` rows had `delivery_time = 00:00:00` (a placeholder, same as `Not Delivered`), had a `rider_id` assigned, and appeared across every rider in proportions consistent with their overall delivery volume — indicating inconsistent labeling of the same failure outcome rather than a genuine third state. These rows were consolidated into `Not Delivered`.
- **`order_status` and `delivery_status` were confirmed to represent two separate, sequential pipeline stages, not overlapping data.** A `LEFT JOIN` between `orders` and `deliveries` showed that all 250 orders with `order_status = 'Not Fulfilled'` had no corresponding row in `deliveries` at all — meaning a delivery is never attempted for an order the restaurant never fulfilled. This confirms a two-stage funnel: **restaurant fulfillment → delivery execution.**



## ❓ Business Questions Answered




```
