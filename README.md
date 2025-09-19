# SQL Server Projects

Welcome to my SQL Server Projects repository!
This repo contains SQL scripts, stored procedures, functions, views, and reporting queries that I’ve built to showcase my database design, optimization, and data analysis skills.

## Projects Included
### 1. PAN Validation & Categorization
Objective: Clean, validate, and categorize PAN numbers into Valid and Invalid.

#### a. Highlights:
Built scalar functions to check:
- Adjacent character repetition
- Sequential characters
- Designed a view (vw_valid_invalid_pans) to classify PAN numbers using rules:
- Format check ([A-Z]{5}[0-9]{4}[A-Z])
- No repeated or sequential characters
- Created a summary report with total valid/invalid/missing PANs.

#### b. Custom Utility Functions
fn_check_adjacent_repetition → detects repeated side-by-side characters.
fn_check_sequence → detects strictly sequential characters.
fn_check_sequence_5 → enhanced function to detect 5+ consecutive characters.

#### c. Data Cleaning & Transformation
Used LTRIM(), RTRIM(), UPPER() for standardization.
Applied CTEs to modularize cleaning and validation logic.
Ensured handling of NULLs and empty strings.

#### Key SQL Skills Demonstrated
- Writing scalar functions for validation
- Designing views for business logic encapsulation
- Using CTEs for stepwise data processing
- Applying CASE expressions for conditional outputs
- Mastering JOINs
- Creating summary reports with aggregations
- Applying regular expressions with LIKE patterns for format validation

#### Tech Stack
- SQL Server (T-SQL)
- Database: pan_numbers_dataset_cleaned, pan_numbers_dataset
- Tools: SQL Server Management Studio (SSMS)
