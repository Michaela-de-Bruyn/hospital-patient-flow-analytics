
-- GOLD ARRIVAL METHOD DIMENSION
-- Purpose: Standardise arrival methods and retain missing values as Unknown.
-- Key 0 = Unknown.
-- Expected result: 5 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.gold.pipeline_dim_arrival_method AS
SELECT
    0 AS arrival_method_key,
    'Unknown' AS arrival_method
UNION ALL
SELECT
    ROW_NUMBER() OVER (ORDER BY arrival_method) AS arrival_method_key,
    arrival_method
FROM (
    SELECT DISTINCT arrival_method
    FROM hospital_patient_flow.silver.pipeline_encounters
    WHERE arrival_method IS NOT NULL
);
