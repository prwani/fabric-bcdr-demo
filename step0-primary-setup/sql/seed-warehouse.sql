-- Synthetic warehouse seed for the Fabric BCDR demo.
-- Run this script in the Fabric warehouse SQL editor after the warehouse is created.

DROP TABLE IF EXISTS dbo.fact_sales;
DROP TABLE IF EXISTS dbo.dim_calendar;
DROP TABLE IF EXISTS dbo.dim_region;
DROP TABLE IF EXISTS dbo.dim_product;
DROP TABLE IF EXISTS dbo.dim_customer;

CREATE TABLE dbo.dim_customer (
    customer_id INT NOT NULL,
    customer_segment VARCHAR(50) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    state_code CHAR(2) NOT NULL,
    CONSTRAINT PK_dim_customer PRIMARY KEY NONCLUSTERED (customer_id) NOT ENFORCED
);

CREATE TABLE dbo.dim_product (
    product_id INT NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    list_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_dim_product PRIMARY KEY NONCLUSTERED (product_id) NOT ENFORCED
);

CREATE TABLE dbo.dim_region (
    region_id INT NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    dr_pattern VARCHAR(20) NOT NULL,
    CONSTRAINT PK_dim_region PRIMARY KEY NONCLUSTERED (region_id) NOT ENFORCED
);

CREATE TABLE dbo.dim_calendar (
    date_key INT NOT NULL,
    calendar_date DATE NOT NULL,
    calendar_month INT NOT NULL,
    calendar_quarter INT NOT NULL,
    calendar_year INT NOT NULL,
    CONSTRAINT PK_dim_calendar PRIMARY KEY NONCLUSTERED (date_key) NOT ENFORCED
);

CREATE TABLE dbo.fact_sales (
    sale_id INT NOT NULL,
    date_key INT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    region_id INT NOT NULL,
    units INT NOT NULL,
    gross_sales DECIMAL(12, 2) NOT NULL,
    support_tier VARCHAR(50) NOT NULL,
    CONSTRAINT PK_fact_sales PRIMARY KEY NONCLUSTERED (sale_id) NOT ENFORCED
);

INSERT INTO dbo.dim_customer (customer_id, customer_segment, customer_name, state_code) VALUES
    (1, 'Consumer', 'Contoso Retail', 'CA'),
    (2, 'Consumer', 'Fabrikam Stores', 'TX'),
    (3, 'Corporate', 'Northwind Traders', 'NY'),
    (4, 'Corporate', 'Adventure Works', 'WA'),
    (5, 'Public Sector', 'City of Redmond', 'WA'),
    (6, 'Public Sector', 'County of Travis', 'TX'),
    (7, 'Healthcare', 'Wingtip Health', 'FL'),
    (8, 'Healthcare', 'Blue Yonder Care', 'NC');

INSERT INTO dbo.dim_product (product_id, product_category, product_name, list_price) VALUES
    (1, 'Analytics', 'Fabric Observability Pack', 399.00),
    (2, 'Storage', 'Geo Restore Vault', 599.00),
    (3, 'AI', 'Inference Accelerator', 1299.00),
    (4, 'Security', 'Zero Trust Connector', 899.00),
    (5, 'Compute', 'Spark Capacity Burst', 1599.00),
    (6, 'IoT', 'Telemetry Gateway', 499.00);

INSERT INTO dbo.dim_region (region_id, region_name, dr_pattern) VALUES
    (1, 'East US', 'paired'),
    (2, 'West US 2', 'paired'),
    (3, 'Central US', 'nonpaired'),
    (4, 'North Europe', 'paired');

INSERT INTO dbo.dim_calendar (date_key, calendar_date, calendar_month, calendar_quarter, calendar_year) VALUES
    (20250115, '2025-01-15', 1, 1, 2025),
    (20250215, '2025-02-15', 2, 1, 2025),
    (20250315, '2025-03-15', 3, 1, 2025),
    (20250415, '2025-04-15', 4, 2, 2025),
    (20250515, '2025-05-15', 5, 2, 2025),
    (20250615, '2025-06-15', 6, 2, 2025);

INSERT INTO dbo.fact_sales (sale_id, date_key, customer_id, product_id, region_id, units, gross_sales, support_tier) VALUES
    (1, 20250115, 1, 1, 1, 4, 1596.00, 'Standard'),
    (2, 20250115, 2, 2, 2, 2, 1198.00, 'Premium'),
    (3, 20250215, 3, 3, 1, 1, 1299.00, 'MissionCritical'),
    (4, 20250215, 4, 5, 2, 3, 4797.00, 'Premium'),
    (5, 20250315, 5, 4, 4, 2, 1798.00, 'Standard'),
    (6, 20250315, 6, 1, 3, 6, 2394.00, 'Premium'),
    (7, 20250415, 7, 6, 3, 8, 3992.00, 'Standard'),
    (8, 20250415, 8, 2, 4, 4, 2396.00, 'MissionCritical'),
    (9, 20250515, 1, 3, 1, 2, 2598.00, 'Premium'),
    (10, 20250515, 2, 4, 2, 1, 899.00, 'Standard'),
    (11, 20250615, 3, 5, 1, 2, 3198.00, 'MissionCritical'),
    (12, 20250615, 4, 6, 2, 5, 2495.00, 'Premium'),
    (13, 20250115, 5, 1, 4, 7, 2793.00, 'Standard'),
    (14, 20250215, 6, 2, 3, 3, 1797.00, 'Standard'),
    (15, 20250315, 7, 3, 4, 4, 5196.00, 'MissionCritical'),
    (16, 20250415, 8, 5, 1, 1, 1599.00, 'Premium');

SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dbo.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dbo.dim_product
UNION ALL
SELECT 'dim_region', COUNT(*) FROM dbo.dim_region
UNION ALL
SELECT 'dim_calendar', COUNT(*) FROM dbo.dim_calendar
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM dbo.fact_sales;
