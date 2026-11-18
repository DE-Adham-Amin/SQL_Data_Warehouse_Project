/*
===============================================================================
    silver Layer - Load CRM Product Information
===============================================================================

    Script Purpose:
        This script cleans and transforms product data from the Bronze layer
        and loads the processed records into the silver layer.

    Transformations:
        1. Extract Category ID from Product Business Key.
        2. Replace '-' with '_' in Category ID.
        3. Extract Product Key by removing the category prefix.
        4. Handle NULL Product Costs by replacing them with 0.
        5. Standardize Product Line values:
           - M -> Mountain
           - R -> Road
           - S -> Other Sales
           - T -> Touring
           - Other values -> N/A
        6. Calculate Product End Date based on the next product start date.
        7. Remove one day from the next start date to determine the end date.

    Loading Strategy:
        - TRUNCATE the silver target table.
        - Insert cleaned and transformed product records.

    Validation:
        - Verify Category ID and Product Key extraction.
        - Check NULL and negative Product Costs.
        - Validate Product Name whitespace.
        - Verify Product Line standardization.
        - Validate Product Start and End Date calculations.
        - Check relationships with ERP categories and CRM sales.
        - Check duplicate Product IDs.
        - Validate data consistency in the silver layer.

    Source:
        bronze.crm_prd_info

    Target:
        silver.crm_prd_info

===============================================================================
*/
-- ============================================================================
-- 1. Explore Source Data and Related Tables
-- ============================================================================
-- View raw product information from Bronze
SELECT *
FROM   bronze.crm_prd_info;

-- Explore ERP product categories
SELECT *
FROM   bronze.erp_px_cat_g1v2
WHERE  ID IN (SELECT cat_id
              FROM   silver.crm_prd_info);

-- Explore CRM sales transactions related to products
SELECT *
FROM   bronze.crm_sales_details
WHERE  sls_prd_key IN (SELECT prd_key
                       FROM   silver.crm_prd_info);

-- ============================================================================
-- 2. Load Cleaned Product Data into silver Layer
-- ============================================================================
-- Remove existing records before reloading
TRUNCATE TABLE silver.crm_prd_info;

-- Insert transformed product records
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT prd_id,
       REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
       SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
       prd_nm,
       ISNULL(prd_cost, 0) AS prd_cost,
       CASE UPPER(TRIM(prd_line)) WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road' WHEN 'S' THEN 'Other Sales' WHEN 'T' THEN 'Touring' ELSE 'N/A' END AS prd_line,
       prd_start_dt,
       DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
FROM   bronze.crm_prd_info;

-- ============================================================================
-- 3. Validate Product Key and Category ID Extraction
-- ============================================================================
-- Verify Category ID and Product Key extraction in Bronze
SELECT prd_key,
       REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
       SUBSTRING(prd_key, 7, LEN(prd_key)) AS extracted_prd_key
FROM   bronze.crm_prd_info;

-- Check missing Category IDs in silver
SELECT *
FROM   silver.crm_prd_info
WHERE  cat_id IS NULL;

-- Check missing Product Keys in silver
SELECT *
FROM   silver.crm_prd_info
WHERE  prd_key IS NULL;

-- ============================================================================
-- 4. Validate Product Cost
-- ============================================================================
-- Identify NULL or negative Product Costs in Bronze
SELECT prd_id,
       prd_cost
FROM   bronze.crm_prd_info
WHERE  prd_cost IS NULL
       OR prd_cost < 0;

-- Verify Product Costs in silver
SELECT prd_id,
       prd_cost
FROM   silver.crm_prd_info
WHERE  prd_cost IS NULL
       OR prd_cost < 0;

-- ============================================================================
-- 5. Validate Product Name Standardization
-- ============================================================================
-- Identify Product Names containing leading or trailing spaces in Bronze
SELECT prd_id,
       prd_nm
FROM   bronze.crm_prd_info
WHERE  prd_nm <> TRIM(prd_nm);

-- Verify Product Names in silver
SELECT prd_id,
       prd_nm
FROM   silver.crm_prd_info
WHERE  prd_nm <> TRIM(prd_nm);

-- ============================================================================
-- 6. Validate Product Line Standardization
-- ============================================================================
-- Inspect distinct Product Line values in Bronze
SELECT DISTINCT prd_line
FROM   bronze.crm_prd_info;

-- Preview Product Line transformation mapping
SELECT DISTINCT prd_line,
                CASE UPPER(TRIM(prd_line)) WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road' WHEN 'S' THEN 'Other Sales' WHEN 'T' THEN 'Touring' ELSE 'N/A' END AS standardized_prd_line
FROM   bronze.crm_prd_info;

-- Verify standardized Product Line values in silver
SELECT DISTINCT prd_line
FROM   silver.crm_prd_info;

-- ============================================================================
-- 7. Validate Product Start and End Date Calculations
-- ============================================================================
-- Verify Product End Date calculation using LEAD()
SELECT prd_id,
       prd_key,
       prd_nm,
       prd_start_dt,
       DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt,
       prd_cost
FROM   bronze.crm_prd_info
WHERE  prd_key IN ('AC-HE-HL-U509', 'AC-HE-HL-U509-R');

-- Check invalid Product Date Ranges in silver
SELECT *
FROM   silver.crm_prd_info
WHERE  prd_end_dt < prd_start_dt;

-- Verify Product Start and End Dates in silver
SELECT   prd_id,
         prd_key,
         prd_start_dt,
         prd_end_dt
FROM     silver.crm_prd_info
ORDER BY prd_key, prd_start_dt;

-- ============================================================================
-- 8. Validate Product Relationships
-- ============================================================================
-- Identify products without matching ERP categories
SELECT *
FROM   silver.crm_prd_info AS p
WHERE  NOT EXISTS (SELECT 1
                   FROM   bronze.erp_px_cat_g1v2 AS c
                   WHERE  c.ID = p.cat_id);

-- Identify products without matching CRM sales transactions
SELECT *
FROM   silver.crm_prd_info AS p
WHERE  NOT EXISTS (SELECT 1
                   FROM   bronze.crm_sales_details AS s
                   WHERE  s.sls_prd_key = p.prd_key);

-- ============================================================================
-- 9. Validate Duplicate Product IDs
-- ============================================================================
-- Check duplicate Product IDs in silver
SELECT   prd_id,
         COUNT(*) AS duplicate_count
FROM     silver.crm_prd_info
GROUP BY prd_id
HAVING   COUNT(*) > 1;

-- ============================================================================
-- 10. Final Data Inspection
-- ============================================================================
-- View all cleaned product records in silver
SELECT *
FROM   silver.crm_prd_info;
