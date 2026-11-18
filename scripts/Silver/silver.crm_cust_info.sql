/*
===============================================================================
    silver Layer - Load CRM Customer Information
===============================================================================

    Script Purpose:
        This script cleans and transforms customer data from the Bronze layer
        and loads the processed records into the silver layer.

    Transformations:
        1. Remove duplicate customer records using ROW_NUMBER().
        2. Exclude records with NULL Customer IDs.
        3. Remove leading and trailing spaces from customer names.
        4. Standardize Marital Status values:
           - S -> Single
           - M -> Married
           - Other values -> N/A
        5. Standardize Gender values:
           - F -> Female
           - M -> Male
           - Other values -> N/A

    Loading Strategy:
        - TRUNCATE the silver target table.
        - Insert the cleaned and transformed customer records.
        - Automatically populate the DWH creation date using DEFAULT.

    Validation:
        - Check for duplicate or NULL Customer IDs.
        - Verify duplicate resolution for individual customers.
        - Validate name trimming.
        - Verify standardized Gender and Marital Status values.

    Source:
        bronze.crm_cust_info

    Target:
        silver.crm_cust_info

===============================================================================
*/
-- ============================================================================
-- 1. Explore Source and Target Data
-- ============================================================================
-- View raw customer data from the Bronze layer
SELECT *
FROM   bronze.crm_cust_info;

-- View existing customer data in the silver layer
SELECT *
FROM   silver.crm_cust_info;

-- ============================================================================
-- 2. Load Cleaned Customer Data into silver Layer
-- ============================================================================
-- Remove existing records before reloading
TRUNCATE TABLE silver.crm_cust_info;

-- Insert transformed customer records
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT cst_id,
       cst_key,
       TRIM(cst_firstname) AS cst_firstname,
       TRIM(cst_lastname) AS cst_lastname,
       CASE UPPER(cst_marital_status) WHEN 'S' THEN 'Single' WHEN 'M' THEN 'Married' ELSE 'N/A' END AS cst_marital_status,
       CASE UPPER(cst_gndr) WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE 'N/A' END AS cst_gndr,
       cst_create_date
FROM   (SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS row_flag
        FROM   bronze.crm_cust_info
        WHERE  cst_id IS NOT NULL) AS t
WHERE  row_flag = 1;

-- ============================================================================
-- 3. Data Quality Checks
-- ============================================================================
-- Check for duplicate or NULL Customer IDs in Bronze
SELECT   cst_id,
         COUNT(*)
FROM     bronze.crm_cust_info
GROUP BY cst_id
HAVING   COUNT(*) > 1
         OR cst_id IS NULL;

-- Check for duplicate or NULL Customer IDs in silver
SELECT   cst_id,
         COUNT(*)
FROM     silver.crm_cust_info
GROUP BY cst_id
HAVING   COUNT(*) > 1
         OR cst_id IS NULL;

-- ============================================================================
-- 4. Validate Duplicate Removal
-- ============================================================================
-- Inspect duplicate customer records in Bronze
-- Verify that the latest record is selected
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)
FROM   bronze.crm_cust_info
WHERE  cst_id = 29466;

-- Verify the selected customer record in silver
SELECT *
FROM   silver.crm_cust_info
WHERE  cst_id = 29466;

-- ============================================================================
-- 5. Validate Customer Deduplication Logic
-- ============================================================================
-- Review the deduplicated customer records before insertion
SELECT cst_id,
       cst_key,
       cst_firstname,
       cst_lastname,
       cst_marital_status,
       cst_gndr,
       cst_create_date
FROM   (SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS row_flag
        FROM   bronze.crm_cust_info
        WHERE  cst_id IS NOT NULL) AS t
WHERE  row_flag = 1;

-- ============================================================================
-- 6. Validate Customer Name Standardization
-- ============================================================================
-- Identify customer names containing leading or trailing spaces
SELECT cst_firstname,
       cst_lastname
FROM   bronze.crm_cust_info
WHERE  cst_firstname <> TRIM(cst_firstname)
       OR cst_lastname <> TRIM(cst_lastname);

-- Verify trimmed customer names
SELECT TRIM(cst_firstname) AS cst_firstname,
       TRIM(cst_lastname) AS cst_lastname
FROM   bronze.crm_cust_info;

-- ============================================================================
-- 7. Validate Gender Standardization
-- ============================================================================
-- Inspect distinct Gender values in Bronze
SELECT DISTINCT cst_gndr
FROM   bronze.crm_cust_info;

-- Verify standardized Gender values in silver
SELECT DISTINCT cst_gndr
FROM   silver.crm_cust_info;

-- Preview Gender transformation mapping
SELECT DISTINCT cst_gndr,
                CASE UPPER(cst_gndr) WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE 'N/A' END AS standardized_gender
FROM   bronze.crm_cust_info;

-- ============================================================================
-- 8. Validate Marital Status Standardization
-- ============================================================================
-- Inspect distinct Marital Status values in Bronze
SELECT DISTINCT cst_marital_status
FROM   bronze.crm_cust_info;

-- Verify standardized Marital Status values in silver
SELECT DISTINCT cst_marital_status
FROM   silver.crm_cust_info;

-- Preview Marital Status transformation mapping
SELECT DISTINCT cst_marital_status,
                CASE UPPER(cst_marital_status) WHEN 'S' THEN 'Single' WHEN 'M' THEN 'Married' ELSE 'N/A' END AS standardized_marital_status
FROM   bronze.crm_cust_info;
