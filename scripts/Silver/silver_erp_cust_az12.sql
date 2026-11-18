/*
===============================================================================
    silver Layer - ERP Customer Data Cleaning
===============================================================================
    Purpose:
        Clean and standardize customer data from the Bronze Layer
        before loading it into the silver Layer.

    Transformations:
        1. Remove NAS prefix from Customer IDs.
        2. Replace future birthdates with NULL.
        3. Standardize Gender values.
        4. Remove unwanted Carriage Return characters.

    Data Quality Checks:
        1. Validate Customer ID standardization.
        2. Validate Customer ID matching with CRM.
        3. Identify invalid birthdates.
        4. Validate Gender standardization.
        5. Identify unmatched Customer IDs.
===============================================================================
*/
-- ============================================================================
-- 1. Explore Source and Target Data
-- ============================================================================
-- Review raw customer data in the Bronze Layer.
SELECT *
FROM   bronze.erp_cust_az12;

-- Review existing customer data in the silver Layer.
SELECT *
FROM   silver.erp_cust_az12;

-- ============================================================================
-- 2. Clean and Load Data into silver Layer
-- ============================================================================
-- Clear existing silver Layer data before reloading.
TRUNCATE TABLE silver.erp_cust_az12;

-- Insert cleaned and standardized customer data.
INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)
SELECT -- Remove NAS prefix from Customer ID when present.
       CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID)) ELSE CID END AS cid,
       -- Replace future birthdates with NULL.
       CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate,
       -- Remove Carriage Return characters and standardize Gender values.
       CASE WHEN UPPER(TRIM(REPLACE(GEN, CHAR(13), ''))) IN ('M', 'MALE') THEN 'Male' WHEN UPPER(TRIM(REPLACE(GEN, CHAR(13), ''))) IN ('F', 'FEMALE') THEN 'Female' ELSE 'N/A' END AS gen
FROM   bronze.erp_cust_az12;

-- ============================================================================
-- 3. Data Quality Checks
-- ============================================================================
-- ---------------------------------------------------------------------------
-- 3.1 Validate Customer ID Standardization
-- ---------------------------------------------------------------------------
-- Check Customer IDs that do not contain the NAS prefix.
SELECT CID,
       CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID)) ELSE CID END AS CID
FROM   bronze.erp_cust_az12
WHERE  CID NOT LIKE 'NAS%';

-- ---------------------------------------------------------------------------
-- 3.2 Validate Customer ID Matching with CRM
-- ---------------------------------------------------------------------------
-- Identify Customer IDs that successfully match CRM customer records.
SELECT cst_key
FROM   silver.crm_cust_info
WHERE  cst_key IN (SELECT CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID)) ELSE CID END
                   FROM   bronze.erp_cust_az12);

-- ---------------------------------------------------------------------------
-- 3.3 Validate Birthdate Cleaning
-- ---------------------------------------------------------------------------
-- Identify future birthdates in the Bronze Layer.
SELECT bdate,
       CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate
FROM   bronze.erp_cust_az12
WHERE  bdate > GETDATE();

-- ---------------------------------------------------------------------------
-- 3.4 Validate Gender Standardization
-- ---------------------------------------------------------------------------
-- Review distinct standardized Gender values.
SELECT DISTINCT CASE WHEN UPPER(TRIM(REPLACE(GEN, CHAR(13), ''))) IN ('M', 'MALE') THEN 'Male' WHEN UPPER(TRIM(REPLACE(GEN, CHAR(13), ''))) IN ('F', 'FEMALE') THEN 'Female' ELSE 'N/A' END AS gen
FROM   bronze.erp_cust_az12;

-- ---------------------------------------------------------------------------
-- 3.5 Investigate Unwanted Characters in Source Data
-- ---------------------------------------------------------------------------
-- Identify hidden characters at the end of Gender values.
SELECT GEN,
       LEN(GEN) AS Len,
       UNICODE(RIGHT(GEN, 1)) AS LastCharacter
FROM   bronze.erp_cust_az12;

-- ---------------------------------------------------------------------------
-- 3.6 Identify Unmatched Customer IDs
-- ---------------------------------------------------------------------------
-- Find ERP customer records that have no matching CRM customer record.
SELECT *
FROM   silver.erp_cust_az12
WHERE  cid NOT IN (SELECT cst_key
                   FROM   silver.crm_cust_info);

-- ---------------------------------------------------------------------------
-- 3.7 Validate Birthdate Cleaning in silver Layer
-- ---------------------------------------------------------------------------
-- Ensure no future birthdates remain after transformation.
SELECT *
FROM   silver.erp_cust_az12
WHERE  bdate > GETDATE();

-- ---------------------------------------------------------------------------
-- 3.8 Validate Gender Standardization in silver Layer
-- ---------------------------------------------------------------------------
-- Ensure all Gender values belong to the approved categories.
SELECT *
FROM   silver.erp_cust_az12
WHERE  gen NOT IN ('Male', 'Female', 'N/A');

