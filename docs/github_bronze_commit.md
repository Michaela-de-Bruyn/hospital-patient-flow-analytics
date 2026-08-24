# GitHub setup — Bronze checkpoint

From the repository root:

```bash
git init
git add .
git status
git commit -m "feat: build bronze ingestion layer"
git branch -M main
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```

Before pushing, check:

- No SQL Server database files are included.
- No passwords, credentials or connection strings are included.
- The raw CSVs are synthetic.
- `01_bronze_ingestion.sql` is included.
- README describes the Bronze checkpoint.
