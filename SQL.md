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

---

### Q6.Among churned customers, how often did their orders fail at the delivery stage?
 
```sql
WITH churn AS (SELECT DISTINCT c.customer_id, c.customer_name,COUNT(*) as total_orders
FROM orders AS o
LEFT JOIN customers AS c ON o.customer_id = c.customer_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
AND o.customer_id NOT IN (
SELECT customer_id FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024)
group by c.customer_id
)
select c.customer_id,c.customer_name,c.total_orders,
SUM(CASE WHEN d.delivery_status='Not Delivered' THEN 1 ELSE 0 END) as notdelivered_orders,
ROUND(SUM(CASE WHEN  d.delivery_status='Not Delivered' THEN 1 ELSE 0 END)100/COUNT(),2) as delivery_failure_rate
FROM orders AS o
JOIN churn AS c ON o.customer_id = c.customer_id
LEFT JOIN deliveries AS d ON o.order_id = d.order_id
group by c.customer_id,c.customer_name
```
 
**Result:**

<img width="627" height="231" alt="image" src="https://github.com/user-attachments/assets/40cc33c2-8a40-48cb-a164-c3117816c93b" />





**Explanation:**

Failure rates vary widely — Rohan Iyer had the worst experience at 16.32% (31 of 190 orders), while Ashish Mishra and Megha Sinha had zero failures but also very few orders (2 and 1). Most others (Aman Gupta, Karan Kapoor, Kavita Malhotra) sit between 6–8%, notably higher than the 8.17% average, suggesting delivery issues may have contributed to their churn.

---

### Q7. Customer Segmentation — Gold vs Silver based on total spend vs. average customer spend
 
```sql
WITH customer_spend AS (
    SELECT customer_id,
           SUM(total_amount) AS total_spent,
           COUNT(order_id) AS total_orders
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT customer_id,
       total_spent,
       total_orders,
       CASE 
           WHEN total_spent > (SELECT AVG(total_spent) FROM customer_spend) THEN 'Gold'
           ELSE 'Silver'
       END AS cx_category
FROM customer_spend
ORDER BY total_spent DESC;
```
 
**Result:**

<img width="402" height="351" alt="image" src="https://github.com/user-attachments/assets/8898c311-f6ff-44bd-a8d5-1e7927399b53" />





**Explanation:**

Customers 17, 22, 19, 20, 18, 16, and 21 are Gold, each spending ₹1.38L–₹1.6L across 450+ orders. Silver customers (1, 12, 10, 3, 11, 2, 13, 14) spend roughly ₹52K–₹63K with about half as many orders. The split is now clean and proportional — Gold customers have both higher spend and more orders, confirming this segmentation is genuinely separating high-value from low-value customers, unlike the earlier flawed version.

---

### Q8. Popular Time Slots — during which 2-hour windows are most orders placed?
 
```sql
SELECT
CASE
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
END AS time_slot,
COUNT(order_id) AS order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;
```
 
**Result:**

<img width="226" height="246" alt="image" src="https://github.com/user-attachments/assets/3202a9d3-6851-4d40-90a2-2397118c86ed" />





**Explanation:**

Order volume is remarkably even across the day — every slot from 6 AM to midnight holds roughly 1,000–1,190 orders, with 14:00–16:00 slightly ahead at 1,188. The 00:00–02:00 slot is the only outlier, with just 12 orders — showing demand is steady all day but drops off almost completely late at night.

---

### Q9. Monthly Sales Trend — comparing each month to the previous one
 
```sql
SELECT
EXTRACT(YEAR FROM order_date) as year,
EXTRACT(MONTH FROM order_date) as month,
SUM(total_amount) as total_sale,
LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) as prev_month_sale,
ROUND((SUM(total_amount)
-LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)))*100/
LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)),2) as growth_pct
FROM orders
GROUP BY year,month
```
 
**Result:**

<img width="440" height="301" alt="image" src="https://github.com/user-attachments/assets/0faaa6c4-1f1f-4a0a-839b-06ec482d9374" />





**Explanation:**

2023 shows healthy month-to-month fluctuation, swinging between roughly -16% and +23% with no clear long-term decline. January 2024 shows a dramatic -97.10% drop (₹7,944 vs ₹2.7L+ in December) — this is almost certainly the dataset simply ending mid-January 2024 rather than a real business collapse, worth calling out as a data-boundary artifact, not a genuine trend.

---

### Q10. What is the most frequently ordered dish in each city?
 
```sql
WITH best_item as (select r.city,o.order_item,COUNT() as total_order,
RANK() OVER(PARTITION BY r.city order by COUNT() DESC) as ranking
from orders as o
LEFT JOIN restaurants as r on o.restaurant_id=r.restaurant_id
GROUP BY  o.order_item,r.city)
SELECT * FROM best_item where ranking = 1 or ranking =2 ORDER BY  ranking
```
 
**Result:**

<img width="425" height="245" alt="image" src="https://github.com/user-attachments/assets/1a9a8aea-d25e-4d21-b0a1-fa4f72952e16" />





**Explanation:**

Mumbai has by far the highest single-dish volume — Paneer Butter Masala at 363 orders — more than double any other city's top dish. Chicken Biryani and Paneer Butter Masala dominate across most cities, appearing as either the #1 or #2 dish in 4 of 5 cities.

---

### Q11. Which dishes see spikes in demand during certain months or seasons, and are there items with consistent year-round demand versus seasonal ones?
 
```sql
SELECT * FROM
(SELECT
order_item,
seasons,
COUNT(order_id) as total_orders,
RANK() OVER(PARTITION BY seasons order by COUNT(order_id) DESC) as ranking
FROM
(
SELECT *,
EXTRACT(MONTH FROM order_date) as month,
CASE
WHEN EXTRACT(MONTH FROM order_date) BETWEEN 8 AND 10 THEN 'Spring'
WHEN EXTRACT(MONTH FROM order_date) > 2 AND
EXTRACT(MONTH FROM order_date) < 8 THEN 'Summer'
ELSE 'Winter'
END as seasons
FROM orders where order_status='Completed') as t
group by order_item,seasons) as q
where ranking =1 or ranking=2 order by seasons
```
 
**Result:**

<img width="402" height="180" alt="image" src="https://github.com/user-attachments/assets/49f394cd-d533-4176-8313-4adbc80c8b1e" />





**Explanation:**

Paneer Butter Masala peaks hardest in summer (323 orders), while Chicken Biryani stays a strong #2 across Spring, Summer, and Winter alike — showing it's a consistent year-round favorite rather than a seasonal spike item. Masala Dosa leads only in Spring, suggesting a more seasonal demand pattern.

---

### Q12. What are peak order days (day of week)?
 
```sql
SELECT DAYNAME(order_date) as dayname,
COUNT(order_id) as total_order,
DENSE_RANK() OVER(ORDER BY COUNT(order_id))  as ranking
FROM orders GROUP BY dayname
```
 
**Result:**

<img width="277" height="182" alt="image" src="https://github.com/user-attachments/assets/00925344-1d45-4578-be52-0b1611367717" />





**Explanation:**

Sunday is the clear peak day (1,491 orders), followed by Wednesday and Friday. Order volume stays fairly tight across the week overall (1,391–1,491), with weekends and mid-week showing only a modest edge over other days.

---

### Q13. Find the average order value per customer who has placed more than 30 orders?
 
```sql
SELECT
o.customer_id,
c.customer_name,
ROUND(AVG(o.total_amount),2) as aov,
RANK() OVER(ORDER BY ROUND(AVG(o.total_amount) ,2) DESC) as ranking
FROM orders as o
JOIN customers as c
ON c.customer_id = o.customer_id
GROUP BY o.customer_id
HAVING  COUNT(order_id) > 30
LIMIT 5;
```
 
**Result:**

<img width="371" height="137" alt="image" src="https://github.com/user-attachments/assets/4c5a8912-32ba-4300-a513-69613811beea" />






**Explanation:**

Rahul Verma has the highest AOV (₹338.36) among high-frequency customers, followed closely by Ritu Patel, Aman Gupta, Sneha Desai, and Neha Joshi — all within a tight ₹331–₹338 range, showing consistent spending behavior among the platform's most loyal/frequent customers.

---

### Q14. Rank each city based on the total revenue ?
 
```sql
SELECT
r.city,
SUM(total_amount) as total_revenue,
RANK() OVER(ORDER BY SUM(total_amount) DESC) as city_rank
FROM orders as o
JOIN
restaurants as r
ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
```
 
**Result:**

<img width="301" height="136" alt="image" src="https://github.com/user-attachments/assets/ae51a424-8292-4261-b9d0-3726d309823f" />






**Explanation:**

Mumbai dominates with ₹15.2L in revenue — more than double Bengaluru (₹7.2L), the next closest city. Delhi, Hyderabad, and Chennai trail far behind at ₹3L–₹3.7L each, confirming Mumbai as the platform's core market by a wide margin.

---

### Q15.List the customers who have spent more than 10K in total on food orders?
 
```sql
SELECT
o.customer_id,
c.customer_name,
SUM(o.total_amount) as total_spent
FROM orders as o
JOIN customers as c
ON c.customer_id = o.customer_id
GROUP BY o.customer_id
HAVING SUM(o.total_amount) > 10000
```
 
**Result:**

<img width="322" height="175" alt="image" src="https://github.com/user-attachments/assets/49e42da2-28b7-45e6-9f10-678bdb388838" />






**Explanation:**

7 customers cross the ₹10K mark, led by Nikhil Jain at ₹1,67,844 — nearly 3x higher than the next closest customer (Arjun Mehta, ₹65,044). The rest (Sameer Khan, Priya Sharma, Vikram Singh, Anjali Saxena, Divya Nair) cluster more tightly between ₹55K–₹65K, making Nikhil Jain a clear standout high-value customer.

---

## ✅ Conclusion
 
1. **Fulfillment and delivery are two separate failure points** — 2.5% of orders never leave the restaurant, and a further 8.17% of fulfilled orders fail during delivery — meaning restaurant reliability and delivery execution need to be tracked and improved independently.
2. **Mumbai drives the business** — generating over 2x the revenue of the next-closest city, making it the platform's most critical market to protect and invest in.
3. **Demand is stable, not spiky** — orders are spread evenly across days and time slots, so operational planning should focus on consistent capacity rather than peak-hour surges.
4. **A small customer segment holds outsized value** — a handful of top spenders and "Gold" customers contribute disproportionately to revenue, making retention of this group a high-priority lever.
5. **Churn correlates with poor delivery experience** — customers who stopped ordering after 2023 had above-average delivery failure rates, suggesting delivery quality (not just pricing) is a real churn driver worth addressing.

**Overall:** This project says: the platform's core operations — restaurant fulfillment, delivery execution, and demand — run smoothly and consistently at scale, with no major systemic breakdown. The real value of this analysis isn't "everything is broken," it's that it pinpoints specific, fixable levers: a short list of underperforming riders and restaurants, a small but identifiable set of churned customers linked to delivery quality, and a heavy revenue concentration in Mumbai that's either a strength to double down on or a risk to diversify against. 




```

