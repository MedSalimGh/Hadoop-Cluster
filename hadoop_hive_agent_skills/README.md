# Hadoop & Hive Agent Skills

A reusable skill library for agents working on Hadoop/HDFS and Apache Hive data-engineering assignments.

## Contents

- `SKILL.md` — Core agent behavior, workflow, and safety rules.
- `references/hdfs-and-environment.md` — Environment discovery and HDFS operations.
- `references/hive-ingestion-and-schema.md` — CSV inspection, external tables, schemas, and data quality.
- `references/cleaning-and-analytics.md` — Typed transformations and analytical SQL patterns.
- `references/performance-and-partitioning.md` — ORC, partitions, EXPLAIN, and fair benchmarking.
- `references/troubleshooting-and-delivery.md` — Debugging, validation, evidence, and report standards.
- `playbooks/divvy-bikes.md` — Divvy Bikes assignment-specific workflow.
- `playbooks/la-crime-data.md` — LA Crime Data assignment-specific workflow.

## How to use

1. Put this directory where your coding agent expects skills to live, or copy the files into its skills directory.
2. Keep `SKILL.md` as the main entry point. If your agent supports skill folders with reference files, preserve the directory structure.
3. Attach/provide the actual CSV file to the agent. These instructions intentionally do not assume the attachment's filename or schema.
4. Ask the agent to inspect the local environment and dataset first, then execute the relevant playbook step by step.

## Operating principle

These are workflow instructions and SQL patterns, not a claim that commands have been run. The agent must adapt syntax to the installed Hadoop/Hive distribution, inspect real headers, execute commands where possible, and label unverified results honestly.

## Official references

- Apache Hive Language Manual: https://hive.apache.org/docs/latest/language/
- Hive DDL: https://hive.apache.org/docs/latest/language/languagemanual-ddl/
- Managed vs external tables: https://hive.apache.org/docs/latest/language/managed-vs--external-tables/
- Hive DML: https://hive.apache.org/docs/latest/language/languagemanual-dml/
- Hive ORC: https://hive.apache.org/docs/latest/language/languagemanual-orc/
- Hive UDFs/date functions: https://hive.apache.org/docs/latest/language/languagemanual-udf/
- Hive types: https://hive.apache.org/docs/latest/language/languagemanual-types/
- Hadoop HDFS commands: https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html
- ORC background/specification: https://orc.apache.org/docs/
