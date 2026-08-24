# Silver Layer

## Purpose

The Silver layer cleans and validates the raw Bronze data so that it can be used for reliable analysis.

The main focus was:

- Cleaning data types
- Standardising text values
- Handling invalid records
- Identifying duplicates
- Checking relationships between tables
- Keeping invalid records in a quarantine table
- Making sure all Bronze records are accounted for

---

## Silver Tables

The Silver layer contains:

| Table | Purpose | Expected Rows |
|---|---|---:|
| `silver.patients` | Clean patient information | 12,000 |
| `silver.departments` | Clean department information | 6 |
| `silver.encounters` | Clean hospital encounters | 29,933 |
| `silver.encounters_quarantine` | Records excluded from the clean data | 102 |

---

## Patient Cleaning

The Bronze patient data was transformed into `silver.patients`.

The transformation included:

- Converting `patient_id` to an integer
- Converting `age` to an integer
- Removing extra spaces from text fields
- Converting blank text values to NULL

### Validation

The following checks were performed:

- Duplicate patient IDs
- Invalid ages
- NULL patient IDs

Expected results:

- 12,000 patients
- 0 duplicate patient IDs
- 0 invalid ages

---

## Department Cleaning

The Bronze department data was transformed into `silver.departments`.

The transformation included:

- Removing extra spaces
- Converting `target_wait_minutes` to an integer
- Standardising department information

### Validation

Expected result:

- 6 departments
- 6 distinct department IDs

---

## Encounter Data Quality

The Bronze encounter table contained:

**30,035 records**

The data was checked for:

- Missing values
- Duplicate encounter IDs
- Invalid waiting times
- Invalid dates
- Invalid patient relationships
- Invalid department relationships

---

## Data Quality Issues Found

The main critical issues identified were:

| Issue | Records |
|---|---:|
| Missing patient ID | 45 |
| Invalid or missing arrival datetime | 12 |
| Invalid waiting time | 10 |
| Duplicate copies | 35 |
| **Total quarantined** | **102** |

The waiting-time validation used a valid range of:

**0–720 minutes**

---

## Encounter Transformation

The encounter data was cleaned and standardised.

The transformation included:

- Converting `encounter_id` to an integer
- Converting `patient_id` to an integer
- Converting `arrival_datetime` to `DATETIME2`
- Converting numeric fields to appropriate numeric data types
- Standardising arrival methods
- Removing extra spaces
- Creating day-of-week information
- Creating month information
- Creating a weekend flag
- Creating waiting-time bands

### Arrival Method Standardisation

Arrival methods were standardised into:

- Walk-in
- Ambulance
- Scheduled
- Referral

### Waiting-Time Bands

Waiting times were grouped into:

- `<=60 min`
- `61-120 min`
- `121-180 min`
- `>180 min`

---

## Duplicate Handling

Duplicate encounter IDs were identified in the Bronze data.

There were:

**35 extra duplicate records**

For each duplicated encounter:

- One record was kept in Silver
- The additional copy was moved to the quarantine table

This means the Silver encounter table contains only one record per encounter.

Expected result:

**0 duplicate encounter IDs in Silver**

---

## Quarantine

Invalid records were not simply deleted.

They were stored in:

`silver.encounters_quarantine`

Each quarantined record includes a reason explaining why it was excluded.

The quarantine contains:

- 67 critical invalid records
- 35 duplicate copies

Total:

**102 quarantined records**

This allows the original data-quality issues to be investigated later.

---

## Final Reconciliation

The final Silver layer was reconciled against the Bronze layer.

| Layer | Records |
|---|---:|
| Bronze encounters | 30,035 |
| Silver encounters | 29,933 |
| Quarantine | 102 |
| Silver + Quarantine | 30,035 |

The reconciliation confirmed that:

**29,933 + 102 = 30,035**

Therefore, all Bronze encounter records are accounted for.

---

## Final Silver Validation

The following checks returned the expected results:

- No duplicate encounter IDs
- No invalid waiting times
- No invalid arrival dates
- No unmatched patients
- No unmatched departments

The Silver layer is therefore ready to be used to build the Gold analytical model.
