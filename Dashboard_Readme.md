# 📊 Power BI Dashboard — Food Delivery Analytics(Order Karo)

This dashboard visualizes the food delivery platform's order, delivery, restaurant, and rider data across two pages: **Business Overview** and **Delivery Operations & Performance**. It sits on top of the same `orders`, `deliveries`, `restaurants`, `customers`, and `riders` tables used for the SQL analysis in this repo.

---

## 🧭 Pages

### 1. Business Overview

High-level KPIs and a parameter-driven trend/breakdown view for Revenue, Orders, Order Failure Rate, Average Order Value, and Fulfilled Orders.

**KPI Cards**

| Metric | Description |
|---|---|
| Total Revenue | Sum of `total_amount` for `Completed` orders |
| Orders | Total order count |
| Order Failure Rate | % of orders with `order_status = 'Not Fulfilled'` |
| Average Order Value | Total Revenue ÷ Fulfilled Orders |
| Fulfilled Orders | Count of orders with `order_status = 'Completed'` |

Each card shows a month-over-month % change (`▲`/`▼`) computed via `DATEADD` time intelligence.

**Parameter-driven visuals** (Field Parameter: `Total Revenue | Orders | Order Failure Rate | Avg Order Value | Fulfilled Orders`)
- Trend chart — selected metric over time
- Top 10 Restaurants — by selected metric
- By Delivery Area — selected metric broken down by city

Chart titles update dynamically based on the selected parameter (e.g. "Total Revenue / By Top 10 Restaurants").

**Screenshots:** `screenshots/overview_screenshots/`
- `Total_Revenue.png`
- `Orders.png`
- `Order_failure_rate.png`
- `Average_order_value.png`
- `Fulfilled_orders.png`

---

### 2. Delivery Operations & Performance

Focused on delivery-side performance — where orders are lost, how fast they're delivered, and how that varies by rider and city.

**KPI Cards**

| Metric | Description |
|---|---|
| Avg Fulfilment Time | Average delivery time (mins), corrected for midnight roll-over |
| Fast Delivery Rate | % of delivered orders completed in under 60 minutes |
| Total Restaurants | Distinct restaurant count, with orders-per-restaurant |

**Charts**
- **Orders by Delivery Time Band** — bucketed delivery duration (`<30`, `30-45`, `45-60`, `60-75`, `75-90`, `90-120`, `120+`)
- **Avg Fulfilment Time by City** — donut chart comparing average delivery time across cities
- **Order Volume by Hour and Day** — heatmap-style table showing demand patterns by hour × weekday
- **Failure Rate by Stage** — the platform's failure broken into its two distinct stages:
  - *Not Fulfilled (Restaurant)* — order never left the restaurant
  - *Not Delivered (Rider)* — order was fulfilled but delivery failed
  
  This chart is the core finding of the analysis: it separates restaurant-side failure from rider-side failure, which a single blended "failure rate" number would hide.

**Screenshots:** `screenshots/Operation_screenshots/`
- `Jan.png`, `Feb.png`, `Mar.png`, `Apr.png` — monthly views via the page's month filter
- `selectall.png` — full page, all months selected

---

## 🧮 Key DAX Measures

```dax
Total Revenue = 
CALCULATE(SUM('fooddelivery orders'[total_amount]), 'fooddelivery orders'[order_status] = "Completed")

Order Failure Rate = 
DIVIDE(
    CALCULATE(COUNTROWS('fooddelivery orders'), 'fooddelivery orders'[order_status] = "Not Fulfilled"),
    [Total Orders]
)

Delivery Failure Rate = 
DIVIDE(
    CALCULATE(COUNTROWS('fooddelivery deliveries'), 'fooddelivery deliveries'[delivery_status] = "Not Delivered"),
    COUNTROWS('fooddelivery deliveries')
)

Delivery Time Mins = 
VAR OrderSec = HOUR(RELATED('fooddelivery orders'[order_time]))*3600 
             + MINUTE(RELATED('fooddelivery orders'[order_time]))*60 
             + SECOND(RELATED('fooddelivery orders'[order_time]))
VAR DeliverySec = HOUR('fooddelivery deliveries'[delivery_time])*3600 
                + MINUTE('fooddelivery deliveries'[delivery_time])*60 
                + SECOND('fooddelivery deliveries'[delivery_time])
RETURN
    IF(DeliverySec < OrderSec, DeliverySec + 86400 - OrderSec, DeliverySec - OrderSec) / 60
```

---

## 💡 Design Notes

- **`order_status` vs `delivery_status` are two separate, sequential stages** — restaurant fulfilment and rider delivery — and every measure on this dashboard respects that distinction rather than treating "failure" as one blended metric.
- **Revenue is filtered to `Completed` orders only.** `total_amount` is populated even on `Not Fulfilled` rows (it reflects the requested order value, not money actually earned), so an unfiltered `SUM` would overstate restaurant and platform revenue.
- **KPI cards use a Field Parameter** so one set of visuals can serve five different metrics, rather than duplicating charts per metric.
- **Sidebar navigation** is a custom-built element (shapes + page-navigation buttons), not a native Power BI feature — copied across all report pages for a consistent multi-page app feel.

---

- [`Order_Karo_dashboard`](./Order_Karo_dashboard.pbix) — the Power BI file (open in Power BI Desktop to interact with filters)

