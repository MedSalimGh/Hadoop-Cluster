# Playbook: Divvy Bikes Trip Data

## Assignment goals

1. Upload the provided CSV to HDFS.
2. Create external table `divvy_trips_raw`.
3. Verify raw data.
4. Create managed ORC table `divvy_trips_cleaned`.
5. Parse `start_time` and `end_time` into timestamps and uppercase station names.
6. Answer the required analytical questions.
7. Create `divvy_trips_partitioned` partitioned by starting date.
8. Compare the Aug. 15 trip count and query time on partitioned versus non-partitioned data.

## Step 0 — Inspect the dataset

Do not assume the attachment filename or field schema. Inspect its header and sample rows. Confirm whether the actual fields correspond to `start_time`, `end_time`, station names, bike type, rider type, and start/end station identifiers. Map the assignment terminology to the actual column names.

Inspect date range and formats. The assignment's “Aug. 15” does not specify a year in the prompt; select the year supported by the data or ask the instructor/user. Do not silently pick one.

## Part 1 — Load raw data

1. Upload CSV to a project-specific HDFS directory.
2. Verify HDFS file exists and size is plausible.
3. Create `divvy_trips_raw` as an external table with all source columns defined in file order.
4. Use a CSV-aware SerDe appropriate for the installed distribution. Correctly handle quote/escape characters and header row.
5. Run `DESCRIBE`, `SELECT ... LIMIT 10`, and `COUNT(*)`.
6. Record raw row count and any parsing anomalies.

Use `CREATE EXTERNAL TABLE` DDL from `references/hive-ingestion-and-schema.md` as a template only.

## Part 2 — Clean into ORC

Create a managed table `divvy_trips_cleaned` stored as ORC. Use explicit columns and appropriate types. For the required timestamps, test conversion expressions against real samples before inserting the full dataset. Uppercase station names using `UPPER(TRIM(...))`, with a documented policy for blanks.

Recommended workflow:
1. Query counts of empty/nonempty and unparseable timestamp values.
2. Create cleaned table.
3. Insert using an explicit target/select column list.
4. Compare row counts.
5. Validate data types with `DESCRIBE`.
6. Check `end_time < start_time`, zero-duration records, missing stations, and duration outliers.
7. If invalid rows are retained, document how they affect metrics; if excluded, quantify and justify exclusions.

Avoid silently discarding records. For coursework, preserving rows while representing invalid conversions as NULL may be preferable, unless the assignment specifies a rejection policy.

## Part 3 — Analysis

Use the actual field names and explicitly define duration. Unless the instructor says otherwise, report average duration in minutes using valid, non-negative trip durations and state the exclusion rule.

Required outputs:
1. Average trip duration in minutes.
2. Number of distinct non-null bike types.
3. Top five start stations by trip count.
4. Trip counts grouped by year and month.
5. Busiest starting hour (0–23), including tie handling.
6. Average trip duration grouped by rider category (e.g., Subscribers vs Customers), using exact source values after inspecting category labels.
7. Top ten start-to-end station routes.
8. Longest valid trip duration per start station.

Use SQL patterns from `references/cleaning-and-analytics.md`. For route ranking, decide whether routes with missing station names are excluded. For “longest trip duration for each start station,” the default interpretation is the maximum duration value per station; if the instructor expects the details of the trip row, use a window function and document tie behavior.

## Part 4 — Date partitioning and benchmark

Create `divvy_trips_partitioned` using `start_date` as a partition column derived from `start_time`. Prefer a DATE partition if supported; otherwise use ISO `yyyy-MM-dd` string values. Keep the partition column separate from non-partition columns in the table DDL.

Load from cleaned table with explicit columns. Confirm dynamic partition settings and target column order for the installed Hive version. Verify partition list and counts.

For Aug. 15:
- Pick the correct year from the dataset or confirmed assignment context.
- On the cleaned table, filter using a half-open timestamp range: start of Aug. 15 inclusive, start of Aug. 16 exclusive.
- On the partitioned table, filter directly on `start_date`.
- Confirm both queries return the same count.
- Capture `EXPLAIN` output and check partition pruning.
- Repeat timings, note first-run versus warm-run effects, and do not invent execution times.

## Suggested deliverables

- HDFS upload command.
- Raw and cleaned table DDL.
- Transformation SQL.
- One SQL file with all eight analytical queries.
- Partition table DDL/load SQL.
- Count comparison and benchmark table.
- Short explanation of partition pruning and observed performance, based on actual evidence.
