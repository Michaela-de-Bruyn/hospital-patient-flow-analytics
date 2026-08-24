# Gold Star Schema

## Purpose

The Gold layer is the business-ready analytical layer of the hospital waiting-time project.

The model uses a **star schema**. The `fact_encounters` table is in the centre and connects to descriptive dimension tables.

## Fact Grain

The grain of the fact table is:

> One row in `gold.fact_encounters` represents one hospital encounter.

This is important because every measure and analysis is based on an individual encounter.

## Fact Table

### `gold.fact_encounters`

The fact table contains the main event and measures used for analysis.

It contains:

- `encounter_key` — primary key
- `patient_key` — link to the patient dimension
- `department_key` — link to the department dimension
- `date_key` — link to the date dimension
- `arrival_key` — link to the arrival method dimension
- `encounter_id`
- `acuity_level`
- `outcome`
- `waiting_time_minutes`
- `staff_on_duty`
- `daily_patient_volume`
- `length_of_stay_days`
- `patient_satisfaction`
- `wait_band`
- `is_weekend`

The expected fact-table count is **29,933 encounters**.

## Dimension Tables

### `gold.dim_patient`

Contains one row per patient.

It provides descriptive information such as:

- Age
- Gender
- Province
- Funding type

Expected rows: **12,000**

### `gold.dim_department`

Contains one row per hospital department.

It provides:

- Department name
- Service line
- Target waiting time

Expected rows: **6**

### `gold.dim_date`

Contains one row per calendar date.

It provides:

- Day
- Month
- Quarter
- Year
- Week
- Weekend information

The project data covers 2025, giving **365 dates**.

### `gold.dim_arrival_method`

Contains one row per standardised arrival method.

The four methods are:

- Walk-in
- Ambulance
- Scheduled
- Referral

Expected rows: **4**

## Relationships

Each dimension connects to the fact table using a surrogate key.

The relationships are:

```text
dim_patient          1 ─────────── * fact_encounters

dim_department       1 ─────────── * fact_encounters

dim_date             1 ─────────── * fact_encounters

dim_arrival_method   1 ─────────── * fact_encounters
```

This means one patient, department, date, or arrival method can be associated with many hospital encounters.

## Why This Model Is Useful

The star schema makes business analysis easier because descriptive information is separated from encounter-level measures.

For example, the model can be used to analyse:

- Average waiting time by department
- Waiting time by province
- Waiting time by arrival method
- Waiting time by month
- Waiting time on weekends versus weekdays
- Waiting time by patient acuity
- Patient satisfaction compared with waiting time
- Waiting time compared with staff levels
- Waiting time compared with daily patient volume

## Architecture

The Gold model is the final structured layer of the data warehouse:

```text
Raw CSV Files
      ↓
   Bronze
      ↓
   Silver
      ↓
    Gold
      ↓
Star Schema
      ↓
Business Analysis / Power BI
```

## Diagram

The accompanying `gold_star_schema.png` file visually shows the fact table, dimensions, keys, and one-to-many relationships.
