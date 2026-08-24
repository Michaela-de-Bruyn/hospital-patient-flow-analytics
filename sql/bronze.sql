/*
===============================================================================
PROJECT:        Hospital Patient Flow & Waiting Time Analytics
FILE:           01_bronze_ingestion.sql
PURPOSE:        Create database, Medallion schemas, Bronze tables, and profile
                the raw data after ingestion.

ARCHITECTURE:
    CSV SOURCE -> BRONZE -> SILVER -> GOLD -> POWER BI

BRONZE PRINCIPLE:
    Preserve the source as closely as possible.
    Do NOT clean, deduplicate, standardise, or apply business rules here.

NOTE:
    All project data is synthetic and created for portfolio/interview purposes.

IMPORTANT:
    The patients CSV has already been successfully loaded through SSMS.
    Therefore STEP 9 (patient BULK INSERT) is included for reproducibility
    but should NOT be run again on the current database or it will duplicate
    the 12,000 patient records.
===============================================================================
*/


/*
===============================================================================
STEP 1 - CREATE DATABASE
EXPECTED RESULT:
    Database: HospitalWaitingTime
===============================================================================
*/

IF DB_ID('HospitalWaitingTime') IS NULL
BEGIN
    CREATE DATABASE HospitalWaitingTime;
END;
GO


/*
===============================================================================
STEP 2 - USE PROJECT DATABASE
===============================================================================
*/

USE HospitalWaitingTime;
GO


/*
===============================================================================
STEP 3 - CREATE MEDALLION SCHEMAS

BRONZE = Raw source data
SILVER = Cleaned and validated data
GOLD   = Business-ready analytical model
AUDIT  = Pipeline/data-quality logging

EXPECTED RESULT:
    Schemas:
        bronze
        silver
        gold
        audit
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
BEGIN
    EXEC('CREATE SCHEMA audit');
END;
GO


/*
===============================================================================
STEP 4 - CREATE BRONZE PATIENT TABLE

SOURCE:
    dim_patients.csv

WHY NVARCHAR?
    Bronze is a raw landing layer. We intentionally avoid strict business
    typing here. Data types and validation rules will be applied in Silver.

EXPECTED RESULT:
    bronze.patients_raw exists.
===============================================================================
*/

IF OBJECT_ID('bronze.patients_raw', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.patients_raw
    (
        patient_id      NVARCHAR(50)  NULL,
        age             NVARCHAR(50)  NULL,
        gender          NVARCHAR(50)  NULL,
        province        NVARCHAR(100) NULL,
        funding_type    NVARCHAR(100) NULL
    );
END;
GO


/*
===============================================================================
STEP 5 - CREATE BRONZE DEPARTMENT TABLE

SOURCE:
    dim_departments.csv

EXPECTED RESULT:
    bronze.departments_raw exists.
===============================================================================
*/

IF OBJECT_ID('bronze.departments_raw', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.departments_raw
    (
        department_id       NVARCHAR(50)  NULL,
        department_name     NVARCHAR(150) NULL,
        service_line        NVARCHAR(100) NULL,
        target_wait_minutes NVARCHAR(50)  NULL
    );
END;
GO


/*
===============================================================================
STEP 6 - CREATE BRONZE ENCOUNTER TABLE

SOURCE:
    fact_encounters_dirty.csv

GRAIN:
    One row represents one hospital encounter.

IMPORTANT:
    The source intentionally contains:
        - NULL values
        - duplicate records
        - invalid waiting times
        - inconsistent categories
        - missing dates

    These issues should remain visible in Bronze.

EXPECTED RESULT:
    bronze.encounters_raw exists.
===============================================================================
*/

IF OBJECT_ID('bronze.encounters_raw', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.encounters_raw
    (
        encounter_id          NVARCHAR(50)  NULL,
        patient_id            NVARCHAR(50)  NULL,
        department_id         NVARCHAR(50)  NULL,
        arrival_datetime      NVARCHAR(100) NULL,
        arrival_method        NVARCHAR(100) NULL,
        acuity_level          NVARCHAR(100) NULL,
        staff_on_duty         NVARCHAR(50)  NULL,
        daily_patient_volume  NVARCHAR(50)  NULL,
        waiting_time_minutes  NVARCHAR(50)  NULL,
        outcome               NVARCHAR(100) NULL,
        length_of_stay_days   NVARCHAR(50)  NULL,
        patient_satisfaction  NVARCHAR(50)  NULL,
        day_of_week           NVARCHAR(50)  NULL,
        month                 NVARCHAR(50)  NULL,
        is_weekend            NVARCHAR(50)  NULL,
        wait_band             NVARCHAR(100) NULL
    );
END;
GO


/*
===============================================================================
STEP 7 - CHECK BRONZE TABLES

EXPECTED RESULT:

schema_name    table_name
------------   ----------------
bronze         departments_raw
bronze         encounters_raw
bronze         patients_raw
===============================================================================
*/

SELECT
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE s.name = 'bronze'
ORDER BY t.name;


/*
===============================================================================
STEP 8 - SOURCE DATA PATH

IMPORTANT:
    Change this path to the actual location of your CSV files.

Example:
    C:\Projects\hospital-patient-flow-analytics\data\

SQL Server must be able to access this folder.

NOTE:
    The BULK INSERT statements below use the explicit path because SQL Server
    cannot use a T-SQL variable directly in a normal BULK INSERT statement.
===============================================================================
*/


/*
===============================================================================
STEP 9 - LOAD PATIENT DATA

IMPORTANT:
    DO NOT RUN THIS AGAIN IF YOUR CURRENT bronze.patients_raw ALREADY CONTAINS
    12,000 ROWS.

SOURCE:
    dim_patients.csv

EXPECTED RESULT:
    12,000 rows.

===============================================================================
*/

-- BULK INSERT bronze.patients_raw
-- FROM 'C:\Projects\hospital-patient-flow-analytics\data\dim_patients.csv'
-- WITH
-- (
--     FORMAT = 'CSV',
--     FIRSTROW = 2,
--     FIELDQUOTE = '"',
--     CODEPAGE = '65001',
--     TABLOCK
-- );
-- GO


/*
===============================================================================
STEP 10 - VALIDATE PATIENT INGESTION

EXPECTED RESULT:

patient_count
-------------
12000
===============================================================================
*/

SELECT
    COUNT(*) AS patient_count
FROM bronze.patients_raw;


/*
===============================================================================
STEP 11 - PREVIEW PATIENT DATA

EXPECTED RESULT:
    10 patient records.
===============================================================================
*/

SELECT TOP 10
    *
FROM bronze.patients_raw;


/*
===============================================================================
STEP 12 - LOAD DEPARTMENT DATA

SOURCE:
    dim_departments.csv

TARGET:
    bronze.departments_raw

EXPECTED RESULT:
    6 rows.
===============================================================================
*/

BULK INSERT bronze.departments_raw
FROM 'C:\Projects\hospital-patient-flow-analytics\data\dim_departments.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/*
===============================================================================
STEP 13 - VALIDATE DEPARTMENT INGESTION

EXPECTED RESULT:

department_count
----------------
6
===============================================================================
*/

SELECT
    COUNT(*) AS department_count
FROM bronze.departments_raw;


/*
===============================================================================
STEP 14 - PREVIEW DEPARTMENT DATA

EXPECTED RESULT:
    6 department records.
===============================================================================
*/

SELECT
    *
FROM bronze.departments_raw;


/*
===============================================================================
STEP 15 - LOAD ENCOUNTER DATA

SOURCE:
    fact_encounters_dirty.csv

TARGET:
    bronze.encounters_raw

EXPECTED RESULT:
    30,035 rows.

WHY 30,035?
    Clean source = 30,000 encounters
    Intentional duplicate records = 35
    Bronze = 30,035

===============================================================================
*/

BULK INSERT bronze.encounters_raw
FROM 'C:\Projects\hospital-patient-flow-analytics\data\fact_encounters_dirty.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/*
===============================================================================
STEP 16 - VALIDATE ENCOUNTER INGESTION

EXPECTED RESULT:

encounter_count
---------------
30035
===============================================================================
*/

SELECT
    COUNT(*) AS encounter_count
FROM bronze.encounters_raw;


/*
===============================================================================
STEP 17 - PREVIEW RAW ENCOUNTER DATA

EXPECTED RESULT:
    10 raw encounter records.
===============================================================================
*/

SELECT TOP 10
    *
FROM bronze.encounters_raw;


/*
===============================================================================
STEP 18 - FINAL BRONZE ROW COUNT CHECK

EXPECTED RESULT:

table_name          row_count
-----------------   ---------
patients_raw          12000
departments_raw           6
encounters_raw        30035

===============================================================================
*/

SELECT
    'patients_raw' AS table_name,
    COUNT(*) AS row_count
FROM bronze.patients_raw

UNION ALL

SELECT
    'departments_raw',
    COUNT(*)
FROM bronze.departments_raw

UNION ALL

SELECT
    'encounters_raw',
    COUNT(*)
FROM bronze.encounters_raw;


/*
===============================================================================
STEP 19 - PROFILE ARRIVAL METHODS

PURPOSE:
    Start profiling the raw source data without cleaning it.

EXPECTED RESULT:
    Standard and intentionally inconsistent values may appear, for example:

        Walk-in
        walk in
        Ambulance
        AMBULANCE
        Referral
        Scheduled
        scheduled

DO NOT FIX THESE IN BRONZE.
===============================================================================
*/

SELECT
    arrival_method,
    COUNT(*) AS record_count
FROM bronze.encounters_raw
GROUP BY arrival_method
ORDER BY record_count DESC;


/*
===============================================================================
STEP 20 - PROFILE ACUITY VALUES

EXPECTED RESULT:
    Low
    Moderate
    High
    Critical
===============================================================================
*/

SELECT
    acuity_level,
    COUNT(*) AS record_count
FROM bronze.encounters_raw
GROUP BY acuity_level
ORDER BY record_count DESC;


/*
===============================================================================
STEP 21 - PROFILE OUTCOME VALUES

EXPECTED RESULT:
    Discharged
    Admitted
    Transferred
    Left Before Treatment

    Some NULL values may also appear.
===============================================================================
*/

SELECT
    outcome,
    COUNT(*) AS record_count
FROM bronze.encounters_raw
GROUP BY outcome
ORDER BY record_count DESC;


/*
===============================================================================
STEP 22 - CHECK NULLS

PURPOSE:
    Quantify missing values before Silver transformation.

EXPECTED RESULT:
    Some NULL counts should be greater than zero.

    This is expected because the dataset intentionally contains data-quality
    issues.
===============================================================================
*/

SELECT
    SUM(CASE WHEN encounter_id IS NULL THEN 1 ELSE 0 END)
        AS null_encounter_id,

    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END)
        AS null_patient_id,

    SUM(CASE WHEN department_id IS NULL THEN 1 ELSE 0 END)
        AS null_department_id,

    SUM(CASE WHEN arrival_datetime IS NULL THEN 1 ELSE 0 END)
        AS null_arrival_datetime,

    SUM(CASE WHEN arrival_method IS NULL THEN 1 ELSE 0 END)
        AS null_arrival_method,

    SUM(CASE WHEN staff_on_duty IS NULL THEN 1 ELSE 0 END)
        AS null_staff_on_duty,

    SUM(CASE WHEN outcome IS NULL THEN 1 ELSE 0 END)
        AS null_outcome,

    SUM(CASE WHEN patient_satisfaction IS NULL THEN 1 ELSE 0 END)
        AS null_patient_satisfaction

FROM bronze.encounters_raw;


/*
===============================================================================
STEP 23 - CHECK DUPLICATE ENCOUNTER IDS

PURPOSE:
    Identify duplicate encounter IDs.

EXPECTED RESULT:
    Duplicate encounter IDs should be returned.

    The dataset intentionally contains approximately 35 duplicate rows.
===============================================================================
*/

SELECT
    encounter_id,
    COUNT(*) AS record_count
FROM bronze.encounters_raw
GROUP BY encounter_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


/*
===============================================================================
STEP 24 - COUNT DUPLICATE ROWS

PURPOSE:
    Quantify rows beyond the first occurrence of each duplicate encounter ID.

EXPECTED RESULT:
    Approximately 35 duplicate rows.
===============================================================================
*/

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


/*
===============================================================================
STEP 25 - CHECK WAITING-TIME RANGE

PURPOSE:
    Identify obviously invalid waiting-time values.

EXPECTED RESULT:
    Minimum may be negative and maximum may be extremely high because the
    source intentionally contains invalid values.
===============================================================================
*/

SELECT
    MIN(TRY_CAST(waiting_time_minutes AS INT)) AS minimum_wait,
    MAX(TRY_CAST(waiting_time_minutes AS INT)) AS maximum_wait
FROM bronze.encounters_raw;


/*
===============================================================================
STEP 26 - SHOW INVALID WAITING TIMES

PURPOSE:
    Identify records requiring investigation in Silver.

EXPECTED RESULT:
    Some records should be returned.

    Examples include:
        waiting_time < 0
        waiting_time > 720
===============================================================================
*/

SELECT
    *
FROM bronze.encounters_raw
WHERE
    TRY_CAST(waiting_time_minutes AS INT) < 0
    OR
    TRY_CAST(waiting_time_minutes AS INT) > 720;


/*
===============================================================================
STEP 27 - CHECK ARRIVAL DATE CONVERSION

PURPOSE:
    Determine whether arrival_datetime can be safely converted to DATETIME2.

EXPECTED RESULT:
    Most records should convert successfully.
    A small number of missing/invalid values may be present.
===============================================================================
*/

SELECT
    COUNT(*) AS total_records,

    SUM
    (
        CASE
            WHEN TRY_CAST(arrival_datetime AS DATETIME2) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS invalid_or_missing_dates

FROM bronze.encounters_raw;


/*
===============================================================================
STEP 28 - CHECK PATIENT REFERENTIAL INTEGRITY

PURPOSE:
    Identify encounter records whose patient_id does not exist in the patient
    reference table.

EXPECTED RESULT:
    Ideally 0 unmatched non-NULL patient IDs.
===============================================================================
*/

SELECT
    COUNT(*) AS unmatched_patient_records
FROM bronze.encounters_raw e
LEFT JOIN bronze.patients_raw p
    ON e.patient_id = p.patient_id
WHERE
    e.patient_id IS NOT NULL
    AND p.patient_id IS NULL;


/*
===============================================================================
STEP 29 - CHECK DEPARTMENT REFERENTIAL INTEGRITY

PURPOSE:
    Identify encounter records whose department_id does not exist in the
    department reference table.

EXPECTED RESULT:
    Ideally 0 unmatched non-NULL department IDs.
===============================================================================
*/

SELECT
    COUNT(*) AS unmatched_department_records
FROM bronze.encounters_raw e
LEFT JOIN bronze.departments_raw d
    ON e.department_id = d.department_id
WHERE
    e.department_id IS NOT NULL
    AND d.department_id IS NULL;


/*
===============================================================================
STEP 30 - BRONZE CHECKPOINT

EXPECTED FINAL BRONZE COUNTS:

    patients_raw       = 12,000
    departments_raw   = 6
    encounters_raw    = 30,035

At this point:

    SOURCE
       ↓
    BRONZE

is complete.

DO NOT CLEAN THE BRONZE TABLES.

NEXT PHASE:
    SILVER

Silver will handle:

    1. Data type conversion
    2. NULL handling
    3. Category standardisation
    4. Duplicate removal
    5. Invalid-value handling
    6. Data-quality quarantine
    7. Referential validation
    8. Business-rule validation

===============================================================================
END OF FILE
===============================================================================
