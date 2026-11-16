/*
    Create Bronze Layer Tables
    ==========================

    Script Purpose:
    This script creates the source tables inside the Bronze schema
    of the DataWarehouse database.

    The Bronze layer stores raw data ingested from two source systems:
    1. CRM (Customer Relationship Management).
    2. ERP (Enterprise Resource Planning).

    Tables Created:

    CRM Tables:
    1. bronze.crm_sales_details - Stores sales transaction details.
    2. bronze.crm_cust_info     - Stores customer information.
    3. bronze.crm_prd_info      - Stores product information.

    ERP Tables:
    4. bronze.erp_px_cat_g1v2   - Stores product categories and subcategories.
    5. bronze.erp_loc_a101      - Stores customer location information.
    6. bronze.erp_cust_az12     - Stores additional customer information.

    WARNING:
    The CRM tables are dropped and recreated if they already exist.
    This permanently deletes their existing data.

    Note:
    The ERP tables are currently created without existence checks.
*/
USE DataWarehouse;


GO
-- =====================================================
-- CRM SOURCE TABLES
-- =====================================================
-- =====================================================
-- 1. Create CRM Sales Details Table
-- =====================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

-- Create the CRM Sales Details table
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR (50), -- Sales Order Number
    sls_prd_key  NVARCHAR (50), -- Product Key
    sls_cust_id  INT          , -- Customer ID
    sls_order_dt INT          , -- Order Date
    sls_ship_dt  INT          , -- Shipping Date
    sls_due_dt   INT          , -- Due Date
    sls_sales    INT          , -- Sales Amount
    sls_quantity INT          , -- Quantity Sold
    sls_price    INT           -- Unit Price
);


GO
-- =====================================================
-- 2. Create CRM Customer Information Table
-- =====================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

-- Create the CRM Customer Information table
CREATE TABLE bronze.crm_cust_info (
    cst_id             INT          , -- Customer ID
    cst_key            NVARCHAR (50), -- Customer Business Key
    cst_firstname      NVARCHAR (50), -- Customer First Name
    cst_lastname       NVARCHAR (50), -- Customer Last Name
    cst_marital_status NVARCHAR (50), -- Customer Marital Status
    cst_gndr           NVARCHAR (50), -- Customer Gender
    cst_create_date    DATE          -- Customer Creation Date
);


GO
-- =====================================================
-- 3. Create CRM Product Information Table
-- =====================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

-- Create the CRM Product Information table
CREATE TABLE bronze.crm_prd_info (
    prd_id       INT          , -- Product ID
    prd_key      NVARCHAR (50), -- Product Business Key
    prd_nm       NVARCHAR (50), -- Product Name
    prd_cost     INT          , -- Product Cost
    prd_line     NVARCHAR (50), -- Product Line
    prd_start_dt DATE         , -- Product Start Date
    prd_end_dt   DATE          -- Product End Date
);


GO
-- =====================================================
-- ERP SOURCE TABLES
-- =====================================================
-- =====================================================
-- 4. Create ERP Product Category Table
-- =====================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;

-- Create the ERP Product Category and Subcategory table
CREATE TABLE bronze.erp_px_cat_g1v2 (
    ID          NVARCHAR (50), -- Product Category ID
    CAT         NVARCHAR (50), -- Product Category
    SUBCAT      NVARCHAR (50), -- Product Subcategory
    MAINTENANCE NVARCHAR (50) -- Product Maintenance Information
);


GO
-- =====================================================
-- 5. Create ERP Location Table
-- =====================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;

-- Create the ERP Customer Location table
CREATE TABLE bronze.erp_loc_a101 (
    CID   NVARCHAR (50), -- Customer ID
    CNTRY NVARCHAR (50) -- Customer Country
);


GO
-- =====================================================
-- 6. Create ERP Customer Information Table
-- =====================================================
-- Check if the table already exists and drop it if it does
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;

-- Create the ERP Customer Information table
CREATE TABLE bronze.erp_cust_az12 (
    CID   NVARCHAR (50), -- Customer ID
    BDATE DATE         , -- Customer Birth Date
    GEN   NVARCHAR (50) -- Customer Gender
);
