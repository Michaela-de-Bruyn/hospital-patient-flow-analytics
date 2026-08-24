
-- GOLD PATIENT DIMENSION
-- Purpose: Create a business-ready patient dimension.
-- Expected result: 12,000 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.gold.pipeline_dim_patient AS
SELECT
    patient_id,
    age,
    gender,
    province,
    funding_type
FROM hospital_patient_flow.silver.pipeline_patients;
