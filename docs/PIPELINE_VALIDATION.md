# Databricks Lakeflow Pipeline — Validation

## Final run

The pipeline completed successfully.

### Silver

- `silver.pipeline_patients` → 12,000
- `silver.pipeline_departments` → 6
- `silver.pipeline_encounters` → 29,933
- `silver.pipeline_encounters_quarantine` → 102

### Gold

- `gold.pipeline_dim_patient` → 12,000
- `gold.pipeline_dim_department` → 6
- `gold.pipeline_dim_arrival_method` → 5
- `gold.pipeline_dim_date` → 365
- `gold.pipeline_fact_encounters` → 29,933

## Reconciliation

```text
Bronze encounters       30,035
Silver encounters       29,933
Quarantine records          102
                         -------
Total                    30,035
```

The Lakeflow graph showed the expected upstream/downstream dependencies between the Silver and Gold transformations.
