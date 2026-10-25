---
name: hadoop-hive-data-engineering
description: Plan, implement, validate, troubleshoot, analyze, and optimize Hadoop HDFS + Apache Hive data pipelines and coursework. Use when a task involves CSV ingestion, HDFS, Hive tables, SQL analysis, ORC, partitioning, benchmarking, or a data-engineering report.
---

# Hadoop & Hive Data Engineering Skill

## Mission

Deliver a reproducible, evidence-backed Hadoop/Hive solution, not merely plausible SQL. Work incrementally: inspect, plan, implement, validate, analyze, optimize, and document. Adapt to the actual environment and dataset.

## Mandatory rules

1. **Never invent facts.** Do not invent filenames, schemas, column names, table locations, Hive versions, successful outputs, row counts, execution times, or benchmark conclusions.
2. **Inspect before writing.** Check the input file, headers, sample rows, delimiter, quote/escape rules, encoding, date/time formats, null tokens, and whether a header exists.
3. **Discover the environment.** Identify available HDFS/Hive clients, versions, execution engine, database, warehouse settings, and permissions before relying on version-specific syntax.
4. **Preserve source data.** Treat raw data as immutable. Never overwrite or delete the source dataset to make a pipeline easier.
5. **Make reruns safe.** Explain whether each command is idempotent. Prefer explicit staging paths and controlled table lifecycle operations. Do not drop existing tables or paths without confirming ownership and consequences.
6. **Separate raw and curated layers.** Raw ingestion should preserve original values. Cleaned tables should use appropriate types and documented transformations.
7. **Validate every stage.** A command exit code alone is not proof of correctness. Compare row counts, inspect samples, validate types, and test edge cases.
8. **Respect compatibility.** Use only functions and syntax supported by the installed Hive version and execution engine. If uncertain, verify with local help, `DESCRIBE FUNCTION`, documentation, or a small test query.
9. **Optimize only with evidence.** Explain the expected mechanism, inspect `EXPLAIN`, benchmark equivalent queries, and report the conditions under which timings were measured.
10. **Be honest about execution.** Distinguish code generated, commands attempted, commands successful, and results independently verified. If the agent cannot execute commands, provide a runnable plan and mark results as not executed.
11. **Protect sensitive data.** Do not print credentials, tokens, or private configuration values. Avoid unnecessarily exposing personally identifying data in logs or reports.
12. **Keep work reproducible.** Save SQL scripts, command logs, assumptions, validation outputs, and the final report in a clearly named project directory.

## Standard workflow

### Phase 1 — Understand the task
- Extract deliverables, table names, required analyses, date filters, submission format, and deadline.
- Identify ambiguity: date semantics, duration definition, duplicate definition, null policy, station/route tie handling, and expected timezone.
- Ask only for information that blocks progress. Otherwise inspect the environment and make clearly documented provisional assumptions.

### Phase 2 — Discover
- Inspect the local input files and available command-line tools.
- Check Hadoop/Hive versions and whether `hive`, `beeline`, or a distribution-specific client is available.
- Inspect file metadata and representative rows without dumping the entire dataset.
- Determine column types and formats from observed data, not names alone.

### Phase 3 — Plan
Create a short plan with:
- raw HDFS location;
- raw external table schema and CSV SerDe settings;
- cleaned managed table schema and format;
- transformations and rejected-row policy;
- required queries and expected output columns;
- partition key and rationale;
- validation checks;
- benchmark method;
- artifacts to submit.

### Phase 4 — Implement in small steps
Run one logical stage at a time. After each stage:
- capture command status;
- inspect the result;
- validate a relevant invariant;
- stop and diagnose if validation fails.
Do not proceed by stacking unverified commands.

### Phase 5 — Analyze
For each requested metric, document its definition, SQL, result, and interpretation. Handle NULLs explicitly and include deterministic tie-breakers where the task requests rankings.

### Phase 6 — Optimize
- Start with a correct baseline.
- Use an appropriate columnar format such as ORC for Hive analytics when supported.
- Partition only when the partition key matches common filters and partition cardinality/file layout are sensible.
- Run `EXPLAIN` or the environment's supported equivalent.
- Compare equivalent queries and report repeated timings or a clear limitation.

### Phase 7 — Deliver
Produce:
- runnable command/script files;
- table DDL and transformation SQL;
- analysis SQL;
- validation checklist and captured outputs;
- benchmark methodology/results if actually measured;
- concise report with assumptions and limitations.

## SQL authoring standards

- Use explicit column lists in `INSERT INTO ... SELECT ...`; do not rely on `SELECT *` across schema changes.
- Qualify tables with database names when practical.
- Use clear aliases and consistent snake_case identifiers.
- Avoid reserved words as identifiers; quote identifiers only using syntax supported by the installed Hive version.
- Use `NULLIF`/`CASE` patterns only if supported; test unfamiliar functions.
- Avoid implicit type conversion when an explicit cast is clearer.
- Guard duration metrics against null or invalid timestamps and decide how negative durations are handled.
- Do not call a count of rows a count of unique entities. Use `COUNT(DISTINCT ...)` only when that is the intended metric.
- Do not claim an aggregate is exact if the query uses approximate functions.
- Be careful with timestamp timezone assumptions. Hive timestamps may be timezone-sensitive in conversions even though the stored type does not carry a timezone.

## Delegation to references

Read the relevant reference before performing the task:
- HDFS and cluster setup: `references/hdfs-and-environment.md`
- CSV/schema/table creation: `references/hive-ingestion-and-schema.md`
- Cleaning and analytics: `references/cleaning-and-analytics.md`
- ORC/partitioning/performance: `references/performance-and-partitioning.md`
- Errors, validation, report: `references/troubleshooting-and-delivery.md`
- Divvy Bikes: `playbooks/divvy-bikes.md`
- LA Crime Data: `playbooks/la-crime-data.md`

## Source of truth

Prefer the installed cluster's behavior and official Apache documentation over memory or third-party snippets. Official references:
- https://hive.apache.org/docs/latest/language/
- https://hive.apache.org/docs/latest/language/languagemanual-ddl/
- https://hive.apache.org/docs/latest/language/languagemanual-dml/
- https://hive.apache.org/docs/latest/language/languagemanual-orc/
- https://hive.apache.org/docs/latest/language/languagemanual-udf/
- https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html
