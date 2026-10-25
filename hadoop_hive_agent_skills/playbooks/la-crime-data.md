# Playbook: LA Open Data Crime Dataset

## Assignment goals

Source URL supplied in the assignment:
https://data.lacity.org/api/views/2nrs-mtv8/rows.csv

Database: `crime_data_db`

Required analyses:
- View a few records.
- Total crimes reported.
- Crimes by area.
- Most common crime descriptions.
- Crime trends by year.
- Filter crimes with a specific weapon.
- Victim age groups.

## Step 0 — Download and inspect

Download the CSV using an approved tool/network path. Confirm the download is a CSV and not an HTML error page. Record file size and inspect the header and representative rows.

Do not assume the live dataset schema is unchanged. Confirm exact names and formats for:
- crime/report identifier, if present;
- area or area name;
- crime description;
- relevant occurrence/report date;
- weapon field;
- victim age.

If the data contains coded values, consult the dataset's official metadata/data dictionary before interpreting them. Do not infer weapon semantics from a code without evidence.

## Step 1 — HDFS and database

1. Upload the CSV to a project-specific HDFS path.
2. Verify file size and readability.
3. Create database `crime_data_db` if needed.
4. Create an external raw table with all fields in the correct order, initially using STRING types when appropriate for robust ingestion.
5. Configure the correct CSV SerDe and header handling for the installed Hive distribution.
6. Verify with `DESCRIBE`, a limited sample, and `COUNT(*)`.

Example database setup:
```sql
CREATE DATABASE IF NOT EXISTS crime_data_db;
USE crime_data_db;
```

Do not use a destructive `DROP DATABASE ... CASCADE` to resolve naming conflicts. Inspect existing objects first.

## Step 2 — Clean and type

For the assignment's minimum scope, a raw table may be sufficient for basic grouping if fields are reliably parsed. For stronger data-engineering practice, create a curated managed table with:
- an appropriate date/timestamp for the verified date field;
- numeric victim age only after checking invalid/sentinel values;
- trimmed/canonicalized area and description fields where justified;
- raw source values retained or traceable.

Measure parsing failures before relying on typed fields. Preserve the original raw table and document all cleaning decisions.

## Step 3 — Required queries

### A. View a few records
Use `SELECT ... LIMIT 10` with relevant columns. Avoid dumping the full dataset.

### B. Total crimes reported
Start with `COUNT(*)` if each row represents one crime record. If duplicate identifiers or multiple rows per incident exist, inspect the official definition and decide whether the metric should count rows, distinct report IDs, or distinct incidents. State the definition.

### C. Crimes by area
Group by the verified area column and count records. Include or explicitly exclude missing/unknown areas.

### D. Most common crime descriptions
Group by the verified description field, count records, order descending, and use the description as a deterministic tie-breaker. Decide whether blank descriptions are excluded.

### E. Crime trends by year
Use the correct verified date field and extract the year. Distinguish occurrence date from report date if both exist; choose the one that matches the assignment's intent and state it. Check date parsing failures.

### F. Filter crimes with a specific weapon
Inspect actual values first:
```sql
SELECT <weapon_column>, COUNT(*) AS records
FROM crime_data_db.<curated_or_raw_table>
GROUP BY <weapon_column>
ORDER BY records DESC
LIMIT 30;
```
Then filter using the exact observed code/label. If the task expects a specific weapon but does not identify which, ask the user/instructor or select one clearly labelled as an example and explain the choice. Do not fabricate a weapon field.

### G. Victim age groups
Inspect minimum, maximum, NULLs, zeros, and sentinel values before binning. Agree on boundaries and document them. Example only:
- under 18;
- 18–24;
- 25–34;
- 35–44;
- 45–54;
- 55–64;
- 65+;
- unknown/invalid.

These are suggested reporting bins, not official dataset categories. Ensure boundaries do not overlap or leave gaps. Do not treat unknown or invalid age codes as true ages.

## Step 4 — Verify and submit

- Record raw row count and curated row count.
- Quantify invalid dates and ages.
- Save SQL and actual query outputs.
- Include dataset source, download date, environment, schema decisions, query definitions, results, and limitations.
- If online data changes over time, record the downloaded snapshot's date and preserve the file used for the submitted results.
- Never invent result values if the query was not run.

## Suggested deliverables

- `01_download_and_hdfs.md` or shell script.
- `02_create_database_and_raw_table.sql`.
- `03_cleaning.sql` if a curated layer is created.
- `04_analysis.sql` with all required queries.
- `validation.md`.
- `final_report.md` with outputs captured from the actual run.
