/*
===============================================================================
    Silver Layer - ERP Product Category Data Cleaning
===============================================================================
    Purpose:
        Clean and load product category data from the Bronze Layer
        into the Silver Layer.

    Transformations:
        1. Remove unwanted Carriage Return characters from Maintenance.
        2. Trim leading and trailing spaces from Maintenance.

    Data Quality Checks:
        1. Check for duplicate and NULL Product IDs.
        2. Validate distinct Product Categories.
        3. Validate distinct Product Subcategories.
        4. Validate standardized Maintenance values.
===============================================================================
*/
-- ============================================================================
-- 1. Explore Source and Target Data
-- ============================================================================
-- Review raw product category data in Bronze Layer.
SELECT *
FROM   bronze.erp_px_cat_g1v2;

-- Review existing product category data in Silver Layer.
SELECT *
FROM   silver.erp_px_cat_g1v2;

-- ============================================================================
-- 2. Clean and Load Data into Silver Layer
-- ============================================================================
-- Clear existing Silver Layer data before reloading.
TRUNCATE TABLE silver.erp_px_cat_g1v2;

-- Insert cleaned product category data.
INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
SELECT id,
       cat,
       subcat,
       -- Remove Carriage Return characters and trim extra spaces.
       TRIM(REPLACE(MAINTENANCE, CHAR(13), '')) AS maintenance
FROM   bronze.erp_px_cat_g1v2;

-- ============================================================================
-- 3. Data Quality Checks
-- ============================================================================
-- ---------------------------------------------------------------------------
-- 3.1 Check for Duplicate and NULL Product IDs
-- ---------------------------------------------------------------------------
-- Identify duplicate or missing Product IDs.
SELECT   id,
         COUNT(*)
FROM     bronze.erp_px_cat_g1v2
GROUP BY id
HAVING   COUNT(*) > 1
         OR id IS NULL;

-- ---------------------------------------------------------------------------
-- 3.2 Validate Product Categories
-- ---------------------------------------------------------------------------
-- Review distinct product category values.
SELECT DISTINCT cat
FROM   bronze.erp_px_cat_g1v2;

-- ---------------------------------------------------------------------------
-- 3.3 Validate Product Subcategories
-- ---------------------------------------------------------------------------
-- Review distinct product subcategory values.
SELECT DISTINCT subcat
FROM   bronze.erp_px_cat_g1v2;

-- ---------------------------------------------------------------------------
-- 3.4 Validate Maintenance Standardization
-- ---------------------------------------------------------------------------
-- Review distinct maintenance values after removing unwanted characters.
SELECT DISTINCT TRIM(REPLACE(MAINTENANCE, CHAR(13), '')) AS maintenance
FROM   bronze.erp_px_cat_g1v2;
