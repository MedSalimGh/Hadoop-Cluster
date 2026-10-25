# HDFS and Environment Discovery

## Goal

Determine how this particular cluster is configured before issuing commands.

## Discover tools and versions

Run only commands available in the environment; record failures without treating them as fatal evidence about the cluster itself.

```bash
hadoop version
hdfs version
hive --version
beeline --version
which hdfs
which hive
which beeline
```

If the classic Hive CLI is absent, investigate Beeline or the platform's supported SQL interface. Do not assume a local command can reach a remote cluster.

In Hive/Beeline, useful discovery commands may include:

```sql
SHOW DATABASES;
SELECT current_database();
SET;
```

`SET;` may print many configuration values; do not expose secrets in logs. Check the execution engine and warehouse location only when relevant, and redact credentials.

## HDFS file workflow

Use HDFS filesystem commands, not local shell commands, to verify HDFS content.

```bash
hdfs dfs -ls /
hdfs dfs -mkdir -p /user/<user>/divvy/raw
hdfs dfs -put -f ./input.csv /user/<user>/divvy/raw/input.csv
hdfs dfs -ls -h /user/<user>/divvy/raw
hdfs dfs -du -h /user/<user>/divvy/raw
hdfs dfs -cat /user/<user>/divvy/raw/input.csv | head
```

Replace placeholders with actual values. Verify that the destination is correct before using `-f`, because it can replace a destination file. For very large files, avoid streaming the entire file to the terminal; inspect a bounded sample.

Useful checks:
- Does the path exist?
- Is the file size plausible and non-zero?
- Can the submitting user read the file?
- Is the file really in HDFS rather than the local filesystem?
- Is the HDFS path accessible from Hive's execution environment?

## Safe operational habits

- Never run recursive deletion (`hdfs dfs -rm -r`) without verifying the exact target and confirming that it is a disposable project-owned path.
- Do not change HDFS permissions broadly (for example, world-writable permissions) to bypass an access problem.
- Avoid hard-coding NameNode addresses if the cluster configuration already provides them.
- Do not upload credentials or private keys as data files.
- Use a project-specific HDFS directory; do not place assignment files in shared root paths.
- Do not assume `hdfs dfs -put -f` is equivalent to a safe append or versioned upload.

## Environment report

Record:
- Hadoop and Hive versions, when obtainable;
- SQL client used;
- execution engine, when discoverable;
- input and HDFS paths;
- table database;
- permission/access issues;
- any syntax that had to be adapted for compatibility.

Official references:
- HDFS commands: https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html
- Hive language manual: https://hive.apache.org/docs/latest/language/
