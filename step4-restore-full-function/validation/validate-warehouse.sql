-- Warehouse validation for the Fabric BCDR demo.
-- Run this in the recovered warehouse SQL editor.

SELECT name
FROM sys.tables
WHERE name IN ('dim_customer', 'dim_product', 'dim_region', 'dim_calendar', 'fact_sales')
ORDER BY name;

SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dbo.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dbo.dim_product
UNION ALL
SELECT 'dim_region', COUNT(*) FROM dbo.dim_region
UNION ALL
SELECT 'dim_calendar', COUNT(*) FROM dbo.dim_calendar
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM dbo.fact_sales;
