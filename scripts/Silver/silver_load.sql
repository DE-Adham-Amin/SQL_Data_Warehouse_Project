/*
    Stored Procedure: Load Silver Layer
    ====================================

    Script Purpose:
    This stored procedure loads cleaned and transformed data from the Bronze
    layer into the corresponding tables in the Silver layer.

    Loading Strategy:
    1. Truncate existing data from each Silver table.
    2. Transform and standardize raw Bronze data.
    3. Remove duplicates and handle missing or invalid values.
    4. Load cleaned data into Silver tables.
    5. Measure and display the loading duration for each table.
    6. Measure and display the total batch execution time.
    7. Handle errors using TRY...CATCH.

    Source Systems:
    - CRM (Customer Relationship Management)
    - ERP (Enterprise Resource Planning)

    Transformations:
    - Remove duplicate customer records.
    - Standardize customer names and attributes.
    - Standardize product categories and keys.
    - Validate sales amounts, prices, and dates.
    - Standardize customer IDs and demographic data.
    - Standardize country names.
    - Remove unwanted characters and spaces.

    Important Notes:
    - Existing Silver data is deleted before each load.
    - Data is transformed during the INSERT operation.
    - ROW_NUMBER() is used to identify the latest customer records.
    - LEAD() is used to calculate product end dates.
*/
USE DataWarehouse;


GO
-- =====================================================
-- Create Stored Procedure: silver.load_silver
-- =====================================================
CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    BEGIN TRY
        -- Declare variables for tracking execution time
        DECLARE @start_date AS DATETIME, @end_date AS DATETIME, @batch_start_time AS DATETIME, @batch_end_time AS DATETIME;
        -- =====================================================
        -- Start Silver Layer Loading
        -- =====================================================
        PRINT '=====================================================';
        PRINT '              SILVER LAYER LOADING                  ';
        PRINT '=====================================================';
        -- Record the batch start time
        SET @batch_start_time = GETDATE();
        -- =====================================================
        -- CRM SOURCE SYSTEM
        -- =====================================================
        PRINT '';
        PRINT '-----------------------------------------------------';
        PRINT '              LOADING CRM TABLES                     ';
        PRINT '-----------------------------------------------------';
        -- -----------------------------------------------------
        -- 1. Load CRM Customer Information
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: silver.crm_cust_info';
        -- Remove existing data before loading fresh data
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
               -- Standardize marital status
               CASE UPPER(cst_marital_status) WHEN 'S' THEN 'Single' WHEN 'M' THEN 'Married' ELSE 'N/A' END AS cst_marital_status,
               -- Standardize gender values
               CASE UPPER(cst_gndr) WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE 'N/A' END AS cst_gndr,
               cst_create_date
        FROM   (SELECT *,
                       ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS row_flag
                FROM   bronze.crm_cust_info
                WHERE  cst_id IS NOT NULL) AS t
        WHERE  row_flag = 1;
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 2. Load CRM Product Information
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: silver.crm_prd_info';
        -- Remove existing data before loading fresh data
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
               -- Standardize category ID
               REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
               -- Extract product key
               SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
               prd_nm,
               -- Replace NULL product costs with zero
               ISNULL(prd_cost, 0) AS prd_cost,
               -- Standardize product line
               CASE UPPER(TRIM(prd_line)) WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road' WHEN 'S' THEN 'Other Sales' WHEN 'T' THEN 'Touring' ELSE 'N/A' END AS prd_line,
               prd_start_dt,
               -- Calculate product end date based on the next start date
               DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
        FROM   bronze.crm_prd_info;
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 3. Load CRM Sales Details
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: silver.crm_sales_details';
        -- Remove existing data before loading fresh data
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
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- =====================================================
        -- ERP SOURCE SYSTEM
        -- =====================================================
        PRINT '';
        PRINT '-----------------------------------------------------';
        PRINT '              LOADING ERP TABLES                     ';
        PRINT '-----------------------------------------------------';
        -- -----------------------------------------------------
        -- 4. Load ERP Customer Information
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: silver.erp_cust_az12';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE silver.erp_cust_az12;
        -- Insert cleaned and standardized customer data
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT -- Remove NAS prefix from Customer ID when present
               CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID)) ELSE CID END AS cid,
               -- Replace future birthdates with NULL
               CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate,
               -- Remove Carriage Return and standardize Gender values
               CASE WHEN UPPER(TRIM(REPLACE(GEN, CHAR(13), ''))) IN ('M', 'MALE') THEN 'Male' WHEN UPPER(TRIM(REPLACE(GEN, CHAR(13), ''))) IN ('F', 'FEMALE') THEN 'Female' ELSE 'N/A' END AS gen
        FROM   bronze.erp_cust_az12;
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 5. Load ERP Customer Locations
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: silver.erp_loc_a101';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE silver.erp_loc_a101;
        -- Insert cleaned and standardized location data
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT -- Remove AW-000 prefix from Customer ID
               REPLACE(cid, 'AW-000', '') AS cid,
               -- Standardize country codes and handle missing values
               CASE WHEN TRIM(REPLACE(cntry, CHAR(13), '')) = 'DE' THEN 'Germany' WHEN TRIM(REPLACE(cntry, CHAR(13), '')) IN ('US', 'USA') THEN 'United States' WHEN TRIM(REPLACE(cntry, CHAR(13), '')) = ''
                                                                                                                                                                     OR TRIM(REPLACE(cntry, CHAR(13), '')) IS NULL THEN 'N/A' ELSE TRIM(REPLACE(cntry, CHAR(13), '')) END AS cntry
        FROM   bronze.erp_loc_a101;
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 6. Load ERP Product Categories
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: silver.erp_px_cat_g1v2';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        -- Insert cleaned product category data
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT id,
               cat,
               subcat,
               -- Remove Carriage Return characters and trim extra spaces
               TRIM(REPLACE(MAINTENANCE, CHAR(13), '')) AS maintenance
        FROM   bronze.erp_px_cat_g1v2;
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- =====================================================
        -- Batch Execution Summary
        -- =====================================================
        SET @batch_end_time = GETDATE();
        PRINT '';
        PRINT '=====================================================';
        PRINT '           SILVER LOADING SUMMARY                   ';
        PRINT '=====================================================';
        PRINT '   Status: SUCCESS';
        PRINT '   Total Execution Time: ' + CAST (DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' Seconds';
        PRINT '=====================================================';
        PRINT '          SILVER LAYER LOAD COMPLETED                ';
        PRINT '=====================================================';
    END TRY
    BEGIN CATCH
        -- =====================================================
        -- Error Handling
        -- =====================================================
        PRINT '';
        PRINT '=====================================================';
        PRINT '              SILVER LOADING FAILED                  ';
        PRINT '=====================================================';
        PRINT '   Error Message: ' + ERROR_MESSAGE();
        PRINT '   Error Number: ' + CAST (ERROR_NUMBER() AS VARCHAR);
        PRINT '   Error State: ' + CAST (ERROR_STATE() AS VARCHAR);
        PRINT '   Error Line: ' + CAST (ERROR_LINE() AS VARCHAR);
        PRINT '=====================================================';
    END CATCH
END
-- =====================================================
-- Execute Stored Procedure: silver.load_silver
-- =====================================================
EXECUTE silver.load_silver ;
