# ORC, Partitioning, and Query Performance

## ORC

ORC is a columnar format designed for efficient Hive workloads. It supports type-aware encoding, compression, metadata, and row/stripe skipping for suitable predicates. Use it for curated analytical tables when the environment supports it.

Example:
```sql
CREATE TABLE <database>.divvy_trips_cleaned (
  -- explicit typed columns
)
STORED AS ORC;
```

Do not assume ORC automatically makes every query faster. Small datasets, execution overhead, file layout, and query shape all affect observed timings. Confirm the table's actual storage format and inspect output files.

Official reference: https://hive.apache.org/docs/latest/language/languagemanual-orc/

## Partitioning principles

Partition on a column commonly used for selective filters, such as a start date. Avoid very high-cardinality partition keys (such as timestamps down to the second) that create many tiny partitions/directories. Consider partition sizes and how often the data is queried.

For a date-partitioned table, a common design is a `DATE` or ISO date string partition column. Confirm support and conventions in the installed Hive version. The partition column is generally a separate partition column in the table definition rather than a normal data column; avoid duplicate/conflicting definitions.

Example pattern:
```sql
CREATE TABLE <database>.divvy_trips_partitioned (
  -- all non-partition columns with explicit types
)
PARTITIONED BY (start_date DATE)
STORED AS ORC;
```

If the installed Hive version does not support `DATE` partition columns as expected, use a canonical `STRING` such as `yyyy-MM-dd` and document it. Test the DDL before bulk loading.

Populate with an explicit partition column:
```sql
INSERT INTO TABLE <database>.divvy_trips_partitioned
PARTITION (start_date)
SELECT
  -- explicit non-partition columns in target order,
  TO_DATE(start_time) AS start_date
FROM <database>.divvy_trips_cleaned
WHERE start_time IS NOT NULL;
```

Check dynamic partition configuration and syntax for the installed version. Ensure the SELECT column order matches the target's non-partition columns followed by the partition value as required by the relevant Hive syntax. Run a small test first if the table is new.

## Partition pruning

A query must filter on the partition column in a form the optimizer can use. For example:

```sql
SELECT COUNT(*)
FROM <database>.divvy_trips_partitioned
WHERE start_date = CAST('2024-08-15' AS DATE);
```

Compare with a non-partitioned table query using the equivalent timestamp range:

```sql
SELECT COUNT(*)
FROM <database>.divvy_trips_cleaned
WHERE start_time >= CAST('2024-08-15 00:00:00' AS TIMESTAMP)
  AND start_time < CAST('2024-08-16 00:00:00' AS TIMESTAMP);
```

Use the dataset's actual year. If the assignment says “Aug. 15” but the year is unclear, inspect dataset dates or ask. Do not invent a year. Using a half-open timestamp range avoids missing times after midnight and is generally clearer than applying a function to the timestamp column.

Verify with `EXPLAIN` that partition pruning occurs, and inspect which partitions/files are scanned where the engine exposes this information.

## Fair benchmarking

1. Ensure both queries return the same count and refer to the same logical date and rows.
2. Use the same engine, resources, session configuration, and client.
3. Run both queries more than once where practical; record each elapsed time and whether the run was first/cold or repeated/warm.
4. Alternate query order or otherwise account for caching and startup effects.
5. Do not compare a cached query with a cold query and call the difference a partitioning result.
6. Capture `EXPLAIN` output and explain the expected scan reduction.
7. Record dataset size, row count, number of partitions/files, file format, and environment where available.
8. If the table is small or overhead dominates, state that timing differences may be noisy.
9. Never fabricate timings or claim a speedup without measured evidence.

Suggested results table:

| Run | Table | Query | Count | Elapsed time | Notes |
|---|---|---|---:|---:|---|
| 1 | cleaned | date range | measured output | measured output | cold/warm noted |
| 1 | partitioned | partition filter | measured output | measured output | pruning checked |

## Statistics and plan inspection

Use `EXPLAIN <query>` where supported. After loading data, consider `ANALYZE TABLE ... COMPUTE STATISTICS` and partition statistics if the Hive version supports it and the workload benefits. Statistics can help the optimizer, but do not blindly run expensive maintenance commands on every table.

## Small files

Many tiny files increase metadata and task overhead. Check file counts and sizes after writes. Compact only when appropriate, supported, and safe. Never recommend a costly optimization merely because it sounds advanced.
