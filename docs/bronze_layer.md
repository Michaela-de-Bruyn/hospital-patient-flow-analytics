# Bronze Layer

## Purpose

The Bronze layer is the raw landing layer of the Medallion architecture.

The principle is simple:

> Preserve the source before transforming it.

This means the Bronze layer intentionally contains the source data-quality issues.

## Tables

### `bronze.patients_raw`

Patient reference data.

### `bronze.departments_raw`

Department reference data.

### `bronze.encounters_raw`

Hospital encounter/event data.

**Grain:** one source row represents one hospital encounter record.

## Why the Bronze layer is permissive

The raw columns are stored mainly as `NVARCHAR` rather than immediately enforcing
business data types.

For example:

```sql
waiting_time_minutes NVARCHAR(50)
```

The value can later be validated and converted in Silver:

```sql
TRY_CAST(waiting_time_minutes AS INT)
```

This makes the pipeline more traceable and allows invalid source values to be
identified rather than silently rejected.

## Data-quality issues intentionally present

The encounter source contains examples of:

- NULL values
- Duplicate encounter records
- Inconsistent arrival-method labels
- Invalid waiting times
- Missing/invalid date values

These are not fixed in Bronze.

## Validation checkpoint

The Bronze ingestion is considered complete when:

```text
patients_raw       = 12,000
departments_raw    = 6
encounters_raw     = 30,035
```

and the raw profiling queries have been run.

## Technical principle

Bronze is not the analytical layer.

Power BI should not connect directly to Bronze.

Bronze feeds Silver, and Silver feeds the business-ready Gold model.
