# Bronze Layer

## Purpose

The Bronze layer stores the raw source data with minimal transformation.

The main purpose is to keep a reliable copy of the source data before cleaning and transformation takes place.

---

## Source Data

The project uses three source files:

| File | Description |
|---|---|
| `dim_patients.csv` | Patient information |
| `dim_departments.csv` | Hospital department information |
| `fact_encounters_dirty.csv` | Hospital encounter information |

The files are stored in:

`data/raw/`

---

## Bronze Tables

The raw files were loaded into the following Bronze tables:

| Table | Source |
|---|---|
| `bronze.patients_raw` | `dim_patients.csv` |
| `bronze.departments_raw` | `dim_departments.csv` |
| `bronze.encounters_raw` | `fact_encounters_dirty.csv` |

The `_raw` naming convention makes it clear that these tables contain source data before Silver transformations.

---

## Ingestion

The source CSV files were imported into SQL Server.

The Bronze layer was intentionally kept close to the original source structure.

The main goal at this stage was:

- Load the source data
- Preserve the original values
- Check row counts
- Confirm the data was successfully ingested
- Avoid applying business transformations too early

---

## Initial Data Checks

After ingestion, the Bronze data was checked using SQL.

Checks included:

- Row counts
- NULL values
- Duplicate encounter IDs
- Arrival methods
- Acuity levels
- Outcomes
- Waiting-time ranges
- Arrival dates
- Patient relationships
- Department relationships

---

## Encounter Data

The Bronze encounter table contained:

**30,035 records**

This dataset was intentionally used to demonstrate data-quality handling.

The initial checks identified:

- Missing values
- Duplicate encounter records
- Invalid waiting times
- Invalid or missing dates
- Records with missing patient IDs

These issues were not removed from Bronze.

Instead, they were handled during the Silver transformation.

---

## Bronze Design Principle

The Bronze layer acts as the raw source layer.

Data is not permanently changed or cleaned at this stage.

This provides a reference point for:

- Data quality investigations
- Reconciliation
- Troubleshooting
- Reprocessing
- Auditing

The cleaned and validated data is created in the Silver layer.

---

## Next Layer

The Bronze data feeds into the Silver layer.

```text
Raw CSV files
      ↓
Bronze
      ↓
Data cleaning and validation
      ↓
Silver
