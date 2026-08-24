
-- SILVER ENCOUNTER QUARANTINE
-- Purpose: Keep invalid records and extra duplicate copies for audit.
-- Expected result: 102 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.silver.pipeline_encounters_quarantine AS
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
SELECT *
FROM ranked_encounters
WHERE
    CAST(encounter_id AS INT) IS NULL
    OR CAST(patient_id AS INT) IS NULL
    OR TRIM(department_id) IS NULL
    OR CAST(arrival_datetime AS TIMESTAMP) IS NULL
    OR CAST(waiting_time_minutes AS INT) IS NULL
    OR CAST(waiting_time_minutes AS INT) < 0
    OR CAST(waiting_time_minutes AS INT) > 720
    OR row_number > 1;
