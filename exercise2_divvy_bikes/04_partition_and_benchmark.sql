-- ==============================================================================
-- Exercise 2 - PART 4: Performance Optimization & Partitioning Benchmark
-- Database: divvy_db
-- ==============================================================================

USE divvy_db;

-- 1. Enable dynamic partitioning and configure CBO
SET hive.cbo.enable = false;
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions = 1000;
SET hive.exec.max.dynamic.partitions.pernode = 1000;

-- 2. Create partitioned table
DROP TABLE IF EXISTS divvy_trips_partitioned;

CREATE TABLE IF NOT EXISTS divvy_trips_partitioned (
    ride_id STRING,
    rideable_type STRING,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    start_station_name STRING,
    start_station_id STRING,
    end_station_name STRING,
    end_station_id STRING,
    start_lat DOUBLE,
    start_lng DOUBLE,
    end_lat DOUBLE,
    end_lng DOUBLE,
    member_casual STRING
)
PARTITIONED BY (start_date STRING)
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');

-- 3. Populate partitioned table from cleaned ORC table
INSERT OVERWRITE TABLE divvy_trips_partitioned PARTITION (start_date)
SELECT
    ride_id,
    rideable_type,
    start_time,
    end_time,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual,
    substr(cast(start_time as STRING), 1, 10) AS start_date
FROM divvy_trips_cleaned;

SHOW PARTITIONS divvy_trips_partitioned;

-- ------------------------------------------------------------------------------
-- 4. BENCHMARK: Total Trips on August 15 (Cleaned vs Partitioned)
-- ------------------------------------------------------------------------------

-- 4A. Query on Non-Partitioned Table (divvy_trips_cleaned)
SELECT '--- BENCHMARK A: NON-PARTITIONED TABLE (FULL TABLE SCAN) ---' AS benchmark_stage;
EXPLAIN 
SELECT count(*) AS aug15_trips_unpartitioned
FROM divvy_trips_cleaned
WHERE start_time >= '2025-08-15 00:00:00' AND start_time < '2025-08-16 00:00:00';

SELECT count(*) AS aug15_trips_unpartitioned
FROM divvy_trips_cleaned
WHERE start_time >= '2025-08-15 00:00:00' AND start_time < '2025-08-16 00:00:00';

-- 4B. Query on Partitioned Table (divvy_trips_partitioned)
SELECT '--- BENCHMARK B: PARTITIONED TABLE (PARTITION PRUNING) ---' AS benchmark_stage;
EXPLAIN 
SELECT count(*) AS aug15_trips_partitioned
FROM divvy_trips_partitioned
WHERE start_date = '2025-08-15';

SELECT count(*) AS aug15_trips_partitioned
FROM divvy_trips_partitioned
WHERE start_date = '2025-08-15';
