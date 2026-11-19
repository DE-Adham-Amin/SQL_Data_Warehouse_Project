# SQL Data Warehouse Project

A modern SQL Server data warehouse built with T-SQL, following the
**Medallion Architecture** (Bronze, Silver, and Gold) to integrate,
clean, transform, and prepare CRM and ERP data for analytics.

## Project Overview

This project demonstrates the design and implementation of an end-to-end
data warehouse using Microsoft SQL Server.

Data is ingested from CSV files belonging to two source systems (CRM and
ERP), processed through three architectural layers, and organized into a
dimensional model for analytical use.

## Architecture

The project follows the Medallion Architecture:

### Bronze Layer --- Raw Data

-   Loads source data from CRM and ERP CSV files into SQL Server.
-   Preserves raw data before applying transformations.
-   Uses stored procedures to manage the loading process.

### Silver Layer --- Cleaned and Standardized Data

-   Cleans and standardizes data from the Bronze layer.
-   Handles missing values and duplicates.
-   Applies data quality and consistency rules.
-   Loads transformed data into the Silver layer.

### Gold Layer --- Business-Ready Data

-   Organizes transformed data into a dimensional model.
-   Uses a Star Schema with dimension and fact views.
-   Prepares data for reporting and analytical queries.

## Data Sources

The project integrates data from two source systems:

  Source System   Format      Number of Files
  --------------- --------- -----------------
  CRM             CSV                       3
  ERP             CSV                       3
  **Total**       **CSV**               **6**

## Data Quality

SQL scripts are used to validate data across the warehouse layers,
including checks for:

-   Duplicate records.
-   Missing or NULL values.
-   Data consistency and standardization.
-   Referential integrity.
-   Dimension and fact data validity.

## Technology Stack

  Technology             Usage
  ---------------------- ------------------------------------------------
  Microsoft SQL Server   Relational database and data warehouse
  T-SQL                  Data ingestion, transformation, and validation
  Docker                 Running SQL Server in a container
  Visual Studio Code     SQL development
  Git & GitHub           Version control
  Draw.io                Architecture and data model diagrams

## Repository Contents

The repository contains SQL scripts for the Bronze, Silver, and Gold
layers, data quality checks, source datasets, and project documentation.

Refer to the repository folders for the exact scripts and diagrams.

## Current Scope

Implemented: - Bronze layer data loading. - Silver layer data cleaning
and transformation. - Gold layer dimensional modeling and analytical
views. - Silver and Gold data quality checks. - Data warehouse
documentation and diagrams.

Business analysis queries and reporting can be added as a subsequent
stage.

## Author

**Adham Amin Hassan**

Aspiring Data Engineer

-   GitHub: [DE-Adham-Amin](https://github.com/DE-Adham-Amin)
