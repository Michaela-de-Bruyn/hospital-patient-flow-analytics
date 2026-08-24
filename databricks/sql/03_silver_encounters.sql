
-- SILVER ENCOUNTERS
-- Purpose: Clean and standardise encounter data.
-- One record is retained per encounter_id.
-- Invalid critical records are excluded from Silver.
-- Expected result: 29,933 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.silver.pipeline_encounters AS
WITH ranked_encounters AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY encounter_id
            ORDER BY encounter_id
        ) AS row_number
    FROM hospital_patient_flow.bronze.encounters_raw
)
SELECT
    CAST(encounter_id AS INT) AS encounter_id,
    CAST(patient_id AS INT) AS patient_id,
    TRIM(department_id) AS department_id,
    CAST(arrival_datetime AS TIMESTAMP) AS arrival_datetime,
    CASE
        WHEN LOWER(TRIM(arrival_method)) IN ('walk-in', 'walk in') THEN 'Walk-in'
        WHEN LOWER(TRIM(arrival_method)) = 'ambulance' THEN 'Ambulance'
        WHEN LOWER(TRIM(arrival_method)) = 'scheduled' THEN 'Scheduled'
        WHEN LOWER(TRIM(arrival_method)) = 'referral' THEN 'Referral'
        ELSE NULL
    END AS arrival_method,
    NULLIF(TRIM(acuity_level), '') AS acuity_level,
    CAST(staff_on_duty AS DOUBLE) AS staff_on_duty,
    CAST(daily_patient_volume AS INT) AS daily_patient_volume,
    CAST(waiting_time_minutes AS INT) AS waiting_time_minutes,
    NULLIF(TRIM(outcome), '') AS outcome,
    CAST(length_of_stay_days AS DOUBLE) AS length_of_stay_days,
    CAST(patient_satisfaction AS DOUBLE) AS patient_satisfaction,
    MONTH(CAST(arrival_datetime AS TIMESTAMP)) AS month,
    CASE
        WHEN DAYOFWEEK(CAST(arrival_datetime AS TIMESTAMP)) IN (1, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend,
    CASE
        WHEN CAST(waiting_time_minutes AS INT) <= 60 THEN '<=60 min'
        WHEN CAST(waiting_time_minutes AS INT) <= 120 THEN '61-120 min'
        WHEN CAST(waiting_time_minutes AS INT) <= 180 THEN '121-180 min'
        ELSE '>180 min'
    END AS wait_band
FROM ranked_encounters
WHERE row_number = 1
  AND CAST(encounter_id AS INT) IS NOT NULL
  AND CAST(patient_id AS INT) IS NOT NULL
  AND TRIM(department_id) IS NOT NULL
  AND CAST(arrival_datetime AS TIMESTAMP) IS NOT NULL
  AND CAST(waiting_time_minutes AS INT) BETWEEN 0 AND 720;
