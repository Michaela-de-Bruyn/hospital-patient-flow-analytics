[README_Hospital_Patient_Flow.md](https://github.com/user-attachments/files/31383910/README_Hospital_Patient_Flow.md)
# Hospital Patient Flow & Waiting Time Analytics

## 📌 Project Overview

This project demonstrates an end-to-end Data Engineering workflow for analysing hospital patient flow and waiting times.

The project starts with synthetic CSV data containing patients, hospital departments and encounter-level records. The data is transformed through a **Bronze → Silver → Gold** architecture and prepared for business reporting.

The project was first developed and validated using SQL Server and was then implemented in **Databricks using Lakeflow** to demonstrate pipeline orchestration and dependency management.

The final Gold layer is designed to support a reporting dashboard focused on hospital waiting times, patient flow and operational performance.

> **Note:** All project data is synthetic and created for portfolio and interview purposes.

---

## 🏗️ Architecture

```text
CSV SOURCE
    ↓
🥉 BRONZE
Raw / minimally changed data
    ↓
🥈 SILVER
Cleaning + validation
    ├── Clean records
    └── Quarantine
    ↓
🥇 GOLD
Star schema
    ↓
📊 DASHBOARD
Planned next phase
```

The Databricks implementation uses **Lakeflow** to orchestrate the Silver and Gold transformations and represent dataset dependencies.

---

## 📂 Source Data

The project uses three synthetic CSV files:

| File | Description |
|---|---|
| `dim_patients.csv` | Patient demographic and funding information |
| `dim_departments.csv` | Hospital department reference data |
| `fact_encounters_dirty.csv` | Hospital encounter and waiting-time data containing data-quality issues |

**Fact grain:** One row represents one hospital encounter.

---

# 🥉 Bronze Layer

The Bronze layer preserves the source data as closely as possible.

### Bronze tables

```text
bronze.patients_raw
bronze.departments_raw
bronze.encounters_raw
```

### Purpose

- Load the CSV source data
- Preserve source values
- Check ingestion and row counts
- Profile data-quality issues
- Provide a reliable source for downstream transformations

The Bronze layer does not perform the main cleaning or business transformations.

**Bronze encounter count: 30,035 records.**

See the Bronze diagram and documentation under `diagrams/` and `docs/`.

---

# 🥈 Silver Layer

The Silver layer is the **cleaning and validation layer**.

### Main transformations

- Data-type conversion
- Trimming unnecessary spaces
- Standardising text values
- Duplicate detection and handling
- Missing-value handling
- Waiting-time validation
- Date conversion
- Derived fields such as weekend flags and wait bands
- Data-quality quarantine

### Silver datasets

```text
silver.pipeline_patients
silver.pipeline_departments
silver.pipeline_encounters
silver.pipeline_encounters_quarantine
```

### Final Silver results

| Dataset | Records |
|---|---:|
| Patients | 12,000 |
| Departments | 6 |
| Clean encounters | 29,933 |
| Quarantine | 102 |

### Reconciliation

```text
29,933 clean encounters
+   102 quarantined records
-------------------------
30,035 Bronze records
```

This confirms that all Bronze encounter records are accounted for.

Invalid and duplicate records are retained in quarantine rather than simply deleted.

---

# 🥇 Gold Layer

The Gold layer is the **business-ready analytical layer**.

The model uses a **star schema**, with the encounter fact table at the centre.

### Gold datasets

```text
gold.pipeline_fact_encounters

gold.pipeline_dim_patient
gold.pipeline_dim_department
gold.pipeline_dim_arrival_method
gold.pipeline_dim_date
```

### Gold results

| Dataset | Records |
|---|---:|
| Patient dimension | 12,000 |
| Department dimension | 6 |
| Arrival method dimension | 5 |
| Date dimension | 365 |
| Encounter fact | 29,933 |

The arrival-method dimension contains an `Unknown` member with key `0`, so missing arrival methods can remain in the fact table.

### Analytical questions supported

- Average waiting time by department
- Waiting time by province
- Waiting time by arrival method
- Waiting time by month
- Weekend vs weekday waiting time
- Waiting time by patient acuity
- Patient satisfaction vs waiting time
- Waiting time vs staffing levels
- Waiting time vs daily patient volume

---

# ☁️ Databricks & Lakeflow

The validated SQL model was then implemented in **Databricks**.

Lakeflow is used to orchestrate the transformations and build a dependency graph from the dataset references.

Example:

```text
pipeline_patients
       ↓
pipeline_dim_patient
```

and:

```text
pipeline_encounters
       ├──────────────► pipeline_fact_encounters
       │
       ▼
pipeline_dim_arrival_method
```

The pipeline was successfully executed.

### Final pipeline validation

| Dataset | Result |
|---|---:|
| `silver.pipeline_patients` | 12,000 |
| `silver.pipeline_departments` | 6 |
| `silver.pipeline_encounters` | 29,933 |
| `silver.pipeline_encounters_quarantine` | 102 |
| `gold.pipeline_dim_patient` | 12,000 |
| `gold.pipeline_dim_department` | 6 |
| `gold.pipeline_dim_arrival_method` | 5 |
| `gold.pipeline_dim_date` | 365 |
| `gold.pipeline_fact_encounters` | 29,933 |

The output counts matched the validated data model.

Pipeline screenshots are stored under:

```text
databricks/diagrams/
```

---

# 🔎 Key Data-Quality Decisions

### Duplicate encounters

Duplicate `encounter_id` values were identified using `ROW_NUMBER()`. One record is retained and additional duplicate copies are quarantined.

### Invalid waiting times

Waiting times outside the accepted **0–720 minute** range are treated as invalid for the clean encounter dataset.

### Missing arrival methods

Missing arrival methods are represented by:

```text
arrival_method_key = 0
arrival_method = Unknown
```

This keeps the encounter in the fact table while maintaining a valid dimension relationship.

The arrival-method dimension therefore contains:

```text
0 = Unknown
1 = Ambulance
2 = Referral
3 = Scheduled
4 = Walk-in
```

---

# 🛠️ Technologies Used

### Data Engineering
- SQL
- SQL Server
- Databricks
- Lakeflow
- Delta tables
- Medallion architecture
- Dimensional modelling
- Star schema

### Data Quality
- Data profiling
- Duplicate detection
- Null handling
- Data-type validation
- Business-rule validation
- Quarantine handling
- Reconciliation checks

### Documentation & Version Control
- Git
- GitHub
- Draw.io
- Markdown

### Planned Analytics
- Power BI

---

# 📁 Repository Structure

```text
hospital-patient-flow/
│
├── data/
│   └── raw/
│
├── diagrams/
│
├── docs/
│
├── sql/
│   └── SQL Server implementation
│
└── databricks/
    ├── sql/
    │   ├── 01_silver_patients.sql
    │   ├── 02_silver_departments.sql
    │   ├── 03_silver_encounters.sql
    │   ├── 04_silver_quarantine.sql
    │   ├── 05_gold_dim_patient.sql
    │   ├── 06_gold_dim_department.sql
    │   ├── 07_gold_dim_arrival_method.sql
    │   ├── 08_gold_dim_date.sql
    │   └── 09_gold_fact_encounters.sql
    │
    ├── diagrams/
    │   ├── lakeflow_pipeline_graph.png
    │   ├── lakeflow_pipeline_performance.png
    │   └── lakeflow_pipeline_tables.png
    │
    └── docs/
        ├── DATABRICKS_PIPELINE_README.md
        ├── PIPELINE_VALIDATION.md
        └── PIPELINE_DIAGRAMS.md
```

---

# 📊 Dashboard — Next Phase

The pipeline and Gold analytical model are complete and validated.

The **next phase is to build the Power BI dashboard** using the Gold layer.

The dashboard will focus on:

### Waiting Time
- Average waiting time
- Waiting time by department
- Waiting-time trends
- Waiting-time bands

### Patient Flow
- Patient volume over time
- Volume by department
- Arrival-method analysis

### Operational Performance
- Waiting time vs staffing
- Weekend vs weekday performance
- Patient satisfaction vs waiting time
- Waiting time vs daily patient volume

The dashboard will use the **Gold fact and dimension tables**, rather than raw Bronze data.

> **Dashboard status: Planned / next phase.**

---

# 🎯 Project Outcome

This project demonstrates the progression from raw source data to a validated analytical data platform:

```text
Raw CSV
   ↓
Bronze
   ↓
Data Quality Investigation
   ↓
Silver
   ↓
Quarantine
   ↓
Gold Star Schema
   ↓
Databricks Lakeflow
   ↓
Validated Pipeline
   ↓
📊 Dashboard
```

The project demonstrates practical skills in:

- Understanding source data
- Designing a Medallion architecture
- Writing SQL transformations
- Performing data-quality checks
- Handling duplicates and invalid data
- Building a dimensional model
- Creating pipeline dependencies
- Using Databricks and Lakeflow
- Validating pipeline outputs
- Documenting technical decisions
- Managing code with Git/GitHub

---

# 🚀 Future Improvements

- Build the Power BI dashboard
- Add pipeline scheduling
- Add automated data-quality expectations
- Add monitoring and alerts
- Add incremental processing
- Add more detailed audit logging
- Add CI/CD integration for Databricks code
