# Silver Layer Architecture

## Purpose

The Silver layer is the cleaned and validated data layer of the project.

It takes the raw data from Bronze and prepares it for the Gold analytical layer.

The Silver layer focuses on cleaning, standardising and checking the data before it is used for business analysis.

---

## How to Read the Diagram

Read the diagram from **top to bottom**.

```text
BRONZE TABLES
      ↓
CLEANING + VALIDATION
      ↓
SILVER TABLES
      ↓
GOLD LAYER
```

Invalid or duplicate records can be moved to the quarantine table instead of being used in the clean Silver data.

---

## 1. Bronze Tables

The Silver process starts with the Bronze tables:

- `bronze.patients_raw`
- `bronze.departments_raw`
- `bronze.encounters_raw`

These tables contain the source data before the main cleaning and validation takes place.

---

## 2. Cleaning and Validation

The Bronze data is cleaned and checked before being loaded into the Silver tables.

The main activities include:

- Converting values to the correct data types
- Removing unnecessary spaces
- Standardising text values
- Checking for duplicate records
- Checking for missing critical values
- Checking waiting-time values
- Checking dates
- Checking patient relationships
- Checking department relationships

---

## 3. Silver Tables

The cleaned data is stored in:

- `silver.patients`
- `silver.departments`
- `silver.encounters`

These tables contain the data that passed the main validation rules.

The final Silver encounter table contains:

**29,933 records**

---

## 4. Quarantine

Not every Bronze record is suitable for the clean Silver tables.

Records with critical data-quality problems are kept separately in:

`silver.encounters_quarantine`

This means the records are **not simply deleted**.

They can still be reviewed later.

The quarantine contains:

- Invalid records
- Duplicate records

Final quarantine count:

**102 records**

---

## 5. Duplicate Handling

Duplicate encounter records were identified during the data-quality checks.

The Bronze encounter data contained:

**35 extra duplicate records**

One record was kept for the Silver layer and the additional duplicate copies were quarantined.

The final Silver encounter table therefore contains one record per encounter.

---

## 6. Final Reconciliation

The Silver layer was compared against the original Bronze encounter data.

| Layer | Records |
|---|---:|
| Bronze encounters | 30,035 |
| Silver encounters | 29,933 |
| Quarantine | 102 |
| Silver + Quarantine | 30,035 |

The numbers reconcile:

**29,933 + 102 = 30,035**

This confirms that all Bronze encounter records are accounted for.

---

## 7. Moving to Gold

After the data has been cleaned and validated, the Silver layer feeds the Gold layer.

The Gold layer turns the cleaned data into a business-ready analytical model.

The overall flow is:

```text
Raw CSV Files
      ↓
Bronze
      ↓
Silver
      ↓
Gold
```

---

## Key Point

The Silver layer is the **cleaning and validation layer**.

Its purpose is to turn raw Bronze data into reliable data that can safely be used to build the Gold analytical model.
