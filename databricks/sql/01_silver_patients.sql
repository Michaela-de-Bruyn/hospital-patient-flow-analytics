
-- SILVER PATIENTS
-- Purpose: Clean and standardise patient data from Bronze.
-- Expected result: 12,000 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.silver.pipeline_patients AS
SELECT
    CAST(patient_id AS INT) AS patient_id,
    CAST(age AS INT) AS age,
    NULLIF(TRIM(gender), '') AS gender,
    NULLIF(TRIM(province), '') AS province,
    NULLIF(TRIM(funding_type), '') AS funding_type
FROM hospital_patient_flow.bronze.patients_raw;
