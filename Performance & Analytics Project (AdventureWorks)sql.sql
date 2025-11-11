
USE AdventureWorks2022;

--1 Analytical Insight: Evaluates customer order efficiency by calculating shipping lead time (OrderDate → ShipDate)

SELECT 
      so.CustomerID,
      (p.FirstName + ' ' + p.LastName) AS Full_Name,
      CAST(so.OrderDate AS date) AS Order_Date,
      CAST(so.ShipDate AS date) AS Ship_Date,
      DATEDIFF(DAY, so.OrderDate, so.ShipDate) AS Date_Diff
FROM Sales.SalesOrderHeader AS so
LEFT JOIN Person.Person AS p 
   ON p.BusinessEntityID = so.CustomerID
WHERE so.OrderDate >= DATEADD(YEAR, -12, CAST(GETDATE() AS date));

--2 Analytical Insight: Ranks salespersons by yearly sales within each postal code to identify top regional performers
SELECT 
      ROW_NUMBER() OVER (PARTITION BY a.PostalCode ORDER BY s.SalesYTD DESC) AS SalesRank,
      p.LastName,
      s.SalesYTD,
      a.PostalCode
FROM Sales.SalesPerson AS s
JOIN Person.Person AS p 
   ON p.BusinessEntityID = s.BusinessEntityID
JOIN Person.BusinessEntityAddress AS b 
   ON b.BusinessEntityID = s.BusinessEntityID
LEFT JOIN Person.Address AS a 
   ON a.AddressID = b.AddressID
WHERE s.SalesYTD <> 0 
  AND s.TerritoryID IS NOT NULL;


--3 Analytical Insight: Implements a scalar function to calculate employee age and applies it for demographic workforce analysis
CREATE FUNCTION dbo.fn_GetAge (@BirthDate DATE)
RETURNS INT
AS 
BEGIN 
	RETURN DATEDIFF(YEAR, @BirthDate, GETDATE());
END;
GO

SELECT 
      p.FirstName + ' ' + p.LastName AS FullName,
      e.BirthDate,
      dbo.fn_GetAge(e.BirthDate) AS Age
FROM Person.Person AS p
JOIN HumanResources.Employee AS e 
   ON e.BusinessEntityID = p.BusinessEntityID;



--4 Analytical Insight: Defines a table-valued function to retrieve detailed line-item metrics for a specific sales order, supporting order-level profitability analysis
CREATE FUNCTION dbo.fn_GetOrderDetails (@SalesOrderID INT)
RETURNS @Result TABLE
(
    ProductID INT,
    OrderQty INT,
    UnitPrice MONEY,
    LineTotal MONEY
)
AS
BEGIN
    INSERT INTO @Result (ProductID, OrderQty, UnitPrice, LineTotal)
    SELECT 
        ProductID,
        OrderQty,
        UnitPrice,
        UnitPrice * OrderQty AS LineTotal
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @SalesOrderID;

    RETURN;
END;
GO

--Execute the function to analyze order details for a specific SalesOrderID
SELECT * 
FROM dbo.fn_GetOrderDetails(43659);



--5 Analytical Insight: Aggregates monthly sales volume and revenue for 2013 to identify seasonal trends and performance fluctuations
SELECT 
     YEAR(sh.OrderDate) AS Year,
     MONTH(sh.OrderDate) AS Month_Num,
     DATENAME(MONTH, sh.OrderDate) AS Month_Name,
     SUM(so.OrderQty) AS TotalQty,
     SUM(so.LineTotal) AS TotalSales
FROM Sales.SalesOrderDetail AS so
JOIN Sales.SalesOrderHeader AS sh
   ON sh.SalesOrderID = so.SalesOrderID
GROUP BY 
     YEAR(sh.OrderDate),
     MONTH(sh.OrderDate),
     DATENAME(MONTH, sh.OrderDate)
HAVING YEAR(sh.OrderDate) = 2013
ORDER BY MONTH(sh.OrderDate);



-- 6Analytical Insight: Utilizes ROLLUP to generate hierarchical sales summaries by year and month, providing both detailed and aggregate revenue insights
SELECT  
    ISNULL(CAST(YEAR(OrderDate) AS VARCHAR), 'ALL YEARS') AS OrderYear,
    ISNULL(CAST(MONTH(OrderDate) AS VARCHAR), 'ALL MONTHS') AS OrderMonth,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY ROLLUP (YEAR(OrderDate), MONTH(OrderDate))
ORDER BY YEAR(OrderDate), MONTH(OrderDate);



--7 Analytical Insight: Generates a hierarchical summary of product sales by year using ROLLUP, supporting both product-level and overall performance analysis
SELECT 
     ISNULL(CAST(so.ProductID AS VARCHAR), 'Total Products') AS ProductID,
     ISNULL(MAX(p.Name), 'Total Product') AS ProductName,
     SUM(so.OrderQty) AS TotalQty,
     COALESCE(CAST(YEAR(h.OrderDate) AS VARCHAR), 'AllYears') AS OrderYear
FROM Sales.SalesOrderHeader AS h
JOIN Sales.SalesOrderDetail AS so  
    ON h.SalesOrderID = so.SalesOrderID
JOIN Production.Product AS p   
    ON p.ProductID = so.ProductID
GROUP BY ROLLUP (so.ProductID, YEAR(h.OrderDate))
ORDER BY so.ProductID, YEAR(h.OrderDate);




--8 Analytical Insight: Uses CUBE to produce multi-dimensional sales summaries by year, month, and territory, enabling comprehensive trend and regional performance analysis
SELECT 
    ISNULL(CAST(YEAR(h.OrderDate) AS VARCHAR), 'ALL YEARS') AS OrderYear,
    ISNULL(CAST(MONTH(h.OrderDate) AS VARCHAR), 'ALL MONTHS') AS OrderMonth,
    ISNULL(t.Name, 'ALL TERRITORIES') AS TerritoryName,
    SUM(h.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS h
JOIN Sales.SalesTerritory AS t 
    ON h.TerritoryID = t.TerritoryID
GROUP BY CUBE (YEAR(h.OrderDate), MONTH(h.OrderDate), t.Name)
ORDER BY 
    GROUPING(YEAR(h.OrderDate)),   -- Grand total at the end
    YEAR(h.OrderDate),             -- Years in order
    GROUPING(MONTH(h.OrderDate)),  -- Subtotals for months
    MONTH(h.OrderDate),           
    TerritoryName;


--9 Analytical Insight: Identifies products consistently ordered across consecutive years (2013 & 2014), highlighting stable product demand
SELECT ProductID
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh 
    ON sod.SalesOrderID = soh.SalesOrderID
WHERE YEAR(soh.OrderDate) = 2013

INTERSECT

SELECT ProductID
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh 
    ON sod.SalesOrderID = soh.SalesOrderID
WHERE YEAR(soh.OrderDate) = 2014;


--10 Analytical Insight: Retrieves employees who have worked in Sales but never in Marketing, useful for workforce allocation and departmental analysis
SELECT BusinessEntityID
FROM HumanResources.EmployeeDepartmentHistory AS edh
JOIN HumanResources.Department AS d 
    ON edh.DepartmentID = d.DepartmentID
WHERE d.Name = 'Sales'

EXCEPT

SELECT BusinessEntityID
FROM HumanResources.EmployeeDepartmentHistory AS edh
JOIN HumanResources.Department AS d 
    ON edh.DepartmentID = d.DepartmentID
WHERE d.Name = 'Marketing';


--11 Analytical Insight: Shows each product's price along with the average price of its category, enabling comparison of product pricing against category benchmarks
SELECT  
    p.Name AS ProductName,
    p.ListPrice,
    pc.Name AS CategoryName,
    (
        SELECT AVG(p2.ListPrice)
        FROM Production.Product AS p2
        JOIN Production.ProductSubcategory AS ps2
          ON p2.ProductSubcategoryID = ps2.ProductSubcategoryID
        WHERE ps2.ProductCategoryID = ps.ProductCategoryID
    ) AS AvgCategoryPrice
FROM Production.Product AS p
JOIN Production.ProductSubcategory AS ps
  ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory AS pc
  ON pc.ProductCategoryID = ps.ProductCategoryID;



--12 Analytical Insight: Identifies employees whose current pay rate is higher than any previous rate, highlighting recent salary increases
WITH PayHistoryOrdered AS (
    SELECT
        eph.BusinessEntityID,
        eph.Rate,
        eph.RateChangeDate,
        ROW_NUMBER() OVER (PARTITION BY eph.BusinessEntityID ORDER BY eph.RateChangeDate DESC) AS rn,
        -- Highest rate until previous row (NULL if no prior record)
        MAX(eph.Rate) OVER (
            PARTITION BY eph.BusinessEntityID
            ORDER BY eph.RateChangeDate
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS MaxPrevRate
    FROM HumanResources.EmployeePayHistory AS eph
)
SELECT
    p.BusinessEntityID,
    p.FirstName,
    p.LastName,
    pho.Rate AS CurrentRate,
    pho.MaxPrevRate
FROM PayHistoryOrdered AS pho
JOIN Person.Person AS p
    ON pho.BusinessEntityID = p.BusinessEntityID
WHERE pho.rn = 1                    -- Only the latest record (current rate)
  AND (pho.MaxPrevRate IS NULL      -- Accept if no previous history
       OR pho.Rate > pho.MaxPrev;





--13 Analytical Insight: Retrieves the latest order for each customer using CROSS APPLY, supporting analysis of recent customer activity and revenue
SELECT 
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    lastOrder.SalesOrderID,
    lastOrder.OrderDate,
    lastOrder.TotalDue
FROM Sales.Customer AS c
JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID
CROSS APPLY (
    SELECT TOP 1 
           h.SalesOrderID, 
           h.OrderDate, 
           h.TotalDue
    FROM Sales.SalesOrderHeader AS h
    WHERE h.CustomerID = c.CustomerID
    ORDER BY h.OrderDate DESC
) AS lastOrder
ORDER BY lastOrder.OrderDate DESC;


--14 Analytical Insight: Identifies line items exceeding the average order value using CROSS APPLY, supporting product-level profitability analysis
SELECT 
    soh.SalesOrderID,
    sod.ProductID,
    p.Name AS ProductName,
    sod.LineTotal,
    stats.AvgLineTotal
FROM Sales.SalesOrderHeader AS soh
CROSS APPLY (
    SELECT AVG(LineTotal) AS AvgLineTotal
    FROM Sales.SalesOrderDetail AS sod
    WHERE sod.SalesOrderID = soh.SalesOrderID
) AS stats
JOIN Sales.SalesOrderDetail AS sod
    ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
WHERE sod.LineTotal > stats.AvgLineTotal;


--15 Analytical Insight: Identifies the top 3 customers by quantity for each product using CROSS APPLY, supporting targeted sales and marketing strategies
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    topCustomers.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    topCustomers.TotalQty
FROM Production.Product AS p
CROSS APPLY (
    SELECT TOP 3 
        soh.CustomerID,
        SUM(sod.OrderQty) AS TotalQty
    FROM Sales.SalesOrderDetail AS sod
    JOIN Sales.SalesOrderHeader AS soh
        ON sod.SalesOrderID = soh.SalesOrderID
    WHERE sod.ProductID = p.ProductID
    GROUP BY soh.CustomerID
    ORDER BY SUM(sod.OrderQty) DESC
) AS topCustomers
JOIN Sales.Customer AS sc
    ON topCustomers.CustomerID = sc.CustomerID
JOIN Person.Person AS c
    ON sc.PersonID = c.BusinessEntityID
ORDER BY p.ProductID, topCustomers.TotalQty DESC;



--16 Analytical Insight: Recursively retrieves an employee hierarchy starting from a specific manager, enabling organizational structure analysis
WITH EmployeeHierarchy AS
(
    -- Base case: starting manager or root node
    SELECT 
        e.BusinessEntityID,
        e.JobTitle,
        e.OrganizationLevel,
        e.OrganizationNode
    FROM HumanResources.Employee AS e
    WHERE e.BusinessEntityID = 2   -- Starting employee

    UNION ALL

    -- Recursive case: find direct subordinates
    SELECT 
        e.BusinessEntityID,
        e.JobTitle,
        e.OrganizationLevel,
        e.OrganizationNode
    FROM HumanResources.Employee AS e
    INNER JOIN EmployeeHierarchy AS eh
        ON e.OrganizationNode.GetAncestor(1) = eh.OrganizationNode
)
SELECT 
    BusinessEntityID,
    JobTitle,
    OrganizationLevel,
    OrganizationNode.ToString() AS OrgPath
FROM EmployeeHierarchy
ORDER BY OrganizationLevel, BusinessEntityID;



--17 Analytical Insight: Identifies high-value customers with more than 3 orders and total purchases over 20,000, supporting targeted marketing and VIP customer analysis
WITH customerCte AS (
    SELECT  
         c.CustomerID,
         p.FirstName + ' ' + p.LastName AS FullName
    FROM Sales.Customer AS c
    JOIN Person.Person AS p
        ON p.BusinessEntityID = c.PersonID
),
OrderCount_cte AS (
    SELECT 
         soh.CustomerID,
         COUNT(*) AS OrderCount,
         SUM(soh.TotalDue) AS Total_Purchase
    FROM Sales.SalesOrderHeader AS soh
    GROUP BY soh.CustomerID
    HAVING COUNT(*) > 3 
       AND SUM(soh.TotalDue) > 20000
)
SELECT 
      cc.*,
      oc.OrderCount,
      oc.Total_Purchase
FROM OrderCount_cte AS oc
JOIN customerCte AS cc
    ON cc.CustomerID = oc.CustomerID
ORDER BY oc.Total_Purchase DESC;

--18 Calculate a 3-period moving average of each product's unit price over time 
-- using a SQL Window Function (AVG OVER). This helps analyze short-term price 
-- trends and variations for every product in the AdventureWorks dataset.

WITH RankedSales AS (
    SELECT
        ProductID,
        CAST (ModifiedDate AS date)AS Modified_Date,
        UnitPrice,
        ROW_NUMBER() OVER (
            PARTITION BY ProductID 
            ORDER BY ModifiedDate DESC
        ) AS rn
    FROM Sales.SalesOrderDetail
)
SELECT *
FROM RankedSales
WHERE rn <= 3
ORDER BY ProductID, Modified_Date DESC;


--19 Display total sales aggregated by year and territory using GROUP BY CUBE.
-- This query shows subtotals and grand totals for multidimensional sales 
-- analysis in the AdventureWorks dataset.

SELECT 
    COALESCE (CAST (YEAR(soh.OrderDate)AS varchar (20)),'All Year') AS SalesYear,
    COALESCE (st.Name, 'ALL Territories') AS Territory,
    SUM(soh.SubTotal) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesTerritory AS st 
    ON soh.TerritoryID = st.TerritoryID
GROUP BY CUBE (
    YEAR(soh.OrderDate),
    st.Name
)
ORDER BY SalesYear, Territory;


--20 Show each customer's minimum, maximum, and average order totals in a single row.
-- Aggregation is done using MIN, MAX, and AVG with GROUP BY on customer name.
SELECT
    p.FirstName + ' ' + p.LastName AS FullName,
    MIN(soh.TotalDue) AS MinOrder,
    MAX(soh.TotalDue) AS MaxOrder,
    AVG(soh.TotalDue) AS AvgOrder
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c 
    ON c.CustomerID = soh.CustomerID
JOIN Person.Person AS p
    ON p.BusinessEntityID = c.PersonID
GROUP BY p.FirstName, p.LastName
ORDER BY FullName;

--21 Find orders where TotalDue is greater than the average order amount of the same customer
-- using a correlated subquery.
SELECT 
    soh.SalesOrderID,
    soh.CustomerID,
    p.FirstName + ' ' + p.LastName AS FullName,
    soh.TotalDue
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c
    ON c.CustomerID = soh.CustomerID
JOIN Person.Person AS p
    ON p.BusinessEntityID = c.PersonID
WHERE soh.TotalDue > (
    SELECT AVG(soh2.TotalDue)AS avg_order
    FROM Sales.SalesOrderHeader AS soh2
    WHERE soh2.CustomerID = soh.CustomerID
)
ORDER BY CustomerID, TotalDue DESC;

--22 Calculate daily order count and include the previous day's count using LAG().
SELECT
    CAST ( OrderDate AS date) AS OrderDate,
    COUNT(*) AS DailyOrderCount,
    LAG(COUNT(*)) OVER (ORDER BY CONVERT(date, OrderDate)) AS PreviousDayCount
FROM Sales.SalesOrderHeader
GROUP BY CONVERT(date, OrderDate)
ORDER BY OrderDate;

--23 Calculate total sales for each product along with its category and subcategory.
-- Aggregates sales using SUM(LineTotal) and demonstrates proper joins across 
-- Product, ProductSubcategory, and ProductCategory in AdventureWorks.

SELECT
    sod.ProductID,
    p.Name AS Product_Name,
    pc.Name AS Category,
    ps.Name  AS Subcategory,
    SUM(sod.LineTotal)AS Total_sale
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p
ON p.ProductID=sod.ProductID
JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID=ps.ProductSubcategoryID
JOIN Production.ProductCategory pc
ON pc.ProductCategoryID=ps.ProductCategoryID
GROUP BY sod.ProductID,p.Name, pc.Name,ps.Name
    ORDER BY sod.ProductID;

—24Two approaches to perform year-over-year (YoY) sales comparison per territory:
one using LAG() window function and another using self join.”

SELECT
    st.Name AS Territory_Name,
    YEAR(soh.OrderDate) AS Order_Year,
    SUM(soh.SubTotal) AS Total_Sales,
    LAG(SUM(soh.SubTotal)) OVER (PARTITION BY st.TerritoryID ORDER BY YEAR(soh.OrderDate)) AS Prev_Year_Sales,
    SUM(soh.SubTotal) - LAG(SUM(soh.SubTotal)) OVER (PARTITION BY st.TerritoryID ORDER BY YEAR(soh.OrderDate)) AS Sales_Diff
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesTerritory AS st 
    ON soh.TerritoryID = st.TerritoryID
GROUP BY 
    st.TerritoryID,
    st.Name,
    YEAR(soh.OrderDate)
ORDER BY 
    st.TerritoryID,
    Order_Year;

WITH YearlySales AS (
    SELECT 
        TerritoryID,
        YEAR(OrderDate) AS Order_Year,
        SUM(SubTotal) AS Total_Sales
    FROM Sales.SalesOrderHeader
    GROUP BY TerritoryID, YEAR(OrderDate)
)
SELECT 
    cur.TerritoryID,
    cur.Order_Year,
    cur.Total_Sales AS Current_Year_Sales,
    prev.Total_Sales AS Prev_Year_Sales,
    cur.Total_Sales - prev.Total_Sales AS Sales_Diff
FROM YearlySales AS cur
LEFT JOIN YearlySales AS prev
    ON cur.TerritoryID = prev.TerritoryID
    AND cur.Order_Year = prev.Order_Year + 1
ORDER BY cur.TerritoryID, cur.Order_Year;

--25 This query retrieves the 100 most recent sales orders from the SalesOrderHeader table 
-- using the ORDER BY, OFFSET, and FETCH clauses for pagination.
-- It joins Customer and Person tables to display the customer's full name alongside the order details.
-- OFFSET defines how many rows to skip, and FETCH specifies how many rows to return.
-- This technique is commonly used for paging through large datasets in modern SQL Server queries.

SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    soh.TotalDue
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c 
    ON soh.CustomerID = c.CustomerID
JOIN Person.Person AS p 
    ON c.PersonID = p.BusinessEntityID
ORDER BY soh.OrderDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

--26 Generate a comma-separated list of product names per subcategory using STRING_AGG.

SELECT
    psc.ProductSubcategoryID,
    psc.Name AS ProductSubcategoryName,
    STRING_AGG(p.Name, ', ') WITHIN GROUP (ORDER BY p.Name) AS ProductList
FROM Production.ProductSubcategory psc
LEFT JOIN Production.Product p
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
GROUP BY
    psc.ProductSubcategoryID,
    psc.Name
ORDER BY psc.ProductSubcategoryID;

--27 Calculate linear trend (slope) of order amounts per customer using regression formula.
SELECT 
    c.CustomerID,
    ROUND(CAST(
        (COUNT(*) * SUM(DATEDIFF(DAY, '2011-01-01', soh.OrderDate) * soh.TotalDue)
            - SUM(DATEDIFF(DAY, '2011-01-01', soh.OrderDate)) * SUM(soh.TotalDue)
        ) AS FLOAT
    )
    /
  NULLIF((COUNT(*) * SUM(POWER(DATEDIFF(DAY, '2011-01-01', soh.OrderDate), 2))
         - POWER(SUM(DATEDIFF(DAY, '2011-01-01', soh.OrderDate)), 2)),
        0 ),2) AS Trend_Slope
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
GROUP BY c.CustomerID
ORDER BY Trend_Slope DESC;

--28 Compare each product's current price with its next price using LEAD() to detect increases or decreases.

SELECT 
    ProductID,
    CAST (StartDate AS date) AS Start_Date,
    ListPrice,
    LEAD(ListPrice) OVER (PARTITION BY ProductID ORDER BY StartDate) AS NextPrice,
    CASE 
        WHEN LEAD(ListPrice) OVER (PARTITION BY ProductID ORDER BY StartDate) > ListPrice THEN 'Increased'
        WHEN LEAD(ListPrice) OVER (PARTITION BY ProductID ORDER BY StartDate) < ListPrice THEN 'Decreased'
        ELSE 'No Change'
    END AS Price_Trend
FROM Production.ProductListPriceHistory
ORDER BY ProductID, Start_Date;

--29 Recursive CTE to extract the organizational hierarchy of a specific employee starting from BusinessEntityID = 2.

WITH EmployeeHierarchy AS
(  SELECT 
        e.BusinessEntityID,
        e.JobTitle,
        e.OrganizationLevel,
        e.OrganizationNode
    FROM HumanResources.Employee AS e
    WHERE e.BusinessEntityID = 2 
    UNION ALL
    SELECT 
        e.BusinessEntityID,
        e.JobTitle,
        e.OrganizationLevel,
        e.OrganizationNode
    FROM HumanResources.Employee AS e
    INNER JOIN EmployeeHierarchy AS eh
        ON e.OrganizationNode.GetAncestor(1) = eh.OrganizationNode
)
SELECT 
    BusinessEntityID,
    JobTitle,
    OrganizationLevel,
    OrganizationNode.ToString() AS OrgPath
FROM EmployeeHierarchy
ORDER BY OrganizationLevel, BusinessEntityID;

--30 Calculate average delivery time per territory and show only territories above overall average.
WITH AvgShip AS (
   
    SELECT 
        TerritoryID,
        AVG(DATEDIFF(DAY, OrderDate, ShipDate)) AS AvgDaysToShip
    FROM Sales.SalesOrderHeader
    GROUP BY TerritoryID
),
OverallAvg AS (
   SELECT AVG(AvgDaysToShip) AS OverallAvgDays
    FROM AvgShip
)
SELECT 
    a.TerritoryID,
    a.AvgDaysToShip
FROM AvgShip a
CROSS JOIN OverallAvg o
WHERE a.AvgDaysToShip > o.OverallAvgDays
ORDER BY a.AvgDaysToShip DESC;

—31 Calculates the number of days each product had sales and its average daily sales based on order data from AdventureWorks2021.
WITH DailySales AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        CAST(soh.OrderDate AS DATE) AS SalesDate,
        SUM(sod.OrderQty) AS TotalDailySales
    FROM Sales.SalesOrderDetail AS sod
    INNER JOIN Sales.SalesOrderHeader AS soh
        ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN Production.Product AS p
        ON sod.ProductID = p.ProductID
    GROUP BY p.ProductID, p.Name, CAST(soh.OrderDate AS DATE)
)
SELECT 
    ds.ProductID,
    ds.ProductName,
    COUNT(DISTINCT ds.SalesDate) AS DaysWithSales,
    AVG(ds.TotalDailySales) AS AvgDailySales
FROM DailySales AS ds
GROUP BY ds.ProductID, ds.ProductName
ORDER BY DaysWithSales DESC;

—32 Uses COALESCE, ROLLUP, and GROUPING() to replace NULL values and distinguish detail rows from subtotal and grand total levels in product price aggregation.
SELECT 
    COALESCE(p.Color, 'Unknown') AS Color,
    COALESCE(CAST(p.ProductSubcategoryID AS VARCHAR(10)), 'No Subcategory') AS ProductSubcategoryID,
    SUM(p.ListPrice) AS TotalListPrice,
    CASE 
        WHEN GROUPING(p.Color) = 1 AND GROUPING(p.ProductSubcategoryID) = 1 THEN 'Grand Total'
        WHEN GROUPING(p.Color) = 1 THEN 'Subtotal by Color'
        WHEN GROUPING(p.ProductSubcategoryID) = 1 THEN 'Subtotal by Subcategory'
        ELSE 'Detail Level'
    END AS RowType
FROM Production.Product AS p
GROUP BY ROLLUP (p.Color, p.ProductSubcategoryID)
ORDER BY Color, ProductSubcategoryID;



—33 Calculates daily sales and their running total using a window function with an explicit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW frame.
SELECT 
    CAST(soh.OrderDate AS DATE) AS SalesDate,
    SUM(sod.LineTotal) AS DailySales,
    SUM(SUM(sod.LineTotal)) OVER (ORDER BY CAST(soh.OrderDate AS DATE)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY CAST(soh.OrderDate AS DATE)
ORDER BY SalesDate;

—34 Identifies customers who placed orders in the last 3 months but had no activity in the previous 6 months using time-window analysis.
WITH CustomerActivity AS (
    SELECT 
        c.CustomerID,
        MAX(soh.OrderDate) AS LastOrderDate
    FROM Sales.SalesOrderHeader AS soh
    JOIN Sales.Customer AS c
        ON soh.CustomerID = c.CustomerID
    GROUP BY c.CustomerID
),
ActiveCustomers AS (
    SELECT 
        c.CustomerID,
        c.LastOrderDate
    FROM CustomerActivity AS c
    WHERE c.LastOrderDate >= DATEADD(MONTH, -3, GETDATE())),
InactiveBefore AS (
    SELECT 
        c.CustomerID,
        c.LastOrderDate
    FROM CustomerActivity AS c
    WHERE c.LastOrderDate < DATEADD(MONTH, -3, GETDATE()) 
      AND c.LastOrderDate >= DATEADD(MONTH, -9, GETDATE()) 
)
SELECT 
    a.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    a.LastOrderDate
FROM ActiveCustomers AS a
JOIN Sales.Customer AS c
    ON a.CustomerID = c.CustomerID
JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID
WHERE a.CustomerID NOT IN (SELECT CustomerID FROM InactiveBefore)
ORDER BY a.LastOrderDate DESC;