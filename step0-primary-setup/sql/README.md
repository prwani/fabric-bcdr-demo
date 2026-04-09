# Warehouse sample-data seed

`seed-warehouse.sql` creates a small warehouse star schema and inserts synthetic rows so the BCDR demo includes warehouse data as well as lakehouse data.

## How to run it

1. Open the target warehouse in Fabric.
2. Open a new SQL query window.
3. Paste the contents of `seed-warehouse.sql`.
4. Run the script.

## Why this is separate from the REST bootstrap

Warehouse creation is handled by the Fabric REST API, but warehouse table creation and row insertion run through the **SQL interface**. This repo keeps the warehouse seed as an explicit SQL script so the setup remains transparent and portable.
