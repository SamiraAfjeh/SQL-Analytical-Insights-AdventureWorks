# 🛍️ Retail Analytics Case Study (SQL + Power BI)

## 📖 Overview
This project is a **retail analytics case study** designed for **portfolio presentation** and **data analytics interviews**.  
It demonstrates the **end-to-end analytics workflow** — from **SQL-based data extraction and transformation** to **Power BI dashboard visualization** — using the **AdventureWorksDW2022** sample database.

The analysis focuses on **sales**, **products**, **customers**, **territories**, and **employee** data to uncover meaningful retail insights.

---

## 🏗️ Project Architecture

```
/retail-analytics-case-study
│
├── /sql_queries
│ ├── 01_total_sales_by_year.sql
│ ├── 02_avg_shipping_time.sql
│ ├── 03_products_with_mountain.sql
│ ├── 04_unique_hire_dates.sql
│ └── ...
│
├── /powerbi_dashboard
│ └── retail_analytics_dashboard.pbix
│
└── README.md
```

---

## 🎯 Business Objectives
- Analyze **annual sales performance** and growth trends  
- Identify **peak order periods**  
- Evaluate **average shipping times** by territory  
- Determine **top-selling product categories**  
- Examine **employee hiring patterns**  
- Present **clean, actionable insights** through Power BI visuals  

---

## 🧠 SQL Analytics
All SQL scripts used in this project are available in the `/sql_queries` folder.  
Below is a summary of the key analytical queries:

### 1️⃣ Total Sales & Order Count by Year  
**File:** `01_total_sales_by_year.sql`  
- Filters orders by year  
- Computes total revenue and order count  
- Demonstrates parameterized SQL query techniques  

### 2️⃣ Average Shipping Time by Territory  
**File:** `02_avg_shipping_time.sql`  
- Uses **CTE** for cleaner logic and modularity  
- Calculates **average days between order and shipment**  
- Returns only **territories with above-average shipping time**

### 3️⃣ Products Containing “Mountain”  
**File:** `03_products_with_mountain.sql`  
- Demonstrates pattern-based text filtering using the `LIKE` operator  

### 4️⃣ Unique Employee Hire Dates  
**File:** `04_unique_hire_dates.sql`  
- Groups employee data by hire date  
- Removes duplicates using `GROUP BY` and `DISTINCT`

---

## 📊 Power BI Dashboard
A professional Power BI dashboard (`retail_analytics_dashboard.pbix`) brings the SQL insights to life with interactive visuals and KPIs.

### 🔍 Dashboard Highlights
- Interactive **slicers** for *Year*, *Product*, and *Region*  
- **KPI Cards** for revenue, order count, and average shipping duration  
- **Line charts** showing sales trends over time  
- **Bar charts** comparing performance by territory  
- **Smart narrative** for automated natural language insights  

---

## 📝 How to Use the Project
### ✅ Step 1 — Load SQL Scripts
Run the `.sql` files in **SQL Server Management Studio (SSMS)** or **Azure Data Studio** connected to the `AdventureWorksDW2022` database.

### ✅ Step 2 — Load Data into Power BI
Open the `.pbix` file → click **Refresh Data** → connect to your SQL Server instance.

### ✅ Step 3 — Explore Insights
Navigate through the Power BI dashboard tabs:
- **Sales Overview**
- **Territory Analysis**
- **Product Insights**
- **HR Analytics**

---

## 🚀 Key Skills Demonstrated
- **SQL:** CTEs, Joins, Window Functions, Aggregations, Filtering  
- **Power BI:** DAX Basics, Data Modeling, KPI Cards, Interactive Visuals  
- **Analytics Thinking:** Transforming data into insights  
- **Business Acumen:** Retail performance analysis and KPI design  

---

## 🧩 Tools & Technologies
- **Database:** Microsoft SQL Server  
- **Visualization:** Microsoft Power BI  
- **Dataset:** AdventureWorksDW2022  
- **Language:** SQL (T-SQL)

---

## 💡 Author
**Ghazaleh Mo**  
📧 [Insert your contact or LinkedIn link here]  
🗂️ *Built with SQL + Power BI | Retail Analytics Portfolio Project*

---

⭐ If you found this project insightful, feel free to **star** the repository and check out my other data analytics projects!
