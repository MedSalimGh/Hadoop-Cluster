# Big Data Coursework: Comprehensive Screenshot Guide for LaTeX Reports

This guide provides the exact list of screenshots required for both academic reports. Each screenshot has a dedicated filename and path matching the `\safeincludeimage` macros in the LaTeX documents:
- Exercise 1 screenshots go to: `exercise1_la_crime/images/`
- Exercise 2 screenshots go to: `exercise2_divvy_bikes/images/`

---

## Exercise 1: Los Angeles Crime Data Analysis (~1M Records)
Directory: `exercise1_la_crime/images/`

| # | Filename | Report Section & Purpose | How to Capture / Command or URL |
| :--- | :--- | :--- | :--- |
| **1** | `ex1_01_hdfs_upload.png` | **HDFS Ingestion Verification:** Proves dataset was uploaded to HDFS with replication and correct size (~243.6 MB). | **Option A (Browser):** Open `http://192.168.56.10:9870/explorer.html#/data/crime/raw`<br>**Option B (Terminal):** Run `hdfs dfs -ls -h /data/crime/raw/` |
| **2** | `ex1_02_create_table.png` | **Schema & OpenCSVSerde Verification:** Proves `crime_data_raw` external table was created with `OpenCSVSerde`. | In Beeline, run:<br>`DESCRIBE FORMATTED crime_data_db.crime_data_raw;` |
| **3** | `ex1_03_sample_records.png` | **Sample Records Verification:** Shows first 5 records with clean columns and no delimiter corruption. | In Beeline, run:<br>`SELECT dr_no, date_occ, time_occ, area_name, crm_cd_desc, vict_age, vict_sex, status_desc FROM crime_data_db.crime_data_raw LIMIT 5;` |
| **4** | `ex1_04_total_crimes.png` | **Total Volume & Uniqueness Check:** Proves exactly 1,004,894 records and 100% unique `dr_no`. | In Beeline, run:<br>`SELECT count(*) AS total_crimes, count(DISTINCT dr_no) AS unique_dr_no FROM crime_data_db.crime_data_raw;` |
| **5** | `ex1_05_crimes_by_area.png` | **Crimes by Area (Top 10):** Shows distribution across LAPD geographic areas (Central, 77th Street, Pacific). | In Beeline, run:<br>`SELECT area_name, count(*) AS crime_count FROM crime_data_db.crime_data_raw GROUP BY area_name ORDER BY crime_count DESC LIMIT 10;` |
| **6** | `ex1_06_common_crimes.png` | **Most Common Crime Descriptions:** Shows top crimes (Stolen Vehicle, Simple Assault, Burglary). | In Beeline, run:<br>`SELECT crm_cd_desc, count(*) AS crime_count FROM crime_data_db.crime_data_raw GROUP BY crm_cd_desc ORDER BY crime_count DESC LIMIT 10;` |
| **7** | `ex1_07_crime_trends_year.png` | **Crime Trends by Year (2020–2024):** Proves longitudinal crime counts across 2020, 2021, 2022, 2023, and 2024. | In Beeline, run:<br>`SELECT substr(date_occ, 7, 4) AS crime_year, count(*) AS total_crimes FROM crime_data_db.crime_data_raw WHERE substr(date_occ, 7, 4) IS NOT NULL AND length(substr(date_occ, 7, 4)) = 4 GROUP BY substr(date_occ, 7, 4) ORDER BY crime_year ASC;` |
| **8** | `ex1_08_handgun_filter.png` | **Specific Weapon Filter:** Shows isolated crimes involving `HAND GUN` (exactly 20,182 incidents). | In Beeline, run:<br>`SELECT count(*) AS handgun_crimes FROM crime_data_db.crime_data_raw WHERE upper(trim(weapon_desc)) = 'HAND GUN';` |
| **9** | `ex1_09_victim_age_groups.png` | **Victim Age Groups:** Shows victim demographic breakdown across age cohorts (25-34, 35-44, Unknown, etc.). | In Beeline, run the query from [`exercise1_la_crime/02_analyze_crime.sql`](file:///e:/Hive%20Project%20Type%20Shit/exercise1_la_crime/02_analyze_crime.sql#L100-L125) |
| **10** | `ex1_10_yarn_job_execution.png` | **Cluster Infrastructure Verification:** Shows YARN ResourceManager with completed MapReduce applications. | **Browser:** Open `http://192.168.56.10:8088/cluster/apps` |

---

## Exercise 2: Chicago Divvy Bikes Trip Data Analysis (~800K Records)
Directory: `exercise2_divvy_bikes/images/`

| # | Filename | Report Section & Purpose | How to Capture / Command or URL |
| :--- | :--- | :--- | :--- |
| **1** | `ex2_01_hdfs_upload.png` | **Part 1 — HDFS Ingestion:** Proves `divvy-tripdata.csv` (150.2 MB) is staged in HDFS. | **Option A (Browser):** Open `http://192.168.56.10:9870/explorer.html#/data/divvy/raw`<br>**Option B (Terminal):** Run `hdfs dfs -ls -h /data/divvy/raw/` |
| **2** | `ex2_02_raw_table_verify.png` | **Part 1 — Raw External Table:** Shows `divvy_trips_raw` row count (790,177 rows). | In Beeline, run:<br>`SELECT count(*) FROM divvy_db.divvy_trips_raw;` |
| **3** | `ex2_03_orc_cleaned_table.png` | **Part 2 — ORC Storage & Compression:** Proves managed ORC table size (31.3 MB vs 150.2 MB CSV = 79.2% storage reduction). | **Terminal:** Run<br>`hdfs dfs -du -h /user/hive/warehouse/divvy_db.db/divvy_trips_cleaned` |
| **4** | `ex2_04_q1_avg_duration.png` | **Part 3 — Q1 Average Duration:** Shows average (17.56 min), min (0.02 min), and max (1499.97 min). | In Beeline, run:<br>`SELECT round(avg((unix_timestamp(end_time) - unix_timestamp(start_time))/60.0), 2) AS avg_min, round(min((unix_timestamp(end_time) - unix_timestamp(start_time))/60.0), 2) AS min_min, round(max((unix_timestamp(end_time) - unix_timestamp(start_time))/60.0), 2) AS max_min FROM divvy_db.divvy_trips_cleaned WHERE end_time >= start_time;` |
| **5** | `ex2_05_q2_bike_types.png` | **Part 3 — Q2 Unique Bike Types:** Shows 2 types (`electric_bike`: 509,196; `classic_bike`: 280,981). | In Beeline, run:<br>`SELECT rideable_type, count(*) AS count FROM divvy_db.divvy_trips_cleaned GROUP BY rideable_type;` |
| **6** | `ex2_06_q3_top_stations.png` | **Part 3 — Q3 Top 5 Start Stations:** Shows Navy Pier (13,851), DuSable Monroe (7,554), etc. | In Beeline, run:<br>`SELECT start_station_name, count(*) AS trips FROM divvy_db.divvy_trips_cleaned WHERE start_station_name IS NOT NULL AND start_station_name != '' GROUP BY start_station_name ORDER BY trips DESC LIMIT 5;` |
| **7** | `ex2_07_q4_monthly_trips.png` | **Part 3 — Q4 Trips Per Month:** Shows July 2025 (128) and August 2025 (790,049). | In Beeline, run:<br>`SELECT year(start_time) AS y, month(start_time) AS m, count(*) AS trips FROM divvy_db.divvy_trips_cleaned GROUP BY year(start_time), month(start_time);` |
| **8** | `ex2_08_q5_busiest_hour.png` | **Part 3 — Q5 Busiest Hour:** Shows Hour 17 (5 PM) with 77,849 trips. | In Beeline, run:<br>`SELECT hour(start_time) AS hr, count(*) AS trips FROM divvy_db.divvy_trips_cleaned GROUP BY hour(start_time) ORDER BY trips DESC LIMIT 1;` |
| **9** | `ex2_09_q6_subscribers_vs_customers.png` | **Part 3 — Q6 Subscribers vs Customers:** Shows casual (23.53 min) vs members (13.10 min). | In Beeline, run:<br>`SELECT member_casual, count(*) AS trips, round(avg((unix_timestamp(end_time) - unix_timestamp(start_time))/60.0), 2) AS avg_duration FROM divvy_db.divvy_trips_cleaned WHERE end_time >= start_time GROUP BY member_casual;` |
| **10** | `ex2_10_q7_top_routes.png` | **Part 3 — Q7 Top 10 Routes:** Shows round trips and popular lakefront routes. | In Beeline, run:<br>`SELECT start_station_name, end_station_name, count(*) AS trips FROM divvy_db.divvy_trips_cleaned WHERE start_station_name != '' AND end_station_name != '' GROUP BY start_station_name, end_station_name ORDER BY trips DESC LIMIT 10;` |
| **11** | `ex2_11_q8_longest_trips.png` | **Part 3 — Q8 Longest Trip per Station:** Shows system cap around ~1499.97 min (~25 hr). | In Beeline, run:<br>`SELECT start_station_name, round(max((unix_timestamp(end_time)-unix_timestamp(start_time))/60.0), 2) AS longest_min FROM divvy_db.divvy_trips_cleaned WHERE start_station_name != '' AND end_time >= start_time GROUP BY start_station_name ORDER BY longest_min DESC LIMIT 10;` |
| **12** | `ex2_12_dynamic_partitioning.png` | **Part 4 — Dynamic Partitioning Execution:** Shows 33 partitions created by date (`start_date=2025-07-30` to `2025-08-31`). | In Beeline, run:<br>`SHOW PARTITIONS divvy_db.divvy_trips_partitioned;` |
| **13** | `ex2_13_benchmark_unpartitioned.png` | **Part 4 — Benchmark Unpartitioned:** Shows query output for August 15 on `divvy_trips_cleaned` (28,502 trips, 4.78 MB read, 3.95s CPU). | In Beeline, run:<br>`SELECT count(*) FROM divvy_db.divvy_trips_cleaned WHERE start_time >= '2025-08-15 00:00:00' AND start_time < '2025-08-16 00:00:00';` |
| **14** | `ex2_14_benchmark_partitioned.png` | **Part 4 — Benchmark Partitioned:** Shows query output for August 15 on `divvy_trips_partitioned` (28,502 trips, 35.7 KB read, 133.8x I/O reduction!). | In Beeline, run:<br>`SELECT count(*) FROM divvy_db.divvy_trips_partitioned WHERE start_date = '2025-08-15';` |
| **15** | `ex2_15_explain_comparison.png` | **Part 4 — EXPLAIN Comparison:** Shows the operator plan difference proving partition pruning. | In Beeline, run:<br>`SET hive.cbo.enable=false;`<br>`EXPLAIN SELECT count(*) FROM divvy_db.divvy_trips_partitioned WHERE start_date = '2025-08-15';` |

---

## How to Quick-Connect to Beeline

From your host Windows terminal (PowerShell), connect directly to Hive on the master node:
```powershell
$env:VAGRANT_HOME="E:\.vagrant.d"
vagrant ssh master -- "sudo -u huser -i beeline -u 'jdbc:hive2://localhost:10000' -n huser"
```
Or directly inside the VirtualBox console (log in with `huser` / `huser`):
```bash
beeline -u "jdbc:hive2://localhost:10000" -n huser
```
