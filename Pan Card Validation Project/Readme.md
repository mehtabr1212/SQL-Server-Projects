# PAN Number Validation Project

This project demonstrates how to clean, validate, and categorize Indian PAN (Permanent Account Number) data using SQL Server. It focuses on handling missing values, duplicates, formatting issues, and applying business rules to separate valid and invalid PAN numbers.

## Project Objectives
**1. Data Cleaning**
- Identify and remove missing PAN numbers.
- Handle duplicates.
- Trim leading/trailing spaces.
- Convert PAN numbers to uppercase.

**2. Data Validation**
- Check for adjacent character repetition.
- Check for sequential characters (like ABCDE or 1234).
- Ensure PAN follows the correct format: 
[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]

**3. Categorization**
- Classify PAN numbers into Valid PAN and Invalid PAN.

**4. Reporting**
- Provide a summary of total records processed, valid PANs, invalid PANs, and missing/incomplete entries.

## Steps Implemented
**1. Data Cleaning**
- Remove NULL and blank values.
- Remove duplicates.
- Apply trimming and case normalization.
- Store cleaned data in pan_numbers_dataset_cleaned.

**2. Functions**
- fn_check_adjacent_repetition: Detects repeated adjacent characters.
- fn_check_sequence: Detects sequential patterns in alphabets or numbers.

**3. Validation**
- Created a view vw_valid_invalid_pans to categorize PANs based on rules:
- No adjacent repetition.
- No sequential characters in first 5 letters or 4 digits.
- Matches the regex-like pattern: 5 letters + 4 digits + 1 letter

**4. Reporting**
- Generates a summary report with:
- Total processed records.
- Total valid PANs.
- Total invalid PANs.
- Missing/incomplete PANs.

## Example Output
**Categorized PANs (vw_valid_invalid_pans)**
**PAN Number**	    **Status**
ABRHX1259F	        Valid PAN
AADA18129X	       Invalid PAN
ADH5159	           Invalid PAN

**Summary Report**
Total Records	  Valid PANs	  Invalid PANs	 Missing/Incomplete
9033	             3186	         5839	              8

## Note
- This implementation assumes Indian PAN structure (10 characters: 5 letters + 4 digits + 1 letter).
