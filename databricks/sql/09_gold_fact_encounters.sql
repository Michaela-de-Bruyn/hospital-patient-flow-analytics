
-- GOLD FACT ENCOUNTERS
-- Purpose: Create the central encounter fact table for the star schema.
-- Missing arrival methods use key 0 (Unknown).
-- Expected result: 29,933 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.gold.pipeline_fact_encounters AS
SELECT
    e.encounter_id,
    e.patient_id,
    e.department_id,
    COALESCE(a.arrival_method_key, 0) AS arrival_method_key,
    CAST(DATE_FORMAT(e.arrival_datetime, 'yyyyMMdd') AS INT) AS date_key,
    e.arrival_datetime,
    e.acuity_level,
    e.staff_on_duty,
    e.daily_patient_volume,
    e.waiting_time_minutes,
    e.outcome,
    e.length_of_stay_days,
    e.patient_satisfaction,
    e.is_weekend,
    e.wait_band
FROM hospital_patient_flow.silver.pipeline_encounters e
LEFT JOIN hospital_patient_flow.gold.pipeline_dim_arrival_method a
    ON e.arrival_method = a.arrival_method;
