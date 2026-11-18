/*
===============================================================================
    Create silver Layer Tables
===============================================================================

    Script Purpose:
        This script creates the source tables inside the silver schema
        of the DataWarehouse database.

    The silver layer stores raw data ingested from two source systems:
        1. CRM (Customer Relationship Management).
        2. ERP (Enterprise Resource Planning).

    Tables Created:

    CRM Tables:
        1. silver.crm_sales_details - Stores sales transaction details.
        2. silver.crm_cust_info     - Stores customer information.
        3. silver.crm_prd_info      - Stores product information.

    ERP Tables:
        4. silver.erp_px_cat_g1v2   - Stores product categories and subcategories.
        5. silver.erp_loc_a101      - Stores customer location information.
        6. silver.erp_cust_az12     - Stores additional customer information.

    WARNING:
        All existing CRM and ERP tables are dropped and recreated.
        This permanently deletes their existing data.

    Notes:
        1. All tables include a dwh_create_date column.
        2. The dwh_create_date column uses a DEFAULT constraint to
           automatically record the insertion timestamp.
        3. All tables are created without primary key constraints.

===============================================================================
*/
USE DataWarehouse;


GO
-- ============================================================================
-- CRM SOURCE TABLES
-- ============================================================================
-- ============================================================================
-- 1. Create CRM Sales Details Table
-- ============================================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;

-- Create the CRM Sales Details table
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR (50), -- Sales Order Number
    sls_prd_key     NVARCHAR (50), -- Product Key
    sls_cust_id     INT          , -- Customer ID
    sls_order_dt    DATE         , -- Order Date
    sls_ship_dt     DATE         , -- Shipping Date
    sls_due_dt      DATE         , -- Due Date
    sls_sales       INT          , -- Sales Amount
    sls_quantity    INT          , -- Quantity Sold
    sls_price       INT          , -- Unit Price
    dwh_create_date DATETIME2     DEFAULT GETDATE() -- Record Creation Date
);


GO
-- ============================================================================
-- 2. Create CRM Customer Information Table
-- ============================================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;

-- Create the CRM Customer Information table
CREATE TABLE silver.crm_cust_info (
    cst_id             INT          , -- Customer ID
    cst_key            NVARCHAR (50), -- Customer Business Key
    cst_firstname      NVARCHAR (50), -- Customer First Name
    cst_lastname       NVARCHAR (50), -- Customer Last Name
    cst_marital_status NVARCHAR (50), -- Customer Marital Status
    cst_gndr           NVARCHAR (50), -- Customer Gender
    cst_create_date    DATE         , -- Customer Creation Date
    dwh_create_date    DATETIME2     DEFAULT GETDATE() -- Record Creation Date
);


GO
-- ============================================================================
-- 3. Create CRM Product Information Table
-- ============================================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;

-- Create the CRM Product Information table
CREATE TABLE silver.crm_prd_info (
    prd_id          INT          , -- Product ID
    cat_id          NVARCHAR (50), -- Product Category ID
    prd_key         NVARCHAR (50), -- Product Business Key
    prd_nm          NVARCHAR (50), -- Product Name
    prd_cost        INT          , -- Product Cost
    prd_line        NVARCHAR (50), -- Product Line
    prd_start_dt    DATE         , -- Product Start Date
    prd_end_dt      DATE         , -- Product End Date
    dwh_create_date DATETIME2     DEFAULT GETDATE() -- Record Creation Date
);


GO
-- ============================================================================
-- ERP SOURCE TABLES
-- ============================================================================
-- ============================================================================
-- 4. Create ERP Product Category Table
-- ============================================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;

-- Create the ERP Product Category and Subcategory table
CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR (50), -- Product Category ID
    cat             NVARCHAR (50), -- Product Category
    subcat          NVARCHAR (50), -- Product Subcategory
    maintenance     NVARCHAR (50), -- Product Maintenance Information
    dwh_create_date DATETIME2     DEFAULT GETDATE() -- Record Creation Date
);


GO
-- ============================================================================
-- 5. Create ERP Location Table
-- ============================================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;

-- Create the ERP Customer Location table
CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR (50), -- Customer ID
    cntry           NVARCHAR (50), -- Customer Country
    dwh_create_date DATETIME2     DEFAULT GETDATE() -- Record Creation Date
);


GO
-- ============================================================================
-- 6. Create ERP Customer Information Table
-- ============================================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;

-- Create the ERP Customer Information table
CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR (50), -- Customer ID
    bdate           DATE         , -- Customer Birth Date
    gen             NVARCHAR (50), -- Customer Gender
    dwh_create_date DATETIME2     DEFAULT GETDATE() -- Record Creation Date
);
