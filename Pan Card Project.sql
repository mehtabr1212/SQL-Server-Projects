select * from dbo.pan_number_validation_dataset;
---------------------------------------------------
---------------------------------------------------
-- 1. Identify missing data
---------------------------------------------------
SELECT * 
FROM dbo.pan_number_validation_dataset
WHERE pan_numbers IS NULL;

---------------------------------------------------
-- 2. Check for duplicates
---------------------------------------------------
SELECT pan_numbers, COUNT(*) AS cnt
FROM dbo.pan_number_validation_dataset
WHERE pan_numbers IS NOT NULL
GROUP BY pan_numbers
HAVING COUNT(*) > 1;

-- Distinct values
SELECT DISTINCT * 
FROM dbo.pan_number_validation_dataset;

---------------------------------------------------
-- 3. Handle leading/trailing spaces
---------------------------------------------------
SELECT *
FROM dbo.pan_number_validation_dataset
WHERE pan_numbers <> LTRIM(RTRIM(pan_numbers));
---------------------------------------------------
-- 4. Correct letter case
---------------------------------------------------
SELECT *
FROM dbo.pan_number_validation_dataset
WHERE pan_numbers <> UPPER(pan_numbers);
---------------------------------------------------
-- Cleaned table --
---------------------------------------------------
IF OBJECT_ID('pan_numbers_dataset_cleaned') IS NOT NULL
    DROP TABLE pan_numbers_dataset_cleaned;

SELECT DISTINCT UPPER(LTRIM(RTRIM(pan_numbers))) AS pan_number
INTO pan_numbers_dataset_cleaned
FROM dbo.pan_number_validation_dataset
WHERE pan_numbers IS NOT NULL
  AND LTRIM(RTRIM(pan_numbers)) <> '';

select * from pan_numbers_dataset_cleaned

---------------------------------------------------
-- Function: check adjacent repetition
---------------------------------------------------
CREATE OR ALTER FUNCTION fn_check_adjacent_repetition (@p_str NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @i INT = 1, @len INT, @result BIT = 0;
    SET @len = LEN(@p_str);

    WHILE @i < @len
    BEGIN
        IF SUBSTRING(@p_str, @i, 1) = SUBSTRING(@p_str, @i+1, 1)
        BEGIN
            SET @result = 1;
            BREAK;
        END
        SET @i += 1;
    END
    RETURN @result;
END;

---------------------------------------------------
-- Function: check sequential characters
---------------------------------------------------
CREATE OR ALTER FUNCTION fn_check_sequence (@p_str NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @i INT = 1, @len INT, @result BIT = 1;
    SET @len = LEN(@p_str);

    WHILE @i < @len
    BEGIN
        IF ASCII(SUBSTRING(@p_str, @i+1, 1)) - ASCII(SUBSTRING(@p_str, @i, 1)) <> 1
        BEGIN
            SET @result = 0;
            BREAK;
        END
        SET @i += 1;
    END
    RETURN @result;
END;

---------------------------------------------------
-- Valid / Invalid PAN categorization
---------------------------------------------------
CREATE OR ALTER VIEW vw_valid_invalid_pans
AS
WITH cte_cleaned_pan AS
(
    SELECT DISTINCT UPPER(LTRIM(RTRIM(pan_number))) AS pan_number
    FROM pan_numbers_dataset_cleaned
    WHERE pan_number IS NOT NULL AND LTRIM(RTRIM(pan_number)) <> ''
),
cte_valid_pan AS
(
    SELECT * FROM cte_cleaned_pan
    WHERE dbo.fn_check_adjacent_repetition(pan_number) = 0
      AND dbo.fn_check_sequence(SUBSTRING(pan_number, 1, 5)) = 0   --For First 5 Alphabets
      AND dbo.fn_check_sequence(SUBSTRING(pan_number, 6, 4)) = 0   --For 4 Numbers
      AND pan_number LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]'
)
SELECT cln.pan_number,
       CASE WHEN vld.pan_number IS NULL 
            THEN 'Invalid PAN'
            ELSE 'Valid PAN'
       END AS status
FROM cte_cleaned_pan cln
LEFT JOIN cte_valid_pan vld
ON vld.pan_number = cln.pan_number;

---------------------------------------------------
-- Summary Report
---------------------------------------------------
WITH cte AS
(
    SELECT 
        (SELECT COUNT(*) FROM PAN_Number_Validation_Dataset) AS total_processed_records,
        SUM(CASE WHEN vw.status = 'Valid PAN' THEN 1 ELSE 0 END) AS total_valid_pans,
        SUM(CASE WHEN vw.status = 'Invalid PAN' THEN 1 ELSE 0 END) AS total_invalid_pans
    FROM vw_valid_invalid_pans vw
)
SELECT total_processed_records,
       total_valid_pans,
       total_invalid_pans,
       total_processed_records - (total_valid_pans + total_invalid_pans) AS missing_incomplete_PANS
FROM cte;