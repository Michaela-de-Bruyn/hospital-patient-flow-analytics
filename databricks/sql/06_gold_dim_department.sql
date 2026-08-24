
-- GOLD DEPARTMENT DIMENSION
-- Purpose: Create a business-ready department dimension.
-- Expected result: 6 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.gold.pipeline_dim_department AS
SELECT
    department_id,
    department_name,
    service_line,
    target_wait_minutes
FROM hospital_patient_flow.silver.pipeline_departments;
