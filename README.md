# SQL Server Projects

Welcome to my SQL Server Projects repository!
This repo contains SQL scripts, stored procedures, functions, views, and reporting queries that I’ve built to showcase my T-SQL, database design and data analysis skills.

## Projects Included
### 1. PAN Number Validation Project
**Objective:** Clean, validate, and categorize PAN numbers into Valid and Invalid.

#### Highlights:
Built scalar functions to check:
- Adjacent character repetition
- Sequential characters
- Designed a view (vw_valid_invalid_pans) to classify PAN numbers using rules:
- Format check ([A-Z]{5}[0-9]{4}[A-Z])
- No repeated or sequential characters
- Created a summary report with total valid/invalid/missing PANs.

#### Key SQL Skills Demonstrated
- Writing scalar functions for validation.
- Designing views for business logic encapsulation.
- Using CTEs for stepwise data processing.
- Applying CASE expressions for conditional outputs.
- JOINs.
- Creating summary reports with aggregations.
- Applying regular expressions with LIKE patterns for format validation.

#### Tech Stack
- SQL Server (T-SQL)
- Tools: SQL Server Management Studio (SSMS 21)
- SQL Server 16
