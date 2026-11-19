# SQL Data Warehouse Project

### Building a Modern Data Warehouse with SQL Server

[![SQL
Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-T--SQL-red?logo=microsoftsqlserver)](https://www.microsoft.com/en-us/sql-server)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion-blue)](#data-architecture)
[![Status](https://img.shields.io/badge/Project-In%20Progress-orange)](#project-status)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**An end-to-end Data Engineering project that integrates CRM and ERP
data into a structured SQL Server Data Warehouse.**
:::

------------------------------------------------------------------------

## 📌 Project Overview

This project focuses on building a modern data warehouse using
**Microsoft SQL Server** and **T-SQL**.

Data from two operational source systems --- **CRM** and **ERP** --- is
ingested from CSV files, cleaned, standardized, and transformed into a
business-ready dimensional model.

The solution follows the **Medallion Architecture**, separating the data
processing workflow into three layers:

-   **Bronze:** Raw data ingestion.
-   **Silver:** Data cleansing and standardization.
-   **Gold:** Business-ready dimensional modeling.

The goal is to create a reliable and organized foundation for future
analytical queries and reporting.

## 🏗️ Data Architecture

The warehouse is organized into three layers:

  -----------------------------------------------------------------------
  Layer                   Description             Main Responsibilities
  ----------------------- ----------------------- -----------------------
  **Bronze**              Raw data layer          Load source CSV files
                                                  into SQL Server while
                                                  preserving the original
                                                  data.

  **Silver**              Cleansed data layer     Clean, standardize,
                                                  validate, and prepare
                                                  data for integration.

  **Gold**                Business layer          Organize transformed
                                                  data into dimensions
                                                  and facts using a Star
                                                  Schema.
  -----------------------------------------------------------------------

### Data Flow

``` text
       Source Systems
       ┌─────────────┐       ┌─────────────┐
       │     CRM     │       │     ERP     │
       │  CSV Files  │       │  CSV Files  │
       └──────┬──────┘       └──────┬──────┘
              │                     │
              └──────────┬──────────┘
                         ▼
                ┌─────────────────┐
                │  BRONZE LAYER   │
                │    Raw Data     │
                └────────┬────────┘
                         ▼
                ┌─────────────────┐
                │  SILVER LAYER   │
                │ Clean & Prepare │
                └────────┬────────┘
                         ▼
                ┌─────────────────┐
                │   GOLD LAYER    │
                │  Star Schema    │
                └────────┬────────┘
                         ▼
                ┌─────────────────┐
                │ Analytics-Ready │
                │      Data       │
                └─────────────────┘
```

## 🎯 Project Objectives & Requirements

### Data Engineering

-   **Data Integration:** Combine data from CRM and ERP source systems.
-   **Data Quality:** Identify and handle missing, duplicate, and
    inconsistent records.
-   **Data Transformation:** Clean and standardize data using T-SQL.
-   **Data Modeling:** Build a dimensional model using fact and
    dimension views.
-   **Documentation:** Document the architecture, data flow, and data
    model.

### Data Sources

The project uses six CSV files from two source systems:

  Source System     Files Description
  --------------- ------- -----------------------------------------------
  CRM                   3 Customer, product, and sales-related data
  ERP                   3 Customer, location, and product-category data
  **Total**         **6** **Source CSV files**

## ⚙️ Data Pipeline

### 1. Bronze Layer --- Raw Ingestion

-   Create the Bronze schema and source tables.
-   Load raw CSV data into SQL Server.
-   Keep source values unchanged during ingestion.
-   Use stored procedures to organize the loading process.

### 2. Silver Layer --- Cleaning & Transformation

-   Create the Silver schema and tables.
-   Remove duplicate records.
-   Handle NULL and invalid values.
-   Standardize text fields and categorical values.
-   Validate and transform dates and other data attributes.
-   Integrate related CRM and ERP data.

### 3. Gold Layer --- Dimensional Modeling

-   Create business-oriented views.
-   Separate descriptive attributes into dimensions.
-   Organize measurable business events into fact data.
-   Apply a Star Schema design to support analytical workloads.

## ⭐ Data Modeling

The Gold layer follows a **Star Schema** approach.

The model separates data into:

-   **Dimension Views:** Provide descriptive context for business
    entities, such as customers and products.
-   **Fact Views:** Store measurable business events and metrics, such
    as sales.

This structure makes analytical queries easier to understand and
maintain.

## 🔍 Data Quality Checks

Dedicated SQL scripts validate the quality of the transformed data.

Checks cover areas such as:

-   Duplicate records.
-   NULL and missing values.
-   Invalid or inconsistent values.
-   Data standardization.
-   Dimension key uniqueness.
-   Fact-to-dimension relationships.

Quality checks are maintained for both the Silver and Gold layers.

## 📂 Repository Structure

``` text
SQL_Data_Warehouse_Project/
│
├── datasets/                 # CRM and ERP source CSV files
│
├── docs/                     # Project documentation and diagrams
│
├── scripts/
│   ├── bronze/               # Raw data ingestion scripts
│   ├── silver/               # Data cleaning and transformation
│   └── gold/                 # Dimensional modeling and views
│
├── tests/
│   ├── quality_checks_silver.sql
│   └── quality_checks_gold.sql
│
├── README.md
└── LICENSE
```

## 🛠️ Tools & Technologies

  -----------------------------------------------------------------------
  Tool / Technology                   Purpose
  ----------------------------------- -----------------------------------
  **Microsoft SQL Server**            Database engine and data warehouse

  **T-SQL**                           Data definition, ingestion,
                                      transformation, and validation

  **Docker**                          Running SQL Server in a
                                      containerized environment

  **Visual Studio Code**              SQL development and script
                                      management

  **DBeaver**                         Database connection and query
                                      execution

  **Git & GitHub**                    Version control and project
                                      collaboration

  **Draw.io**                         Data architecture and modeling
                                      diagrams
  -----------------------------------------------------------------------

## 🚀 Getting Started

### Prerequisites

Before running the project, make sure you have:

-   Docker installed.
-   A running Microsoft SQL Server instance.
-   Visual Studio Code or another SQL editor.
-   Git installed.

### Run the Project

1.  Clone this repository:

    ``` bash
    git clone https://github.com/DE-Adham-Amin/SQL_Data_Warehouse_Project.git
    ```

2.  Open the project folder in your SQL editor.

3.  Make sure your SQL Server container is running and connect to your
    SQL Server instance.

4.  Execute the SQL scripts in the following order:

    ``` text
    Bronze → Silver → Gold
    ```

5.  Run the corresponding data quality scripts from the `tests/` folder
    to validate the loaded data.

> **Note:** Make sure the source file paths in the Bronze loading
> scripts match the location of the CSV files on your machine.

## 📈 Project Status

  Component                      Status
  ------------------------------ -------------
  Bronze Layer                   Completed
  Silver Layer                   Completed
  Gold Layer                     Completed
  Silver Data Quality Checks     Completed
  Gold Data Quality Checks       Completed
  Data Warehouse Documentation   In Progress

This repository focuses on the data warehouse implementation. Business
analysis queries and dashboards are not included in the current scope.

## 📚 Key Concepts Practiced

-   Relational Database Design
-   Data Warehousing Fundamentals
-   ETL Processes
-   Medallion Architecture
-   Data Cleaning & Transformation
-   Data Quality Validation
-   Dimensional Modeling
-   Star Schema
-   SQL Server Stored Procedures
-   Version Control with Git

## 👨‍💻 Author

**Adham Amin Hassan**

Aspiring Data Engineer

-   GitHub: [DE-Adham-Amin](https://github.com/DE-Adham-Amin)

## 📄 License

This project is licensed under the MIT License. See the
[LICENSE](LICENSE) file for details.

------------------------------------------------------------------------

::: {align="center"}
**Built as part of my journey toward becoming a Data Engineer.**
:::
