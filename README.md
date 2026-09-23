# 🚴 Food Delivery Analytics-(OrderIT)

## 📌 Overview

This project analyzes a food delivery platform's order and delivery pipeline using SQL, uncovering how orders move from **restaurant fulfillment → rider delivery**, where failures occur, and which customers, restaurants, and riders drive the business. It goes beyond static analysis by adding a natural-language-to-SQL layer (via n8n + Gemini) that lets anyone query the database in plain English, and a Power BI dashboard for visualization.

The dataset consists of 5 relational tables — `orders`, `deliveries`, `customers`, `restaurants`, and `riders` — modeled and queried entirely in MySQL Workbench.

## 🎯 Problem Statement
 
Food delivery platforms lose revenue in ways that aren't always obvious from a single "orders failed" number — orders can fail for different reasons, at different stages, caused by different parties (the restaurant vs. the rider vs. the customer). Without separating these, a business can't tell which team to fix, which restaurants to review, or which customers are quietly churning.
 
**Core problem this project solves:** Where exactly in the order lifecycle is the platform losing orders and customers, and who (restaurant, rider, or neither) is responsible at each stage?
 
**Approach:**
1. **Model the pipeline correctly** — build a relational schema that captures the full order journey from placement → restaurant fulfillment → rider delivery.
2. **Validate the data before trusting it** — an inconsistent status value was found and investigated with evidence rather than assumed away, and two status fields were confirmed to represent genuinely separate pipeline stages before being used in any metric.
3. **Split blended metrics into attributable ones** — separating "restaurant fulfillment rate" from "delivery success rate" so failures can be traced to the right team instead of one vague number.
4. **Answer targeted business questions** — revenue drivers, underperforming riders/restaurants, customer segmentation, and churn — using the validated funnel as the foundation.
5. **Make the analysis accessible** — a natural-language-to-SQL agent (n8n + Gemini) and a Power BI dashboard so non-technical stakeholders can query and view these findings without writing SQL.

## ✨ Project Highlights

- ✅ Modeled a 5-table relational schema in MySQL with correct foreign key ordering and validated data types.
- ✅ Identified and resolved a real data quality issue — a mislabeled third `delivery_status` value — by testing hypotheses, not assuming.
- ✅ Discovered `order_status` and `delivery_status` are two independent pipeline stages, confirmed via a `LEFT JOIN` diagnostic.
- ✅ Answered 15 business questions using JOINs, subqueries, CTEs, and window functions (`RANK`, `DENSE_RANK`, `LAG`).
- ✅ Built a working **NL-to-SQL agent in n8n** (Gemini + MySQL tool), verified query-by-query against hand-written SQL.
- ✅ Secured the NL-to-SQL agent with a read-only database user — tested by asking it to delete data, confirming destructive queries are rejected even if the AI generates them.

## 🛠️ Tools Used

- **MySQL Workbench** — schema design, data cleaning, and SQL analysis
- **SQL** — JOINs, subqueries, CTEs, window functions (`RANK`, `DENSE_RANK`, `LAG`), conditional aggregation
- **n8n** — workflow automation for the natural-language-to-SQL agent
- **Google Gemini** — LLM powering the NL-to-SQL AI Agent
- **Power BI** — dashboard visualization layer


## 🔑 Key Highlights (Findings)

1. **Fulfillment and delivery are two separate failure points** — restaurant reliability and delivery execution need to be tracked and improved independently.
2. **Mumbai drives the business** — generating over 2x the revenue of the next-closest city, making it the platform's most critical market to protect and invest in.
3. **Demand is stable, not spiky** — operational planning should focus on consistent capacity rather than peak-hour surges.
4. **A small customer segment holds outsized value** — a handful of top spenders and "Gold" customers contribute disproportionately to revenue, making retention a high-priority lever.
5. **Churn correlates with poor delivery experience** — delivery quality, not just pricing, appears to be a real churn driver.

## 📊 Dashboard Preview
<img width="1411" height="793" alt="image" src="https://github.com/user-attachments/assets/95662d0a-6a79-4cea-a74d-8e2f5df2f6e2" />


## 📂 Project Files

- [`table_creation.md`](./ddl_table_creation.sql) — Table creation queries
- [`SQL.md`](./SQL.md) — All 15 business questions with queries, results, and explanations
- [`N8N.md`](./N8N_readme.md) — Natural-language-to-SQL agent (n8n + Gemini), with example queries and results
- [`NL to SQL.json`](./NL%20to%20SQL.json) — Exported n8n workflow, importable directly into n8n

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


## 👤 Author
Arjav Jain

---
