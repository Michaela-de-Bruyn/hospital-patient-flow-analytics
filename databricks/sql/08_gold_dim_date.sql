
-- GOLD DATE DIMENSION
-- Purpose: Create a calendar dimension covering 2025.
-- Expected result: 365 records.

CREATE OR REFRESH MATERIALIZED VIEW hospital_patient_flow.gold.pipeline_dim_date AS
SELECT
    CAST(date_format(date, 'yyyyMMdd') AS INT) AS date_key,
    date AS full_date,
    DAY(date) AS day_number,
    DATE_FORMAT(date, 'EEEE') AS day_name,
    MONTH(date) AS month_number,
    DATE_FORMAT(date, 'MMMM') AS month_name,
    QUARTER(date) AS quarter_number,
    YEAR(date) AS year_number,
    WEEKOFYEAR(date) AS week_number,
    CASE
        WHEN DAYOFWEEK(date) IN (1, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM (
    SELECT EXPLODE(
        SEQUENCE(
            DATE('2025-01-01'),
            DATE('2025-12-31'),
            INTERVAL 1 DAY
        )
    ) AS date
);
