#!/usr/bin/env bash
set -e

export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "=== [Exercise 2 - Part 2] Creating Managed ORC Table: divvy_trips_cleaned ==="

beeline -u jdbc:hive2://localhost:10000/divvy_db -n huser -e "
USE divvy_db;

DROP TABLE IF EXISTS divvy_trips_cleaned;

CREATE TABLE IF NOT EXISTS divvy_trips_cleaned (
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
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');

-- Insert transformed data into managed ORC table
INSERT OVERWRITE TABLE divvy_trips_cleaned
SELECT
    trim(ride_id) AS ride_id,
    trim(rideable_type) AS rideable_type,
    cast(trim(started_at) AS TIMESTAMP) AS start_time,
    cast(trim(ended_at) AS TIMESTAMP) AS end_time,
    upper(trim(start_station_name)) AS start_station_name,
    trim(start_station_id) AS start_station_id,
    upper(trim(end_station_name)) AS end_station_name,
    trim(end_station_id) AS end_station_id,
    cast(trim(start_lat) AS DOUBLE) AS start_lat,
    cast(trim(start_lng) AS DOUBLE) AS start_lng,
    cast(trim(end_lat) AS DOUBLE) AS end_lat,
    cast(trim(end_lng) AS DOUBLE) AS end_lng,
    trim(member_casual) AS member_casual
FROM divvy_trips_raw
WHERE ride_id != 'ride_id' AND ride_id IS NOT NULL AND started_at IS NOT NULL;

DESCRIBE FORMATTED divvy_trips_cleaned;

SELECT 
    count(*) AS cleaned_total_rows,
    count(DISTINCT ride_id) AS distinct_rides
FROM divvy_trips_cleaned;

SELECT ride_id, rideable_type, start_time, end_time, start_station_name, member_casual
FROM divvy_trips_cleaned
LIMIT 5;
"

echo "=== [Exercise 2 - Part 2] Managed ORC Table Created and Populated! ==="
