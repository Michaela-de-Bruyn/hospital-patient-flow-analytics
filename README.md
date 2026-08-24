# Hospital Patient Flow Analytics

A synthetic healthcare analytics project demonstrating a Medallion data architecture,
SQL data engineering, data quality management, dimensional modelling and
business-focused insights.

## Current project stage

**Stage 1 — Bronze layer complete**

The current repository contains only the raw-source ingestion work. Silver and Gold
transformations will be added in later stages.

```text
Synthetic CSV Source
        |
        v
    [ BRONZE ]   <-- current stage
        |
        v
     [ SILVER ]  <-- next stage
        |
        v
      [ GOLD ]
        |
        v
    [ POWER BI ]
```

## Bronze layer

The Bronze layer is the raw landing layer.

Its purpose is to preserve the incoming source data as closely as possible before
cleaning, standardisation, validation or business rules are applied.

### Source files

| File | Purpose |
|---|---|
| `dim_patients.csv` | Synthetic patient reference data |
| `dim_departments.csv` | Synthetic department reference data |
| `fact_encounters_dirty.csv` | Synthetic hospital encounter data containing intentional data-quality issues |
| `data_dictionary.csv` | Field definitions and data types |

### Bronze SQL

`sql/01_bronze_ingestion.sql`

The script:

- Creates the `HospitalWaitingTime` database
- Creates `bronze`, `silver`, `gold` and `audit` schemas
- Creates the Bronze tables
- Loads the raw CSV files
- Validates row counts
- Profiles the raw data
- Checks NULLs
- Checks duplicate encounter IDs
- Checks invalid waiting-time values
- Checks date conversion
- Checks patient and department referential integrity

## Expected Bronze row counts

After ingestion:

```text
bronze.patients_raw       12,000 rows
bronze.departments_raw         6 rows
bronze.encounters_raw      30,035 rows
```

The encounter source contains 30,000 underlying encounters plus intentionally
introduced duplicate records. These are deliberately retained in Bronze so that
the Silver layer can demonstrate deduplication and data-quality handling.

## Bronze design decisions

- No business cleaning is performed in Bronze.
- Bronze columns are intentionally permissive (`NVARCHAR`) so source values can land
  without aggressive type conversion.
- No primary or foreign keys are applied in Bronze.
- Data-quality issues are identified and documented, not silently removed.
- Cleaning and validation belong in the Silver layer.

## Data disclaimer

All data is synthetic and was generated specifically for portfolio/interview
preparation. It does not represent real patients, a real hospital, or real
South African healthcare statistics.

## Next stage

After the Bronze layer is validated, the next stage will be:

**Bronze → Silver**

This will cover:

- Data type conversion
- Standardisation
- Duplicate handling
- Invalid-value handling
- Data-quality quarantine
- Referential validation
- Derived analytical fields
