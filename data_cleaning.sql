
--- Data Ceaning for HealthCare Patient Records

-- Copy all data from patient_records into a new table patient_records_clean
SELECT *
INTO patient_records_clean
FROM patient_records;


-- Replace missing or blank patient names with 'Not Registered'
UPDATE patient_records_clean
SET [Patient Name] = 'Not Registered'
WHERE [Patient Name] IS NULL
   OR LTRIM(RTRIM([Patient Name])) = '';


  CREATE FUNCTION dbo.ProperCase(@Input VARCHAR(8000))
RETURNS VARCHAR(8000)
AS
BEGIN
    DECLARE @Index INT = 1
    DECLARE @Result VARCHAR(8000) = LOWER(@Input)

    WHILE @Index <= LEN(@Result)
    BEGIN
        -- Capitalize first letter and any letter after a space
        IF @Index = 1 OR SUBSTRING(@Result, @Index - 1, 1) = ' '
            SET @Result = STUFF(@Result, @Index, 1, UPPER(SUBSTRING(@Result, @Index, 1)))
        SET @Index = @Index + 1
    END

    RETURN @Result
END

-- Capitalize the first letter of each word in Patient Name
UPDATE patient_records_clean
SET [Patient Name] = dbo.ProperCase([Patient Name])
WHERE [Patient Name] IS NOT NULL;

-- Capitalize the first letter of each word in Gender
UPDATE patient_records_clean
SET [Gender] = dbo.ProperCase([Gender])
WHERE [Gender] IS NOT NULL;

--Replacing empty spaces to unknown
UPDATE patient_records_clean
SET [Gender] = 'Unknown'
WHERE [Gender] IS NULL
   OR LTRIM(RTRIM([Gender])) = '';

-- Clean up whitespace in Patient Name, Address, and Department
UPDATE patient_records_clean
SET 
    [Patient Name] = LTRIM(RTRIM([Patient Name])),
    [Address] = LTRIM(RTRIM([Address])),
    [Department] = LTRIM(RTRIM([Department]));

-- Standardize Department names (replace abbreviations with full names)
UPDATE patient_records_clean
SET Department =
CASE 
    WHEN Department IN ('ER', 'Emerg.') THEN 'Emergency'
    WHEN Department = 'Cardio' THEN 'Cardiology'
    WHEN Department = 'Ortho' THEN 'Orthopedics'
    ELSE Department
END;

-- Correct typos in Diagnosis column
UPDATE patient_records_clean
SET Diagnosis =
CASE 
    WHEN Diagnosis = 'Typhod' THEN 'Typhoid'
    WHEN Diagnosis = 'Diabetis' THEN 'Diabetes'
    ELSE Diagnosis
END;

-- Remove duplicate patient records, keeping only the first occurrence
WITH cte AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY [Patient ID], [Patient Name]
        ORDER BY [Patient ID]
    ) AS rn
    FROM patient_records_clean
)
DELETE FROM cte WHERE rn > 1;

SELECT 
    [Treatment Cost],
    LEFT([Treatment Cost], CHARINDEX(' ', [Treatment Cost]) - 1) AS Cost_Value,
    RIGHT([Treatment Cost], 3) AS Currency
FROM patient_records_clean;

-- Convert Treatment Cost and Billing Amount from local currency to USD
CREATE TABLE exchange_rates (
    Currency VARCHAR(3),
    Rate FLOAT
);

INSERT INTO exchange_rates VALUES
('NGN', 0.00073),
('USD', 1),
('GBP', 1.27);

SELECT 
    p.*,
    CAST(LEFT(p.[Treatment Cost], CHARINDEX(' ', p.[Treatment Cost]) - 1) AS FLOAT) * e.Rate AS TreamentCost_USD
FROM patient_records_clean p
LEFT JOIN exchange_rates e
ON RIGHT(p.[Treatment Cost], 3) = e.Currency;

SELECT 
    p.*,
    CAST(LEFT(p.[Treatment Cost], CHARINDEX(' ', p.[Treatment Cost]) - 1) AS FLOAT) * e.Rate AS TreatmentCost_USD
FROM patient_records_clean p
LEFT JOIN exchange_rates e
ON RIGHT(p.[Treatment Cost], 3) = e.Currency;

---changing all currencies to USD
UPDATE p
SET BillingAmount_USD =
    CAST(LEFT(p.[Billing Amount], CHARINDEX(' ', p.[Billing Amount]) - 1) AS FLOAT) * e.Rate
FROM patient_records_clean p
LEFT JOIN exchange_rates e
ON RIGHT(p.[Billing Amount], 3) = e.Currency;

ALTER TABLE patient_records_clean
ADD TreatmentCost_USD FLOAT;

UPDATE p
SET TreatmentCost_USD =
    CAST(LEFT(p.[Treatment Cost], CHARINDEX(' ', p.[Treatment Cost]) - 1) AS FLOAT) * e.Rate
FROM patient_records_clean p
JOIN exchange_rates e
ON RIGHT(p.[Treatment Cost], 3) = e.Currency;
 
 -- Standardize Admission Date and Discharge Date into proper DATE format
 ALTER TABLE patient_records_clean
ADD CleanAdmissionDate DATE;

UPDATE patient_records_clean
SET CleanAdmissionDate =
    CASE 
        WHEN ISNUMERIC([Admission Date]) = 1 
            THEN DATEADD(DAY, CAST([Admission Date] AS INT), '1899-12-30')
        ELSE 
            TRY_CAST([Admission Date] AS DATE)
    END;

 ALTER TABLE patient_records_clean
ADD CleanDischargeDate DATE;

UPDATE patient_records_clean
SET CleanDischargeDate =
    CASE 
        WHEN ISNUMERIC([Discharge Date]) = 1 
            THEN DATEADD(DAY, CAST([Discharge Date] AS INT), '1899-12-30')
        ELSE 
            TRY_CAST([Discharge Date] AS DATE)
    END;

  -- Standardize Phone Numbers: keep only digits, remove all other characters, preserve NULLs
ALTER TABLE patient_records_clean
ADD PhoneDigits VARCHAR(50);

UPDATE patient_records_clean
SET PhoneDigits = 
    CASE 
        WHEN [Phone Number] IS NOT NULL THEN
            REGEXP_REPLACE(CAST([Phone Number] AS VARCHAR(50)), '[^0-9]', '')
        ELSE NULL
    END;

 -- Clean Email column: replace invalid or missing emails with 'Not Provided'
UPDATE patient_records_clean
SET [Email] = 'Not Provided'
WHERE [Email] IS NULL
   OR [Email] NOT LIKE '%@%';

-- Replace NULL values in PhoneDigits with 'Not Provided'
UPDATE patient_records_clean
SET PhoneDigits = 'Not Provided'
WHERE PhoneDigits IS NULL;

-- Restore the Medication Prescribed column (empty or from backup)
WITH CTE AS (
    SELECT *,
           LEAD([Medication Prescribed]) OVER (ORDER BY [Patient ID]) AS NextMedication
    FROM patient_records_clean
)
UPDATE p
SET Medication_Clean = 
    CASE 
        WHEN p.[Medication Prescribed] IS NULL THEN cte.NextMedication
        ELSE p.[Medication Prescribed]
    END
FROM patient_records_clean p
JOIN CTE cte
  ON p.[Patient ID] = cte.[Patient ID];

  WITH CTE AS (
    SELECT *,
           LEAD([Medication Prescribed]) OVER (ORDER BY [Patient ID]) AS NextMedication
    FROM patient_records_clean
)

  UPDATE patient_records_clean
SET [Address] = 'Not Provided'
WHERE [Address] IS NULL
   OR LTRIM(RTRIM([Address])) = '';

  UPDATE patient_records_clean
SET [PhoneDigits] = 'Not Provided'
WHERE [PhoneDigits] IS NULL
   OR LTRIM(RTRIM([Address])) = '';

   WITH DeptAvg AS (
    SELECT Department, AVG(CAST(Age AS FLOAT)) AS AvgAge
    FROM patient_records_clean
    WHERE Age IS NOT NULL
    GROUP BY Department
)
UPDATE p
SET p.Age = ROUND(d.AvgAge, 0)  -- round to nearest integer
FROM patient_records_clean p
JOIN DeptAvg d
  ON p.Department = d.Department
WHERE p.Age IS NULL;

-- Backward fill NULL values in Diagnosis using next row value
WITH CTE AS (
    SELECT 
        [Patient ID],
        [Diagnosis],
        LEAD([Diagnosis]) OVER (ORDER BY [Patient ID]) AS NextDiagnosis
    FROM patient_records_clean
)
UPDATE p
SET Diagnosis_Clean =
    CASE 
        WHEN p.[Diagnosis] IS NULL THEN cte.NextDiagnosis
        ELSE p.[Diagnosis]
    END
FROM patient_records_clean p
JOIN CTE cte
  ON p.[Patient ID] = cte.[Patient ID];

ALTER TABLE patient_records_clean
Drop column [Insurance Provider]

-- Backward fill NULL values in Insurance Provider using next row value
WITH CTE AS (
    SELECT 
        [Patient ID],
        [Insurance Provider],
        LEAD([Insurance Provider]) OVER (ORDER BY [Patient ID]) AS NextProvider
    FROM patient_records_clean
)
UPDATE p
SET InsuranceProvider_Clean =
    CASE 
        WHEN p.[Insurance Provider] IS NULL THEN cte.NextProvider
        ELSE p.[Insurance Provider]
    END
FROM patient_records_clean p
JOIN CTE cte
  ON p.[Patient ID] = cte.[Patient ID];