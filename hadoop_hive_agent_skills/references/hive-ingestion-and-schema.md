# Hive Ingestion, CSV, and Schema Design

## Inspect the CSV first

Before creating a table:
1. Identify the actual file path and size.
2. Inspect the first few lines and several representative rows.
3. Confirm delimiter, header row, quoting, escaped quotes, embedded delimiters/newlines, character encoding, and line endings.
4. Determine how empty strings, literal `NULL`, `\N`, and missing values are represented.
5. Inspect timestamp examples and numeric ranges.
6. Check whether the dataset contains duplicate records or malformed rows.
7. Compare observed fields with the assignment's expected fields.

A plain `head` is useful but insufficient when fields may contain quoted commas or embedded newlines. If available, use a CSV-aware parser locally to inspect field counts and malformed rows. Never assume every row has the same number of columns merely because the header looks correct.

## External raw table

Use an external table when Hive should describe source files whose lifecycle remains outside Hive. Use the correct CSV SerDe or equivalent for the installed distribution. Do not assume a comma-delimited file can be safely read with the default text SerDe if quoting is present.

Illustrative template — replace every placeholder and validate SerDe availability:

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS <database>.divvy_trips_raw (
  <column_1> STRING,
  <column_2> STRING
  -- define all observed columns in file order
)
ROW FORMAT SERDE '<supported_csv_serde_class>'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 'hdfs:///user/<user>/divvy/raw';
```

This is a template, not universally executable SQL. SerDe class names and property names vary by distribution. Confirm the class exists and that the header is handled correctly. If the header is not skipped, the first data row can be mistaken for a record. A header-skip table property may be supported by some SerDes; test it rather than assuming.

For LA Crime Data, do not guess the current CSV column names or weapon field. Inspect the downloaded file's header and use the exact observed schema.

## External vs managed tables

- External raw table: metadata describes externally owned files; dropping the table generally leaves the data files in place.
- Managed curated table: Hive manages the table's data lifecycle; dropping it can delete its data.
- Confirm behavior for the installed Hive version and table properties before destructive operations.
- Use `DESCRIBE FORMATTED <table>` to inspect table type and location when supported.

Official reference: https://hive.apache.org/docs/latest/language/managed-vs--external-tables/

## Loading data: do not confuse operations

`LOAD DATA` is generally a file movement/copy operation, not a CSV parser or transformation pipeline. To transform raw strings into typed columns, use a query such as `INSERT INTO ... SELECT ...` or `INSERT OVERWRITE ... SELECT ...` with explicit expressions. Verify semantics for your Hive version.

Official reference: https://hive.apache.org/docs/latest/language/languagemanual-dml/

## Verify immediately

After creating the raw table:

```sql
DESCRIBE <database>.divvy_trips_raw;
SELECT * FROM <database>.divvy_trips_raw LIMIT 10;
SELECT COUNT(*) FROM <database>.divvy_trips_raw;
```

For a large CSV, `COUNT(*)` may be expensive but is a useful baseline when feasible. Compare Hive's count with a CSV-aware count that accounts for quoted embedded newlines, headers, and malformed records. Do not compare naive physical line counts to logical CSV records when embedded newlines may exist.

Validate:
- field alignment;
- header is not included as data;
- commas inside quoted strings do not shift columns;
- empty and NULL fields behave as expected;
- sampled values match the source;
- table location points to the intended HDFS directory.

## Schema design

- Raw landing columns can be `STRING` to preserve original text, especially when the data is messy.
- Curated columns should use meaningful types (`TIMESTAMP`, `DATE`, integer, decimal, etc.) only after validating source values.
- Keep original values or rejected-row output if auditability is needed.
- Document type conversions and null policy.
- Avoid inventing primary keys: Hive tables do not automatically enforce relational uniqueness.
- Keep column order explicit and consistent between table DDL and INSERT statements.
