/*
    Stored Procedure: Load Bronze Layer
    ====================================

    Script Purpose:
    This stored procedure loads raw data from CRM and ERP CSV files
    into their corresponding tables in the Bronze layer.

    Loading Strategy:
    1. Truncate existing data from each Bronze table.
    2. Load fresh data using BULK INSERT.
    3. Measure and display the loading duration for each table.
    4. Measure and display the total batch execution time.
    5. Handle errors using TRY...CATCH.

    Source Systems:
    - CRM (Customer Relationship Management)
    - ERP (Enterprise Resource Planning)

    Important Notes:
    - Existing data is deleted before each load.
    - CSV files are accessed from the Docker container.
    - FIRSTROW = 2 skips the CSV header.
    - TABLOCK optimizes bulk insert operations.
*/
USE DataWarehouse;


GO
-- =====================================================
-- Create Stored Procedure: bronze.load_bronze
-- =====================================================
CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    BEGIN TRY
        -- Declare variables for tracking execution time
        DECLARE @start_date AS DATETIME, @end_date AS DATETIME, @batch_start_time AS DATETIME, @batch_end_time AS DATETIME;
        -- =====================================================
        -- Start Bronze Layer Loading
        -- =====================================================
        PRINT '=====================================================';
        PRINT '              BRONZE LAYER LOADING                  ';
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
        -- 1. Load CRM Sales Details
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: bronze.crm_sales_details';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE bronze.crm_sales_details;
        -- Load sales details from the source CSV file
        BULK INSERT bronze.crm_sales_details FROM '/var/opt/mssql/datasets/source_crm/sales_details.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 2. Load CRM Customer Information
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: bronze.crm_cust_info';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE bronze.crm_cust_info;
        -- Load customer information from the source CSV file
        BULK INSERT bronze.crm_cust_info FROM '/var/opt/mssql/datasets/source_crm/cust_info.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 3. Load CRM Product Information
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: bronze.crm_prd_info';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE bronze.crm_prd_info;
        -- Load product information from the source CSV file
        BULK INSERT bronze.crm_prd_info FROM '/var/opt/mssql/datasets/source_crm/prd_info.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
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
        -- 4. Load ERP Product Categories
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: bronze.erp_px_cat_g1v2';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        -- Load product categories from the source CSV file
        BULK INSERT bronze.erp_px_cat_g1v2 FROM '/var/opt/mssql/datasets/source_erp/PX_CAT_G1V2.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 5. Load ERP Customer Locations
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: bronze.erp_loc_a101';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE bronze.erp_loc_a101;
        -- Load customer locations from the source CSV file
        BULK INSERT bronze.erp_loc_a101 FROM '/var/opt/mssql/datasets/source_erp/loc_a101.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- -----------------------------------------------------
        -- 6. Load ERP Customer Information
        -- -----------------------------------------------------
        SET @start_date = GETDATE();
        PRINT '';
        PRINT '>> Loading Table: bronze.erp_cust_az12';
        -- Remove existing data before loading fresh data
        TRUNCATE TABLE bronze.erp_cust_az12;
        -- Load customer information from the source CSV file
        BULK INSERT bronze.erp_cust_az12 FROM '/var/opt/mssql/datasets/source_erp/cust_az12.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_date = GETDATE();
        PRINT '   Status: SUCCESS';
        PRINT '   Duration: ' + CAST (DATEDIFF(SECOND, @start_date, @end_date) AS VARCHAR) + ' Seconds';
        -- =====================================================
        -- Batch Execution Summary
        -- =====================================================
        SET @batch_end_time = GETDATE();
        PRINT '';
        PRINT '=====================================================';
        PRINT '           BRONZE LOADING SUMMARY                   ';
        PRINT '=====================================================';
        PRINT '   Status: SUCCESS';
        PRINT '   Total Execution Time: ' + CAST (DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' Seconds';
        PRINT '=====================================================';
        PRINT '          BRONZE LAYER LOAD COMPLETED                ';
        PRINT '=====================================================';
    END TRY
    BEGIN CATCH
        -- =====================================================
        -- Error Handling
        -- =====================================================
        PRINT '';
        PRINT '=====================================================';
        PRINT '              BRONZE LOADING FAILED                  ';
        PRINT '=====================================================';
        PRINT '   Error Message: ' + ERROR_MESSAGE();
        PRINT '   Error Number: ' + CAST (ERROR_NUMBER() AS VARCHAR);
        PRINT '   Error State: ' + CAST (ERROR_STATE() AS VARCHAR);
        PRINT '   Error Line: ' + CAST (ERROR_LINE() AS VARCHAR);
        PRINT '=====================================================';
    END CATCH
END
