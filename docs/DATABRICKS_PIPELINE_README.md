# Hospital Patient Flow — Databricks Lakeflow Pipeline

This folder contains the SQL transformations used in the Databricks Lakeflow version of the Hospital Patient Flow project.

## Architecture

```text
CSV files
   ↓
Bronze
   ↓
Silver
   ├── Patients
   ├── Departments
   ├── Encounters
   └── Quarantine
   ↓
Gold
   ├── Patient dimension
   ├── Department dimension
   ├── Arrival method dimension
   ├── Date dimension
   └── Encounter fact
```

## SQL files

### Silver

1. `01_silver_patients.sql` — cleans patient data.
2. `02_silver_departments.sql` — cleans department data.
3. `03_silver_encounters.sql` — cleans encounters, standardises arrival methods, removes duplicate copies and filters invalid critical records.
4. `04_silver_quarantine.sql` — keeps invalid and duplicate records for audit.

### Gold

5. `05_gold_dim_patient.sql` — patient dimension.
6. `06_gold_dim_department.sql` — department dimension.
7. `07_gold_dim_arrival_method.sql` — arrival method dimension, including Unknown.
8. `08_gold_dim_date.sql` — 2025 calendar dimension.
9. `09_gold_fact_encounters.sql` — central encounter fact table.

## Validated pipeline results

| Dataset | Rows |
|---|---:|
| Silver pipeline patients | 12,000 |
| Silver pipeline departments | 6 |
| Silver pipeline encounters | 29,933 |
| Silver quarantine | 102 |
| Gold patient dimension | 12,000 |
| Gold department dimension | 6 |
| Gold arrival method dimension | 5 |
| Gold date dimension | 365 |
| Gold fact encounters | 29,933 |

The encounter reconciliation is:

`29,933 Silver encounters + 102 quarantined records = 30,035 Bronze encounters`

## Key data-quality decisions

- Duplicate `encounter_id` values are ranked with `ROW_NUMBER()`. One record is retained and extra copies are quarantined.
- Invalid critical records are quarantined instead of silently deleted.
- Missing arrival methods are represented by the Gold `Unknown` member with key `0`.
- The Gold fact table uses the cleaned Silver encounter data and connects it to the arrival-method dimension.

## Lakeflow orchestration

The SQL files are used as transformations in a Databricks Lakeflow pipeline. Databricks builds the dependency graph from the dataset references.

The pipeline was run successfully and its output counts matched the expected validated results.
