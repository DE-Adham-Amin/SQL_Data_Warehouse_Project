/*
===============================================================================
    silver Layer - Load CRM Sales Details
===============================================================================

    Script Purpose:
        This script cleans and transforms sales transaction data from the
        Bronze layer and loads the processed records into the silver layer.

    Transformations:
        1. Convert Order, Shipping, and Due Dates from INT to DATE.
        2. Handle invalid or NULL date values by replacing them with NULL.
        3. Validate Sales Amount:
           - Recalculate Sales Amount if it is NULL or less than or equal to 0.
           - Ensure Sales Amount matches Quantity multiplied by Unit Price.
        4. Validate Unit Price:
           - Recalculate Unit Price if it is NULL or less than or equal to 0.
           - Ensure Unit Price matches Sales Amount divided by Quantity.
        5. Preserve original Order Number, Product Key, Customer ID,
           and Quantity.

    Loading Strategy:
        - TRUNCATE the silver target table.
        - Insert cleaned and transformed sales records.
        - Automatically populate DWH creation timestamp using DEFAULT.

    Validation:
        - Check Product Key relationships with CRM Product Information.
        - Check Customer ID relationships with CRM Customer Information.
        - Validate Order, Shipping, and Due Dates.
        - Check date sequence consistency.
        - Validate Sales Amount, Quantity, and Unit Price.
        - Verify cleaned records in the silver layer.

    Source:
        bronze.crm_sales_details

    Target:
        silver.crm_sales_details

===============================================================================
*/
-- ============================================================================
-- 1. Explore Source Data
-- ============================================================================
-- View raw sales transaction data from Bronze
SELECT *
FROM   bronze.crm_sales_details;

-- ============================================================================
-- 2. Load Cleaned Sales Data into silver Layer
-- ============================================================================
-- Remove existing records before reloading
TRUNCATE TABLE silver.crm_sales_details;

-- Insert transformed sales records
INSERT INTO silver.crm_sales_details (
       sls_ord_num,
       sls_prd_key,
       sls_cust_id,
       sls_order_dt,
       sls_ship_dt,
       sls_due_dt,
       sls_sales,
       sls_quantity,
       sls_price
)
SELECT sls_ord_num,
       sls_prd_key,
       sls_cust_id,
       -- Convert Order Date from INT to DATE
       CASE WHEN sls_order_dt IS NULL
                 OR LEN(sls_order_dt) != 8 THEN NULL ELSE CAST (CAST (sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,
       -- Convert Shipping Date from INT to DATE
       CASE WHEN sls_ship_dt IS NULL
                 OR LEN(sls_ship_dt) != 8 THEN NULL ELSE CAST (CAST (sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,
       -- Convert Due Date from INT to DATE
       CASE WHEN sls_due_dt IS NULL
                 OR LEN(sls_due_dt) != 8 THEN NULL ELSE CAST (CAST (sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
       -- Validate and recalculate Sales Amount
       CASE WHEN sls_sales <= 0
                 OR sls_sales IS NULL
                 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * sls_price ELSE sls_sales END AS sls_sales,
       sls_quantity,
       -- Validate and recalculate Unit Price
       CASE WHEN sls_price <= 0
                 OR sls_price IS NULL
                 OR sls_price != sls_sales / NULLIF (sls_quantity, 0) THEN sls_sales / sls_quantity ELSE sls_price END AS sls_price
FROM   bronze.crm_sales_details;

-- ============================================================================
-- 3. Validate Product and Customer Relationships
-- ============================================================================
-- Identify sales records with unmatched Product Keys in Bronze
SELECT sls_prd_key
FROM   bronze.crm_sales_details
WHERE  sls_prd_key NOT IN (SELECT prd_key
                           FROM   silver.crm_prd_info);

-- Identify sales records with unmatched Customer IDs in Bronze
SELECT sls_cust_id
FROM   bronze.crm_sales_details
WHERE  sls_cust_id NOT IN (SELECT cst_id
                           FROM   silver.crm_cust_info);

-- Verify unmatched Product Keys in silver
SELECT *
FROM   silver.crm_sales_details AS s
WHERE  NOT EXISTS (SELECT 1
                   FROM   silver.crm_prd_info AS p
                   WHERE  p.prd_key = s.sls_prd_key);

-- Verify unmatched Customer IDs in silver
SELECT *
FROM   silver.crm_sales_details AS s
WHERE  NOT EXISTS (SELECT 1
                   FROM   silver.crm_cust_info AS c
                   WHERE  c.cst_id = s.sls_cust_id);

-- ============================================================================
-- 4. Validate Order, Shipping, and Due Dates
-- ============================================================================
-- Identify invalid Order Dates in Bronze
SELECT sls_order_dt
FROM   bronze.crm_sales_details
WHERE  sls_order_dt IS NULL
       OR LEN(sls_order_dt) != 8;

-- Identify invalid Shipping Dates in Bronze
SELECT sls_ship_dt
FROM   bronze.crm_sales_details
WHERE  sls_ship_dt IS NULL
       OR LEN(sls_ship_dt) != 8;

-- Identify invalid Due Dates in Bronze
SELECT sls_due_dt
FROM   bronze.crm_sales_details
WHERE  sls_due_dt IS NULL
       OR LEN(sls_due_dt) != 8;

-- ============================================================================
-- 5. Validate Date Conversion
-- ============================================================================
-- Preview converted dates before loading into silver
SELECT CASE WHEN sls_order_dt IS NULL
                 OR LEN(sls_order_dt) != 8 THEN NULL ELSE CAST (CAST (sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,
       CASE WHEN sls_ship_dt IS NULL
                 OR LEN(sls_ship_dt) != 8 THEN NULL ELSE CAST (CAST (sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,
       CASE WHEN sls_due_dt IS NULL
                 OR LEN(sls_due_dt) != 8 THEN NULL ELSE CAST (CAST (sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt
FROM   bronze.crm_sales_details;

-- ============================================================================
-- 6. Validate Date Sequence
-- ============================================================================
-- Identify records where Order Date is later than Shipping or Due Date
SELECT sls_ord_num,
       sls_order_dt,
       sls_ship_dt,
       sls_due_dt
FROM   bronze.crm_sales_details
WHERE  sls_order_dt > sls_ship_dt
       OR sls_order_dt > sls_due_dt;

-- Verify date consistency after loading into silver
SELECT sls_ord_num,
       sls_order_dt,
       sls_ship_dt,
       sls_due_dt
FROM   silver.crm_sales_details
WHERE  sls_order_dt > sls_ship_dt
       OR sls_order_dt > sls_due_dt;

-- ============================================================================
-- 7. Validate Sales Amount
-- ============================================================================
-- Identify NULL or invalid Sales Amount values in Bronze
SELECT sls_sales,
       sls_quantity,
       sls_price
FROM   bronze.crm_sales_details
WHERE  sls_sales <= 0
       OR sls_sales IS NULL;

-- Preview recalculated Sales Amount
SELECT sls_sales,
       CASE WHEN sls_sales <= 0
                 OR sls_sales IS NULL THEN sls_quantity * sls_price ELSE sls_sales END AS recalculated_sales,
       sls_quantity,
       sls_price
FROM   bronze.crm_sales_details
WHERE  sls_sales <= 0
       OR sls_sales IS NULL;

-- Verify Sales Amount in silver
SELECT sls_ord_num,
       sls_sales,
       sls_quantity,
       sls_price
FROM   silver.crm_sales_details
WHERE  sls_sales IS NULL
       OR sls_sales <= 0;

-- ============================================================================
-- 8. Validate Sales Quantity
-- ============================================================================
-- Identify NULL or negative Sales Quantity values in Bronze
SELECT sls_ord_num,
       sls_sales,
       sls_quantity,
       sls_price
FROM   bronze.crm_sales_details
WHERE  sls_quantity < 0
       OR sls_quantity IS NULL;

-- Verify Sales Quantity in silver
SELECT sls_ord_num,
       sls_quantity
FROM   silver.crm_sales_details
WHERE  sls_quantity < 0
       OR sls_quantity IS NULL;

-- ============================================================================
-- 9. Validate Unit Price
-- ============================================================================
-- Identify NULL or invalid Unit Price values in Bronze
SELECT sls_sales,
       sls_quantity,
       sls_price
FROM   bronze.crm_sales_details
WHERE  sls_price <= 0
       OR sls_price IS NULL;

-- Preview recalculated Unit Price
SELECT sls_sales,
       sls_quantity,
       sls_price,
       CASE WHEN sls_price <= 0
                 OR sls_price IS NULL THEN sls_sales / sls_quantity ELSE sls_price END AS recalculated_price
FROM   bronze.crm_sales_details
WHERE  sls_price <= 0
       OR sls_price IS NULL;

-- Verify Unit Price in silver
SELECT sls_ord_num,
       sls_price
FROM   silver.crm_sales_details
WHERE  sls_price <= 0
       OR sls_price IS NULL;

-- ============================================================================
-- 10. Final Data Inspection
-- ============================================================================
-- View all cleaned sales transaction records in silver
SELECT *
FROM   silver.crm_sales_details;
