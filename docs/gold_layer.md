# Gold Layer

## Purpose

The Gold layer contains business-ready analytical data.

The Silver data is transformed into a simple star schema that can be used for analysis and reporting.

The main purpose is to make the data easier to analyse in tools such as Power BI.

---

## Gold Star Schema

The Gold model contains:

- One central fact table
- Four dimension tables

```text
                    dim_patient
                         |
                         |
                         v
dim_date -----> fact_encounters <----- dim_department
                         ^
                         |
                         |
                dim_arrival_method
