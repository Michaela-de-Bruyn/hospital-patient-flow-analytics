/*
===============================================================================
GOLD LAYER - HOSPITAL WAITING TIME ANALYTICS
===============================================================================
Purpose:
    Create business-ready analytical tables using a simple star schema.

Fact grain:
    One row represents one hospital encounter.

Expected final results:
    dim_patient          = 12,000
    dim_department       = 6
    dim_arrival_method   = 4
    dim_date             = 365
    fact_encounters      = 29,933
===============================================================================
*/

USE HospitalWaitingTime;
GO

/*
1. Create the Gold schema.
Expected: schema 'gold' exists.
*/
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO

/*
2. Patient dimension.
Grain: one row per patient.
Expected: 12,000 rows.
*/
DROP TABLE IF EXISTS gold.dim_patient;
GO

CREATE TABLE gold.dim_patient
(
    patient_key INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL,
    age INT NULL,
    gender NVARCHAR(50) NULL,
    province NVARCHAR(100) NULL,
    funding_type NVARCHAR(50) NULL
);
GO

INSERT INTO gold.dim_patient
(
    patient_id,
    age,
    gender,
    province,
    funding_type
)
SELECT
    patient_id,
    age,
    gender,
    province,
    funding_type
FROM silver.patients;
GO

SELECT COUNT(*) AS patient_count
FROM gold.dim_patient;
-- Expected: 12,000

/*
Expected: no duplicate patient IDs.
*/
SELECT
    patient_id,
    COUNT(*) AS record_count
FROM gold.dim_patient
GROUP BY patient_id
HAVING COUNT(*) > 1;
GO

/*
3. Department dimension.
Grain: one row per department.
Expected: 6 rows.
*/
DROP TABLE IF EXISTS gold.dim_department;
GO

CREATE TABLE gold.dim_department
(
    department_key INT IDENTITY(1,1) PRIMARY KEY,
    department_id NVARCHAR(10) NOT NULL,
    department_name NVARCHAR(150) NOT NULL,
    service_line NVARCHAR(100) NOT NULL,
    target_wait_minutes INT NULL
);
GO

INSERT INTO gold.dim_department
(
    department_id,
    department_name,
    service_line,
    target_wait_minutes
)
SELECT
    department_id,
    department_name,
    service_line,
    target_wait_minutes
FROM silver.departments;
GO

SELECT
    COUNT(*) AS department_count,
    COUNT(DISTINCT department_id) AS distinct_department_ids
FROM gold.dim_department;
-- Expected: 6 / 6

/*
Expected: no duplicate department IDs.
*/
SELECT
    department_id,
    COUNT(*) AS record_count
FROM gold.dim_department
GROUP BY department_id
HAVING COUNT(*) > 1;
GO

/*
4. Arrival method dimension.
Grain: one row per arrival method.
Expected: 4 rows.
*/
DROP TABLE IF EXISTS gold.dim_arrival_method;
GO

CREATE TABLE gold.dim_arrival_method
(
    arrival_key INT IDENTITY(1,1) PRIMARY KEY,
    arrival_method NVARCHAR(50) NOT NULL
);
GO

INSERT INTO gold.dim_arrival_method
(
    arrival_method
)
SELECT DISTINCT
    arrival_method
FROM silver.encounters
WHERE arrival_method IS NOT NULL;
GO

SELECT
    COUNT(*) AS arrival_method_count,
    COUNT(DISTINCT arrival_method) AS distinct_arrival_methods
FROM gold.dim_arrival_method;
-- Expected: 4 / 4

/*
Expected: no duplicate arrival methods.
*/
SELECT
    arrival_method,
    COUNT(*) AS record_count
FROM gold.dim_arrival_method
GROUP BY arrival_method
HAVING COUNT(*) > 1;
GO

/*
5. Date dimension.
Grain: one row per calendar date.
Expected: 365 rows for 2025.
*/
DROP TABLE IF EXISTS gold.dim_date;
GO

CREATE TABLE gold.dim_date
(
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_number INT NOT NULL,
    day_name NVARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    quarter_number INT NOT NULL,
    year_number INT NOT NULL,
    week_number INT NOT NULL,
    is_weekend BIT NOT NULL
);
GO

WITH dates AS
(
    SELECT CAST('2025-01-01' AS DATE) AS full_date

    UNION ALL

    SELECT DATEADD(DAY, 1, full_date)
    FROM dates
    WHERE full_date < '2025-12-31'
)
INSERT INTO gold.dim_date
(
    date_key,
    full_date,
    day_number,
    day_name,
    month_number,
    month_name,
    quarter_number,
    year_number,
    week_number,
    is_weekend
)
SELECT
    YEAR(full_date) * 10000
        + MONTH(full_date) * 100
        + DAY(full_date),
    full_date,
    DAY(full_date),
    DATENAME(WEEKDAY, full_date),
    MONTH(full_date),
    DATENAME(MONTH, full_date),
    DATEPART(QUARTER, full_date),
    YEAR(full_date),
    DATEPART(WEEK, full_date),
    CASE
        WHEN DATEPART(WEEKDAY, full_date) IN (1,7)
            THEN 1
        ELSE 0
    END
FROM dates
OPTION (MAXRECURSION 400);
GO

SELECT COUNT(*) AS date_count
FROM gold.dim_date;
-- Expected: 365

/*
Expected:
    First date = 2025-01-01
    Last date  = 2025-12-31
*/
SELECT
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date
FROM gold.dim_date;
GO

/*
Expected: no duplicate date keys.
*/
SELECT
    date_key,
    COUNT(*) AS record_count
FROM gold.dim_date
GROUP BY date_key
HAVING COUNT(*) > 1;
GO

/*
6. Encounter fact table.
Grain: one row per hospital encounter.
Expected: 29,933 rows.
*/
DROP TABLE IF EXISTS gold.fact_encounters;
GO

CREATE TABLE gold.fact_encounters
(
    encounter_key INT IDENTITY(1,1) PRIMARY KEY,
    encounter_id INT NOT NULL,
    patient_key INT NOT NULL,
    department_key INT NOT NULL,
    date_key INT NOT NULL,
    arrival_key INT NULL,
    acuity_level NVARCHAR(50) NULL,
    outcome NVARCHAR(100) NULL,
    waiting_time_minutes INT NOT NULL,
    staff_on_duty DECIMAL(5,1) NULL,
    daily_patient_volume INT NULL,
    length_of_stay_days DECIMAL(5,1) NULL,
    patient_satisfaction DECIMAL(3,1) NULL,
    wait_band NVARCHAR(50) NOT NULL,
    is_weekend BIT NOT NULL
);
GO

/*
7. Load the fact table by joining Silver to the Gold dimensions.
Expected: 29,933 rows inserted.
*/
INSERT INTO gold.fact_encounters
(
    encounter_id,
    patient_key,
    department_key,
    date_key,
    arrival_key,
    acuity_level,
    outcome,
    waiting_time_minutes,
    staff_on_duty,
    daily_patient_volume,
    length_of_stay_days,
    patient_satisfaction,
    wait_band,
    is_weekend
)
SELECT
    e.encounter_id,
    p.patient_key,
    d.department_key,
    dt.date_key,
    a.arrival_key,
    e.acuity_level,
    e.outcome,
    e.waiting_time_minutes,
    e.staff_on_duty,
    e.daily_patient_volume,
    e.length_of_stay_days,
    e.patient_satisfaction,
    e.wait_band,
    e.is_weekend
FROM silver.encounters e
INNER JOIN gold.dim_patient p
    ON e.patient_id = p.patient_id
INNER JOIN gold.dim_department d
    ON e.department_id = d.department_id
INNER JOIN gold.dim_date dt
    ON CAST(e.arrival_datetime AS DATE) = dt.full_date
LEFT JOIN gold.dim_arrival_method a
    ON e.arrival_method = a.arrival_method;
GO

SELECT COUNT(*) AS fact_encounter_count
FROM gold.fact_encounters;
-- Expected: 29,933

/*
8. Final fact-table quality checks.
Expected: no duplicate encounter IDs.
*/
SELECT
    encounter_id,
    COUNT(*) AS record_count
FROM gold.fact_encounters
GROUP BY encounter_id
HAVING COUNT(*) > 1;
GO

/*
Expected: 0 unmatched patient keys.
*/
SELECT COUNT(*) AS unmatched_patients
FROM gold.fact_encounters f
LEFT JOIN gold.dim_patient p
    ON f.patient_key = p.patient_key
WHERE p.patient_key IS NULL;
GO

/*
Expected: 0 unmatched department keys.
*/
SELECT COUNT(*) AS unmatched_departments
FROM gold.fact_encounters f
LEFT JOIN gold.dim_department d
    ON f.department_key = d.department_key
WHERE d.department_key IS NULL;
GO

/*
Expected: 0 unmatched date keys.
*/
SELECT COUNT(*) AS unmatched_dates
FROM gold.fact_encounters f
LEFT JOIN gold.dim_date d
    ON f.date_key = d.date_key
WHERE d.date_key IS NULL;
GO

/*
Expected: 0 unmatched non-NULL arrival keys.
*/
SELECT COUNT(*) AS unmatched_arrivals
FROM gold.fact_encounters f
LEFT JOIN gold.dim_arrival_method a
    ON f.arrival_key = a.arrival_key
WHERE f.arrival_key IS NOT NULL
  AND a.arrival_key IS NULL;
GO

/*
9. Final Gold summary.
Expected:
    dim_patient          12,000
    dim_department       6
    dim_arrival_method   4
    dim_date             365
    fact_encounters      29,933
*/
SELECT 'dim_patient' AS table_name, COUNT(*) AS row_count
FROM gold.dim_patient
UNION ALL
SELECT 'dim_department', COUNT(*)
FROM gold.dim_department
UNION ALL
SELECT 'dim_arrival_method', COUNT(*)
FROM gold.dim_arrival_method
UNION ALL
SELECT 'dim_date', COUNT(*)
FROM gold.dim_date
UNION ALL
SELECT 'fact_encounters', COUNT(*)
FROM gold.fact_encounters;
GO
