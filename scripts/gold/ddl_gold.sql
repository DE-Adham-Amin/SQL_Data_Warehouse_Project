/*
===============================================================================
    Gold Layer - Dimension and Fact Views
===============================================================================

    Script Purpose:
        Create the Gold Layer views that represent the Star Schema
        for analytical and reporting purposes.

    Views:
        1. gold.dim_customers
        2. gold.dim_products
        3. gold.fact_sales

    Architecture:
        - Dimension Tables: Customers and Products.
        - Fact Table: Sales.

    Notes:
        - Surrogate keys are generated using ROW_NUMBER().
        - Only active products are included in dim_products.
        - LEFT JOINs preserve records even when matching data is missing.

===============================================================================
*/


-- ============================================================================
-- 1. Create Customer Dimension
-- ============================================================================
-- Purpose:
--     Combine customer information from CRM and ERP sources.
--
-- Transformations:
--     - Generate a surrogate customer key.
--     - Combine customer personal information with location data.
--     - Resolve missing gender using ERP data.
--     - Include customer birth date and creation date.
-- ============================================================================

CREATE OR ALTER VIEW gold.dim_customers AS

SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,
    CASE
        WHEN ci.cst_gndr = 'N/A'
            THEN COALESCE(ca.gen, 'N/A')
        ELSE ci.cst_gndr
    END AS gender,
    ca.bdate AS birth_date,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info AS ci

LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_id = la.cid;

GO


-- ============================================================================
-- 2. Create Product Dimension
-- ============================================================================
-- Purpose:
--     Combine product information with product category details.
--
-- Transformations:
--     - Generate a surrogate product key.
--     - Enrich products with category and subcategory information.
--     - Include product cost, line, and starting date.
--     - Filter out discontinued products using prd_end_dt.
-- ============================================================================

CREATE OR ALTER VIEW gold.dim_products AS

SELECT
    ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,
    pi.prd_id AS product_id,
    pi.prd_key AS product_number,
    pi.prd_nm AS product_name,
    pi.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance,
    pi.prd_cost AS cost,
    pi.prd_line AS product_line,
    pi.prd_start_dt AS start_date

FROM silver.crm_prd_info AS pi

LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pi.cat_id = pc.id

WHERE pi.prd_end_dt IS NULL;

GO


-- ============================================================================
-- 3. Create Sales Fact
-- ============================================================================
-- Purpose:
--     Create the central fact view containing sales transactions.
--
-- Transformations:
--     - Connect sales transactions with customer dimension.
--     - Connect sales transactions with product dimension.
--     - Replace natural keys with dimension surrogate keys.
--     - Include sales measures and transaction dates.
--
-- Measures:
--     - sales_amount
--     - quantity
--     - price
--
-- Foreign Keys:
--     - product_key
--     - customer_key
-- ============================================================================

CREATE OR ALTER VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details AS sd

LEFT JOIN gold.dim_products AS dp
    ON sd.sls_prd_key = dp.product_number

LEFT JOIN gold.dim_customers AS dc
    ON sd.sls_cust_id = dc.customer_id;

GO
