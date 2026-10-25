# Troubleshooting, Validation, and Delivery

## Diagnose errors systematically

When a command fails:
1. Preserve the exact error message, omitting secrets.
2. Identify the failing layer: local filesystem, HDFS, client connection, Hive parser, metastore, SerDe, execution engine, permissions, schema, or data conversion.
3. Reproduce with the smallest safe command or query.
4. Check version-specific syntax and function support.
5. Inspect schema, table location, SerDe properties, and sample input.
6. Make one change at a time.
7. Rerun the smallest validation test before resuming the pipeline.
8. Record the root cause and fix.

Do not respond to every error by deleting a table, changing permissions broadly, restarting services, or recreating the entire environment.

## Common failure modes

- **Table exists:** inspect it with `DESCRIBE FORMATTED`; verify location and ownership before replacing it.
- **No rows or unexpected count:** verify HDFS path, table location, delimiter, header handling, file permissions, and whether the data landed in a different database.
- **Shifted columns:** likely CSV parsing/quoting or schema-order issue; compare source rows with Hive results.
- **Many NULL timestamps:** inspect raw examples and use a tested format-specific parser.
- **Invalid column:** use `DESCRIBE` and exact observed field names; account for punctuation/spaces in source headers by defining clean aliases in table DDL.
- **Permission denied:** identify the user and required path permission; request least-privilege access instead of making paths world-writable.
- **Slow query:** inspect `EXPLAIN`, input size, file count, selected columns, partition filters, and engine startup overhead before changing configuration.
- **Dynamic partition error:** check supported Hive settings, target DDL, partition column order, and whether the SELECT returns the partition value in the expected position.

## Data-quality validation checklist

For raw ingestion:
- [ ] HDFS path and file size verified.
- [ ] Table location points to intended directory.
- [ ] Header and quoting handled correctly.
- [ ] Sample rows match source.
- [ ] Row count recorded, with count methodology documented.

For cleaning:
- [ ] Source count and target count reconciled.
- [ ] Timestamp conversion failures quantified.
- [ ] Null/blank normalization documented.
- [ ] Negative and zero durations checked.
- [ ] Station normalization sampled and verified.
- [ ] Duplicates investigated according to a documented definition.
- [ ] Data types and storage format confirmed.

For analysis:
- [ ] Every requested metric has executable SQL.
- [ ] Metric definition and exclusions are stated.
- [ ] NULL behavior is understood.
- [ ] Ranking ties are handled deterministically.
- [ ] Results are captured from actual execution.

For partitioning:
- [ ] Partition values are populated correctly.
- [ ] Expected partitions are present.
- [ ] Partitioned and baseline counts match.
- [ ] Query plan confirms partition pruning where expected.
- [ ] Benchmark conditions and actual timings are recorded.

## Submission structure

Recommended project layout:

```text
project/
  README.md
  scripts/
    01_environment_checks.sh
    02_hdfs_upload.sh
    03_create_raw_table.sql
    04_create_cleaned_table.sql
    05_analysis.sql
    06_partition_and_benchmark.sql
  results/
    validation.md
    query_outputs/
    explain_plans/
    benchmark.csv
  report/
    final_report.md
```

Do not create fake output logs. If a query could not be run, provide the SQL and mark the result “not executed” or “pending environment access.”

## Report format

Include:
1. Objective and dataset source.
2. Environment and versions.
3. Data ingestion and table schema.
4. Cleaning rules and data-quality findings.
5. SQL queries and results for each question.
6. Storage and partitioning design.
7. Benchmark methodology and measured results.
8. Limitations, assumptions, and conclusion.

Use screenshots only when required by the instructor. Prefer readable terminal output and query results that show the command and result together. Remove credentials and unrelated personal data before submission.
