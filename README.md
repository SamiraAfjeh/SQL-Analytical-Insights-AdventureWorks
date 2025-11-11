# SQL-Analytical-Insights-AdventureWorks
A collection of analytical SQL queries built on the AdventureWorks database, covering advanced SQL concepts such as CTEs, window functions, ROLLUP, CUBE, and user-defined functions.

> 💡 Designed for data analysts and learners who want to understand **how to build, optimize, and document** analytical SQL code in a professional way.

---

## 🧩 Contents

1. **usp_CustomerID** — Retrieve customer info and order details  
2. **ups_Employee_names_By_id** — Display employee names by department  
3. **ups_Products_Color** — Filter products dynamically by color  
4. **usp_SearchProducts_Dynamic** — Dynamic product search with flexible filters  
5. **Customer Activity Analysis** — Identify top performing customers  
6. **Shipping Lead Time Query** — Measure delivery efficiency per customer  

---

## 1️⃣ Stored Procedure: `usp_CustomerID`

**Purpose:** Retrieve a customer’s personal info and total due amount for each order.  
This procedure allows NULL input to display all customers if no ID is provided.

```sql
CREATE PROCEDURE dbo.usp_CustomerID
    @CustomerID INT = NULL
AS
BEGIN 
    SET NOCOUNT ON;

    SELECT 
        soh.CustomerID,
        p.FirstName, p.LastName,
        soh.TotalDue,
        CAST(soh.OrderDate AS date) AS Order_Date
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.Customer sc ON soh.CustomerID = sc.CustomerID
    JOIN Person.Person p ON p.BusinessEntityID = sc.PersonID

2️⃣ Stored Procedure: ups_Employee_names_By_id

Purpose: Retrieve employee full names by department, supporting optional DepartmentID filtering.
If @DeptID is NULL, all employees across all departments are displayed.

CREATE PROCEDURE dbo.ups_Employee_names_By_id
    @DeptID INT = NULL
AS
BEGIN 
    SET NOCOUNT ON;

    SELECT 
        d.DepartmentID,
        p.FirstName + ' ' + p.LastName AS Full_Name,
        d.Name AS Department_Name
    FROM HumanResources.Department d
    JOIN HumanResources.EmployeeDepartmentHistory edh
        ON edh.DepartmentID = d.DepartmentID
    JOIN Person.Person p
        ON p.BusinessEntityID = edh.BusinessEntityID
    WHERE (@DeptID IS NULL OR d.DepartmentID = @DeptID);
END;

3️⃣ Stored Procedure: ups_Products_Color

Purpose: Dynamically filter products by color.
If color parameter is NULL, all products are returned.

CREATE PROCEDURE dbo.ups_Products_Color 
    @Color NVARCHAR(15) = NULL 
AS 
BEGIN 
    SET NOCOUNT ON;

    SELECT 
        ProductID,
        Name,
        Color,
        ListPrice,
        Size
    FROM Production.Product
    WHERE (@Color IS NULL OR Color = @Color);
END;

4️⃣ Stored Procedure: usp_SearchProducts_Dynamic

Purpose: Perform dynamic product search by optional parameters (Size and Color).
Demonstrates dynamic SQL construction and parameterization for flexible filtering.

CREATE PROCEDURE dbo.usp_SearchProducts_Dynamic
    @Size NVARCHAR(10) = NULL,
    @Color NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX) = N'SELECT ProductID, Name, Color, Size 
                                   FROM Production.Product WHERE 1=1';
    DECLARE @params NVARCHAR(500) = N'@Size NVARCHAR(10), @Color NVARCHAR(50)';

    IF @Size IS NOT NULL
        SET @sql += N' AND Size = @Size';
    IF @Color IS NOT NULL
        SET @sql += N' AND Color = @Color';

    EXEC sp_executesql @sql, @params, @Size = @Size, @Color = @Color;
END;

5️⃣ Analytical Query: Customer Activity Overview

Purpose: Identify customers with more than 3 purchases and calculate their total spend.
Useful for loyalty or segmentation analysis.

WITH Customer_CTE AS (
    SELECT  
         c.CustomerID,
         p.FirstName + ' ' + p.LastName AS FullName
    FROM Sales.Customer c
    JOIN Person.Person p
         ON p.BusinessEntityID = c.PersonID
),
OrderSummary_CTE AS (
    SELECT 
         soh.CustomerID,
         COUNT(*) AS OrderCount,
         SUM(soh.TotalDue) AS TotalPurchase
    FROM Sales.SalesOrderHeader soh
    GROUP BY soh.CustomerID
    HAVING COUNT(*) > 3
)
SELECT 
    c.FullName,
    o.OrderCount,
    o.TotalPurchase
FROM Customer_CTE c
JOIN OrderSummary_CTE o ON c.CustomerID = o.CustomerID
ORDER BY o.TotalPurchase DESC;

6️⃣ Analytical Query: Shipping Lead Time Analysis

Purpose: Measure order-to-shipment duration (delivery efficiency).
Calculates difference in days between order date and ship date for each customer.

SELECT 
      so.CustomerID,
      (p.FirstName + ' ' + p.LastName) AS Full_Name,
      CAST(so.OrderDate AS date) AS Order_Date,
      CAST(so.ShipDate AS date) AS Ship_Date,
      DATEDIFF(DAY, so.OrderDate, so.ShipDate) AS LeadTime_Days
FROM Sales.SalesOrderHeader AS so
LEFT JOIN Person.Person AS p 
   ON p.BusinessEntityID = so.CustomerID
WHERE so.OrderDate >= DATEADD(YEAR, -12, CAST(GETDATE() AS date))
ORDER BY LeadTime_Days ASC;

🧠 Highlights & Best Practices

Each procedure uses SET NOCOUNT ON; for cleaner execution.

Parameters are designed to handle NULL inputs gracefully.

Dynamic SQL queries are parameterized to avoid SQL injection.

Analytical queries utilize CTE (Common Table Expressions) for readability and modularity.

All scripts are compatible with AdventureWorks 2019+ schema.

🏁 Final Note

This project represents a practical showcase of SQL mastery in a real-world dataset —
including stored procedures, analytical CTE queries, and dynamic parameterized logic.

✨ Built for learning, optimized for performance, and documented for clarity.
    WHERE (@CustomerID IS NULL OR soh.CustomerID = @CustomerID);
END;
