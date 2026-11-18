/*
===============================================================================
    Silver Layer - ERP Customer Location Data Cleaning
===============================================================================
    Purpose:
        Clean and standardize customer location data from the Bronze Layer.
    Transformations:
        1. Remove AW-000 prefix from Customer IDs.
        2. Remove unwanted Carriage Return characters.
        3. Standardize country codes into full country names.
        4. Handle NULL and empty country values.
    Data Quality Checks:
        1. Check for duplicate and NULL Customer IDs.
        2. Validate Customer ID standardization.
        3. Validate Customer ID matching with CRM.
        4. Validate country standardization.
        5. Identify unmatched Customer IDs.
        6. Check for invalid country values.
===============================================================================
*/
-- ============================================================================
-- 1. Explore Source and Target Data
-- ============================================================================
-- Review raw customer location data in Bronze Layer.
SELECT *
FROM   bronze.erp_loc_a101;

-- Review existing customer location data in Silver Layer.
SELECT *
FROM   silver.erp_loc_a101;

-- ============================================================================
-- 2. Clean and Load Data into Silver Layer
-- ============================================================================
-- Clear existing Silver Layer data before reloading.
TRUNCATE TABLE silver.erp_loc_a101;

-- Insert cleaned and standardized location data.
INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
SELECT -- Remove AW-000 prefix from Customer ID.
       REPLACE(cid, 'AW-000', '') AS cid,
       -- Standardize country codes and handle missing values.
       CASE WHEN TRIM(REPLACE(cntry, CHAR(13), '')) = 'DE' THEN 'Germany' WHEN TRIM(REPLACE(cntry, CHAR(13), '')) IN ('US', 'USA') THEN 'United States' WHEN TRIM(REPLACE(cntry, CHAR(13), '')) = ''
                                                                                                                                                             OR TRIM(REPLACE(cntry, CHAR(13), '')) IS NULL THEN 'N/A' ELSE TRIM(REPLACE(cntry, CHAR(13), '')) END AS cntry
FROM   bronze.erp_loc_a101;

-- ============================================================================
-- 3. Data Quality Checks
-- ============================================================================
-- ---------------------------------------------------------------------------
-- 3.1 Check for Duplicate and NULL Customer IDs
-- ---------------------------------------------------------------------------
-- Identify duplicate Customer IDs and missing IDs.
SELECT   cid,
         COUNT(*)
FROM     bronze.erp_loc_a101
GROUP BY cid
HAVING   COUNT(*) > 1
         OR cid IS NULL;

-- ---------------------------------------------------------------------------
-- 3.2 Validate Customer ID Standardization
-- ---------------------------------------------------------------------------
-- Review Customer IDs after removing the AW-000 prefix.
SELECT REPLACE(cid, 'AW-000', '') AS cid
FROM   bronze.erp_loc_a101;

-- ---------------------------------------------------------------------------
-- 3.3 Validate Customer ID Matching with CRM
-- ---------------------------------------------------------------------------
-- Identify Customer IDs that successfully match CRM records.
SELECT cst_id
FROM   silver.crm_cust_info
WHERE  cst_id IN (SELECT REPLACE(cid, 'AW-000', '')
                  FROM   bronze.erp_loc_a101);

-- ---------------------------------------------------------------------------
-- 3.4 Validate Country Standardization
-- ---------------------------------------------------------------------------
-- Review distinct original country values and their standardized versions.
SELECT DISTINCT TRIM(REPLACE(cntry, CHAR(13), '')) AS cntry,
                CASE WHEN TRIM(REPLACE(cntry, CHAR(13), '')) = 'DE' THEN 'Germany' WHEN TRIM(REPLACE(cntry, CHAR(13), '')) IN ('US', 'USA') THEN 'United States' WHEN TRIM(REPLACE(cntry, CHAR(13), '')) = ''
                                                                                                                                                                      OR TRIM(REPLACE(cntry, CHAR(13), '')) IS NULL THEN 'N/A' ELSE TRIM(REPLACE(cntry, CHAR(13), '')) END AS standardized_country
FROM   bronze.erp_loc_a101;

-- ---------------------------------------------------------------------------
-- 3.5 Identify Unmatched Customer IDs
-- ---------------------------------------------------------------------------
-- Find CRM customers that do not have a matching ERP location record.
SELECT cst_id
FROM   silver.crm_cust_info
WHERE  cst_id NOT IN (SELECT cid
                      FROM   silver.erp_loc_a101);

-- ---------------------------------------------------------------------------
-- 3.6 Validate Country Values in Silver Layer
-- ---------------------------------------------------------------------------
-- Ensure all country values belong to the approved list.
SELECT *
FROM   silver.erp_loc_a101
WHERE  cntry NOT IN ('Australia', 'United Kingdom', 'France', 'Canada', 'Germany', 'United States', 'N/A');
