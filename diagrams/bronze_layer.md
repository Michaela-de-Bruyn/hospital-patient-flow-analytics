# Bronze Layer Architecture

## Purpose

The Bronze layer is the first database layer in the project.

Its job is to take the raw CSV files and store them in SQL Server with as little change as possible.

This gives us a reliable copy of the source data before we clean or transform it.

---

## How to Read the Diagram

Read the diagram from **left to right**.

```text
SOURCE CSV FILES
       ↓
BRONZE LAYER
       ↓
SILVER LAYER
```

The arrows show the direction that the data moves.

---

## 1. Source CSV Files

The project starts with three CSV files:

- `dim_patients.csv`
- `dim_departments.csv`
- `fact_encounters_dirty.csv`

These files contain the original source data used for the project.

---

## 2. Bronze Layer

The CSV files are loaded into SQL Server.

The Bronze layer contains three raw tables:

- `bronze.patients_raw`
- `bronze.departments_raw`
- `bronze.encounters_raw`

The `_raw` name makes it clear that these tables contain the source data before the main cleaning and transformation work.

### What happens in Bronze?

The main tasks are:

- Load the CSV files
- Store the source data
- Check that the data was loaded correctly
- Check row counts
- Start identifying data-quality issues

The Bronze layer does **not** try to fix all of the problems in the data.

---

## 3. Why Do We Need Bronze?

Keeping the raw data is useful because we can always go back to the original data if something goes wrong later.

It also helps with:

- Traceability
- Troubleshooting
- Data-quality investigations
- Reprocessing
- Comparing the cleaned data against the original data

For example, if a record is changed in Silver, we can compare it back to the Bronze record.

---

## 4. Moving to Silver

After the data has been loaded into Bronze, it moves into the Silver layer.

Silver is where the main cleaning and validation takes place.

Examples include:

- Converting data types
- Standardising values
- Removing duplicate records
- Checking invalid values
- Checking relationships between tables
- Moving invalid records into quarantine

The Bronze layer therefore acts as the starting point for the Silver transformation.

---

## Data Flow

The overall flow represented by this diagram is:

```text
Raw CSV Files
      ↓
Bronze
      ↓
Silver
      ↓
Gold
```

The Bronze diagram focuses on the first part of this process:

```text
CSV Files → Bronze → Silver
```

---

## Key Point

The Bronze layer should be thought of as the **raw data storage layer**.

It preserves the source data before we apply the more significant cleaning and business transformations in the Silver and Gold layers.
