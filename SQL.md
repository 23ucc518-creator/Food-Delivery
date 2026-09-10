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

---

### Q1. Of all orders successfully fulfilled by the restaurant, what percentage were delivered vs. failed during delivery?
 
```sql
SELECT COUNT(*) AS total_orders,
ROUND(SUM(CASE WHEN delivery_status='Delivered' THEN 1 ELSE 0 END)*100/
      SUM(CASE WHEN order_status='Completed' THEN 1 ELSE 0 END),2) AS delivery_success_rate,
ROUND(SUM(CASE WHEN delivery_status='Not Delivered' THEN 1 ELSE 0 END)*100/
      SUM(CASE WHEN order_status='Completed' THEN 1 ELSE 0 END),2) AS delivery_failure_rate
FROM orders AS o LEFT JOIN deliveries AS d ON o.order_id=d.order_id;
```
 
**Result:**

<img width="491" height="61" alt="image" src="https://github.com/user-attachments/assets/71a1e9e8-d686-42bb-b351-1dc685a51ea6" />



**Explanation:**

250 orders never reached delivery — the restaurant never fulfilled them. Of the remaining 9,676 handed off to a rider, 91.83% delivered successfully and 8.17% failed in transit. Isolating the rate to fulfilled orders keeps this a clean delivery-team metric, separate from restaurant-side no-shows.

---

### Q2. Which riders have the highest failure/non-delivery rate?
 
```sql
SELECT rider_id,COUNT(*) as total_deliveries,
SUM(CASE WHEN delivery_status = 'Not Delivered' THEN 1 ELSE 0 END) as not_deliveredcount,
ROUND(SUM(CASE WHEN delivery_status = 'Not Delivered' THEN 1 ELSE 0 END)100/COUNT(),2) as failure_rate
FROM deliveries
GROUP BY rider_id order by failure_rate DESC LIMIT 5
```
 
**Result:**

<img width="448" height="142" alt="image" src="https://github.com/user-attachments/assets/4aa42e0c-f011-4604-978a-e7ee16dc3ba3" />




**Explanation:**

Riders 8, 6, 7, 5, and 13 have the highest failure rates (8.83%–10.96%), all above the 8.17% platform average. Rider 13 has the lowest rate of the five but handles nearly double the deliveries, so their total failed count (69) is still the highest.

---

### Q3. Which restaurants have the highest 'Not Fulfilled' order rate?
 
```sql
SELECT r.restaurant_name,
COUNT() AS total_orders,
SUM(CASE WHEN o.order_status = 'Not Fulfilled' THEN 1 ELSE 0 END) AS not_fulfilled_count,
ROUND(SUM(CASE WHEN o.order_status = 'Not Fulfilled' THEN 1 ELSE 0 END) * 100.0 / COUNT(), 2) AS not_fulfilled_pct
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY not_fulfilled_pct DESC LIMIT 5;
```
 
**Result:**

<img width="532" height="147" alt="image" src="https://github.com/user-attachments/assets/7181f19f-7aeb-45ce-99e6-fe7a79da11a1" />




**Explanation:**

Perch Wine & Coffee Bar tops the list at 6.56%, followed by Bukhara, Nagarjuna, Truffles, and Punjabi By Nature. All five sit well above the platform-wide 2.5% rate.

---

### Q4. Which restaurants contribute the most order value (GMV) to the platform, by city?”(Gross Merchandise Value) — total value of completed transactions flowing through the platform:
 
```sql
WITH resto as (select o.restaurant_id,r.restaurant_name,r.city,
SUM(o.total_amount) as revenue,
RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) as ranking
from orders as o LEFT JOIN restaurants as r on o.restaurant_id=r.restaurant_id
WHERE o.order_status = 'Completed'
GROUP BY o.restaurant_id, r.city)

SELECT restaurant_id,restaurant_name,city,revenue FROM resto
WHERE ranking=1 OR ranking=2
ORDER BY city DESC, ranking ASC;
```
 
**Result:**

<img width="467" height="245" alt="image" src="https://github.com/user-attachments/assets/6f1ef489-ec04-4cf8-bd4c-2ef1ff01ca5a" />




**Explanation:**

Gajalee and Bademiya lead Mumbai with roughly ₹1.5L each, far ahead of the top performers in any other city. Other cities' leaders generate only ₹25K–₹55K, showing Mumbai dominates GMV.

---

### Q5. Who are the customers that churned between 2023 and 2024, based on having ordered in 2023 with no activity since?
 
```sql
SELECT DISTINCT c.customer_id, c.customer_name
FROM orders AS o
JOIN customers AS c ON o.customer_id = c.customer_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
AND o.customer_id NOT IN (
SELECT customer_id FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024
);
```
 
**Result:**

<img width="253" height="228" alt="image" src="https://github.com/user-attachments/assets/c34d54b2-8ac6-42cf-bc61-d344d1aa436f" />




**Explanation:**

9 customers, including Aman Gupta, Sneha Desai, and Karan Kapoor, ordered in 2023 but placed none in 2024. These are clear churn candidates for re-engagement.





```
