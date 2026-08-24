
-- SILVER DEPARTMENTS
-- Purpose: Clean department fields and standardise the wait-time data.
-- Expected result: 6 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.silver.pipeline_departments AS
SELECT
    TRIM(department_id) AS department_id,
    TRIM(department_name) AS department_name,
    TRIM(service_line) AS service_line,
    CAST(target_wait_minutes AS INT) AS target_wait_minutes
FROM hospital_patient_flow.bronze.departments_raw;
