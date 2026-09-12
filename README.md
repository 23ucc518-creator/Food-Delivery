# 🚴 Food Delivery Analytics — SQL + GenAI Case Study

## 📌 Overview

This project analyzes a food delivery platform's order and delivery pipeline using SQL, uncovering how orders move from **restaurant fulfillment → rider delivery**, where failures occur, and which customers, restaurants, and riders drive the business. It goes beyond static analysis by adding a natural-language-to-SQL layer (via n8n + Gemini) that lets anyone query the database in plain English, and a Power BI dashboard for visualization.

The dataset consists of 5 relational tables — `orders`, `deliveries`, `customers`, `restaurants`, and `riders` — modeled and queried entirely in MySQL Workbench.

## ✨ Project Highlights

- Modeled a 5-table relational schema in MySQL with correct foreign key ordering and data-type decisions validated against real sample data.
- Identified and resolved a real-world data quality issue — a mislabeled third `delivery_status` value — by testing hypotheses against the data instead of assuming.
- Discovered that `order_status` and `delivery_status` represent two independent pipeline stages, confirmed via a `LEFT JOIN` diagnostic, turning one ambiguous metric into a clean two-stage funnel.
- Answered 15 business questions using JOINs, subqueries, CTEs, and window functions (`RANK()`, `DENSE_RANK()`, `LAG()`).
- Built a working **NL-to-SQL agent in n8n** (Gemini + MySQL tool) that independently reproduces the same results as the hand-written SQL, verified query-by-query.

## 🛠️ Tools Used

- **MySQL Workbench** — schema design, data cleaning, and SQL analysis
- **SQL** — JOINs, subqueries, CTEs, window functions (`RANK`, `DENSE_RANK`, `LAG`), conditional aggregation
- **n8n** — workflow automation for the natural-language-to-SQL agent
- **Google Gemini** — LLM powering the NL-to-SQL AI Agent
- **Power BI** *(planned)* — dashboard visualization layer


## 🔑 Key Highlights (Findings)

1. **Fulfillment and delivery are two separate failure points** — restaurant reliability and delivery execution need to be tracked and improved independently.
2. **Mumbai drives the business** — generating over 2x the revenue of the next-closest city, making it the platform's most critical market to protect and invest in.
3. **Demand is stable, not spiky** — operational planning should focus on consistent capacity rather than peak-hour surges.
4. **A small customer segment holds outsized value** — a handful of top spenders and "Gold" customers contribute disproportionately to revenue, making retention a high-priority lever.
5. **Churn correlates with poor delivery experience** — delivery quality, not just pricing, appears to be a real churn driver.

## 📚 What I Learned

Through this project, I didn't just write SQL queries — I learned how to think like a data analyst. Here's what I practiced:
 
📌 Database Design – structured tables with real-world relationships
🔍 Data Filtering & Retrieval – queries across thousands of rows
📊 Aggregation & Grouping – SUM, COUNT, AVG for key metrics
🔗 Joins – connected multiple tables for complete answers
🪟 Window Functions – RANK, DENSE_RANK, LAG for rankings and trends
⏰ Date & Time Functions – found demand patterns over days and months
🔀 Conditional Logic – CASE WHEN for rates and segmentation
🧠 Subqueries & CTEs – multi-step logic for churn and segmentation
🤖 GenAI Integration – n8n + Gemini agent for natural language to SQL
 
This project also helped me visualize insights using Power BI, making the data easier to understand for non-technical people.



## 🎯 Conclusion

This project helped me put my SQL knowledge into practice by building a database from scratch and solving real-world business problems in the context of a food delivery company. I learned how to set up and manage tables, clean and validate data, and write queries to answer business questions like identifying top customers, delivery performance, and where failures occur in the order pipeline.
 
I also went a step further by building a natural-language-to-SQL agent in n8n, which let me query the same database in plain English and verify that an AI agent could independently reproduce my hand-written SQL results. With the planned addition of **Power BI**, I aim to translate these raw SQL insights into visual stories — making the data easier to interpret for non-technical stakeholders. This project strengthened both my SQL and data-cleaning skills, and my ability to think like a data-driven decision-maker.


## ⚠️ Disclaimer
 
This project is purely academic and was created for learning and portfolio purposes. All data used is **fictional and randomly generated** — it does not reflect any real individuals, restaurants, riders, or companies. It is **not associated with Zomato, Swiggy, or any real food delivery platform**. Any resemblance to real businesses or individuals is completely coincidental.

---
