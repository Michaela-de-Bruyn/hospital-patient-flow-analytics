/*
===============================================================================
SILVER LAYER - HOSPITAL WAITING TIME ANALYTICS
===============================================================================
Purpose:
    Clean and validate the Bronze data.

Expected final results:
    patients              = 12,000
    departments           = 6
    encounters            = 29,933
    quarantine records    = 102

Note:
    Run the sections in order when rebuilding the Silver layer.
===============================================================================
*/

USE HospitalWaitingTime;
GO

/*
1. Create the Silver schema.
Expected: schema 'silver' exists.
*/
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
END;
GO

/*
2. Create and load Silver patients.
Expected: 12,000 rows.
*/
DROP TABLE IF EXISTS silver.patients;
GO

CREATE TABLE silver.patients
(
    patient_id INT NOT NULL,
    age INT NULL,
    gender NVARCHAR(50) NULL,
    province NVARCHAR(100) NULL,
    funding_type NVARCHAR(50) NULL
);
GO

INSERT INTO silver.patients
(
    patient_id,
    age,
    gender,
    province,
    funding_type
)
SELECT
    TRY_CAST(patient_id AS INT),
    TRY_CAST(age AS INT),
    NULLIF(LTRIM(RTRIM(gender)), ''),
    NULLIF(LTRIM(RTRIM(province)), ''),
    NULLIF(LTRIM(RTRIM(funding_type)), '')
FROM bronze.patients_raw;
GO

SELECT COUNT(*) AS silver_patient_count
FROM silver.patients;
-- Expected: 12,000

/*
Patient quality check.
Expected: no duplicate patient IDs.
*/
SELECT
    patient_id,
    COUNT(*) AS record_count
FROM silver.patients
GROUP BY patient_id
HAVING COUNT(*) > 1;
GO

/*
Age quality check.
Expected: 0 invalid ages.
*/
SELECT COUNT(*) AS invalid_age_records
FROM silver.patients
WHERE age IS NOT NULL
  AND (age < 0 OR age > 120);
GO

/*
3. Create and load Silver departments.
Expected: 6 rows.
*/
DROP TABLE IF EXISTS silver.departments;
GO

CREATE TABLE silver.departments
(
    department_id NVARCHAR(10) NOT NULL,
    department_name NVARCHAR(150) NOT NULL,
    service_line NVARCHAR(100) NOT NULL,
    target_wait_minutes INT NULL
);
GO

INSERT INTO silver.departments
(
    department_id,
    department_name,
    service_line,
    target_wait_minutes
)
SELECT
    LTRIM(RTRIM(department_id)),
    LTRIM(RTRIM(department_name)),
    LTRIM(RTRIM(service_line)),
    TRY_CAST(target_wait_minutes AS INT)
FROM bronze.departments_raw;
GO

SELECT COUNT(*) AS silver_department_count
FROM silver.departments;
-- Expected: 6

/*
4. Profile Bronze encounters before cleaning.
Expected: 30,035 total encounters and 35 extra duplicate rows.
*/
SELECT COUNT(*) AS total_encounters
FROM bronze.encounters_raw;
GO

SELECT
    encounter_id,
    COUNT(*) AS record_count
FROM bronze.encounters_raw
GROUP BY encounter_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;
GO

SELECT
    SUM(record_count - 1) AS duplicate_rows
FROM
(
    SELECT
        encounter_id,
        COUNT(*) AS record_count
    FROM bronze.encounters_raw
    GROUP BY encounter_id
    HAVING COUNT(*) > 1
) d;
GO
-- Expected: 35

/*
5. Create Silver encounters.
Expected final clean count after deduplication: 29,933.
*/
DROP TABLE IF EXISTS silver.encounters;
GO

CREATE TABLE silver.encounters
(
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    department_id NVARCHAR(10) NOT NULL,
    arrival_datetime DATETIME2 NOT NULL,
    arrival_method NVARCHAR(50) NULL,
    acuity_level NVARCHAR(50) NULL,
    staff_on_duty DECIMAL(5,1) NULL,
    daily_patient_volume INT NULL,
    waiting_time_minutes INT NOT NULL,
    outcome NVARCHAR(100) NULL,
    length_of_stay_days DECIMAL(5,1) NULL,
    patient_satisfaction DECIMAL(3,1) NULL,
    day_of_week NVARCHAR(20) NOT NULL,
    month INT NOT NULL,
    is_weekend BIT NOT NULL,
    wait_band NVARCHAR(50) NOT NULL
);
GO

/*
Load valid encounter records.
Expected at this stage: 29,968 rows.
*/
INSERT INTO silver.encounters
(
    encounter_id,
    patient_id,
    department_id,
    arrival_datetime,
    arrival_method,
    acuity_level,
    staff_on_duty,
    daily_patient_volume,
    waiting_time_minutes,
    outcome,
    length_of_stay_days,
    patient_satisfaction,
    day_of_week,
    month,
    is_weekend,
    wait_band
)
SELECT
    TRY_CAST(encounter_id AS INT),
    TRY_CAST(TRY_CAST(patient_id AS DECIMAL(18,0)) AS INT),
    LTRIM(RTRIM(department_id)),
    TRY_CAST(arrival_datetime AS DATETIME2),

    CASE
        WHEN LOWER(LTRIM(RTRIM(arrival_method))) IN ('walk-in', 'walk in')
            THEN 'Walk-in'
        WHEN LOWER(LTRIM(RTRIM(arrival_method))) = 'ambulance'
            THEN 'Ambulance'
        WHEN LOWER(LTRIM(RTRIM(arrival_method))) = 'scheduled'
            THEN 'Scheduled'
        WHEN LOWER(LTRIM(RTRIM(arrival_method))) = 'referral'
            THEN 'Referral'
        ELSE NULL
    END,

    NULLIF(LTRIM(RTRIM(acuity_level)), ''),
    TRY_CAST(staff_on_duty AS DECIMAL(5,1)),
    TRY_CAST(daily_patient_volume AS INT),
    TRY_CAST(waiting_time_minutes AS INT),
    NULLIF(LTRIM(RTRIM(outcome)), ''),
    TRY_CAST(length_of_stay_days AS DECIMAL(5,1)),
    TRY_CAST(patient_satisfaction AS DECIMAL(3,1)),
    DATENAME(WEEKDAY, TRY_CAST(arrival_datetime AS DATETIME2)),
    MONTH(TRY_CAST(arrival_datetime AS DATETIME2)),

    CASE
        WHEN DATEPART(WEEKDAY, TRY_CAST(arrival_datetime AS DATETIME2)) IN (1,7)
            THEN 1
        ELSE 0
    END,

    CASE
        WHEN TRY_CAST(waiting_time_minutes AS INT) <= 60
            THEN '<=60 min'
        WHEN TRY_CAST(waiting_time_minutes AS INT) <= 120
            THEN '61-120 min'
        WHEN TRY_CAST(waiting_time_minutes AS INT) <= 180
            THEN '121-180 min'
        ELSE '>180 min'
    END
FROM bronze.encounters_raw
WHERE TRY_CAST(encounter_id AS INT) IS NOT NULL
  AND TRY_CAST(TRY_CAST(patient_id AS DECIMAL(18,0)) AS INT) IS NOT NULL
  AND department_id IS NOT NULL
  AND TRY_CAST(arrival_datetime AS DATETIME2) IS NOT NULL
  AND TRY_CAST(waiting_time_minutes AS INT) BETWEEN 0 AND 720;
GO

SELECT COUNT(*) AS silver_encounter_count
FROM silver.encounters;
-- Expected: 29,968

/*
6. Create the quarantine table.
Expected final count: 102
(67 critical invalid records + 35 duplicate copies).
*/
DROP TABLE IF EXISTS silver.encounters_quarantine;
GO

CREATE TABLE silver.encounters_quarantine
(
    encounter_id NVARCHAR(50) NULL,
    patient_id NVARCHAR(50) NULL,
    department_id NVARCHAR(50) NULL,
    arrival_datetime NVARCHAR(100) NULL,
    arrival_method NVARCHAR(50) NULL,
    acuity_level NVARCHAR(50) NULL,
    staff_on_duty NVARCHAR(50) NULL,
    daily_patient_volume NVARCHAR(50) NULL,
    waiting_time_minutes NVARCHAR(50) NULL,
    outcome NVARCHAR(100) NULL,
    length_of_stay_days NVARCHAR(50) NULL,
    patient_satisfaction NVARCHAR(50) NULL,
    day_of_week NVARCHAR(50) NULL,
    month NVARCHAR(50) NULL,
    is_weekend NVARCHAR(50) NULL,
    wait_band NVARCHAR(50) NULL,
    quarantine_reason NVARCHAR(200) NOT NULL
);
GO

/*
7. Quarantine duplicate copies.
Expected: 35 rows.
*/
WITH duplicates AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY encounter_id
            ORDER BY encounter_id
        ) AS row_number
    FROM silver.encounters
)
INSERT INTO silver.encounters_quarantine
(
    encounter_id,
    patient_id,
    department_id,
    arrival_datetime,
    arrival_method,
    acuity_level,
    staff_on_duty,
    daily_patient_volume,
    waiting_time_minutes,
    outcome,
    length_of_stay_days,
    patient_satisfaction,
    day_of_week,
    month,
    is_weekend,
    wait_band,
    quarantine_reason
)
SELECT
    CAST(encounter_id AS NVARCHAR(50)),
    CAST(patient_id AS NVARCHAR(50)),
    department_id,
    CONVERT(NVARCHAR(100), arrival_datetime, 120),
    arrival_method,
    acuity_level,
    CAST(staff_on_duty AS NVARCHAR(50)),
    CAST(daily_patient_volume AS NVARCHAR(50)),
    CAST(waiting_time_minutes AS NVARCHAR(50)),
    outcome,
    CAST(length_of_stay_days AS NVARCHAR(50)),
    CAST(patient_satisfaction AS NVARCHAR(50)),
    day_of_week,
    CAST(month AS NVARCHAR(50)),
    CAST(is_weekend AS NVARCHAR(50)),
    wait_band,
    'Duplicate encounter'
FROM duplicates
WHERE row_number = 2;
GO

/*
Remove the duplicate copies from Silver.
Expected: 35 rows deleted.
*/
WITH duplicates AS
(
    SELECT
        encounter_id,
        ROW_NUMBER() OVER
        (
            PARTITION BY encounter_id
            ORDER BY encounter_id
        ) AS row_number
    FROM silver.encounters
)
DELETE FROM duplicates
WHERE row_number = 2;
GO

/*
8. Quarantine critical invalid records from Bronze.
Expected: 67 rows.
*/
INSERT INTO silver.encounters_quarantine
(
    encounter_id,
    patient_id,
    department_id,
    arrival_datetime,
    arrival_method,
    acuity_level,
    staff_on_duty,
    daily_patient_volume,
    waiting_time_minutes,
    outcome,
    length_of_stay_days,
    patient_satisfaction,
    day_of_week,
    month,
    is_weekend,
    wait_band,
    quarantine_reason
)
SELECT
    encounter_id,
    patient_id,
    department_id,
    arrival_datetime,
    arrival_method,
    acuity_level,
    staff_on_duty,
    daily_patient_volume,
    waiting_time_minutes,
    outcome,
    length_of_stay_days,
    patient_satisfaction,
    day_of_week,
    month,
    is_weekend,
    wait_band,

    CASE
        WHEN patient_id IS NULL
            THEN 'Missing patient ID'
        WHEN TRY_CAST(arrival_datetime AS DATETIME2) IS NULL
            THEN 'Invalid or missing arrival datetime'
        WHEN TRY_CAST(waiting_time_minutes AS INT) IS NULL
             OR TRY_CAST(waiting_time_minutes AS INT) < 0
             OR TRY_CAST(waiting_time_minutes AS INT) > 720
            THEN 'Invalid waiting time'
        ELSE 'Other data quality issue'
    END
FROM bronze.encounters_raw
WHERE patient_id IS NULL
   OR TRY_CAST(arrival_datetime AS DATETIME2) IS NULL
   OR TRY_CAST(waiting_time_minutes AS INT) IS NULL
   OR TRY_CAST(waiting_time_minutes AS INT) < 0
   OR TRY_CAST(waiting_time_minutes AS INT) > 720;
GO

/*
9. Final Silver reconciliation.
Expected:
    Bronze = 30,035
    Silver = 29,933
    Quarantine = 102
    Silver + quarantine = 30,035
*/
SELECT
    (SELECT COUNT(*) FROM bronze.encounters_raw) AS bronze_count,
    (SELECT COUNT(*) FROM silver.encounters) AS silver_count,
    (SELECT COUNT(*) FROM silver.encounters_quarantine) AS quarantine_count,
    (
        (SELECT COUNT(*) FROM silver.encounters)
        +
        (SELECT COUNT(*) FROM silver.encounters_quarantine)
    ) AS silver_plus_quarantine;
GO

/*
10. Final Silver quality checks.
Expected:
    No duplicate encounter IDs.
*/
SELECT
    encounter_id,
    COUNT(*) AS record_count
FROM silver.encounters
GROUP BY encounter_id
HAVING COUNT(*) > 1;
GO

/*
Expected: 0 invalid waiting times.
*/
SELECT COUNT(*) AS invalid_waiting_times
FROM silver.encounters
WHERE waiting_time_minutes < 0
   OR waiting_time_minutes > 720;
GO

/*
Expected: 0 invalid dates.
*/
SELECT COUNT(*) AS invalid_dates
FROM silver.encounters
WHERE arrival_datetime IS NULL;
GO

/*
Expected: 0 unmatched patients.
*/
SELECT COUNT(*) AS unmatched_patients
FROM silver.encounters e
LEFT JOIN silver.patients p
    ON e.patient_id = p.patient_id
WHERE p.patient_id IS NULL;
GO

/*
Expected: 0 unmatched departments.
*/
SELECT COUNT(*) AS unmatched_departments
FROM silver.encounters e
LEFT JOIN silver.departments d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL;
GO
