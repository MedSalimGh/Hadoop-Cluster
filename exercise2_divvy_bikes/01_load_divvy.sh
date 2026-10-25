#!/usr/bin/env bash
set -e

export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "=== [Exercise 2] Step 1: Uploading Divvy Bikes Trip Data to HDFS ==="
hdfs dfs -mkdir -p /data/divvy/raw

if hdfs dfs -test -e /data/divvy/raw/divvy-tripdata.csv; then
    echo "Divvy dataset already exists in HDFS at /data/divvy/raw/divvy-tripdata.csv."
else
    echo "Copying /vagrant/data/divvy-tripdata.csv to HDFS /data/divvy/raw/ ..."
    hdfs dfs -put -f /vagrant/data/divvy-tripdata.csv /data/divvy/raw/
fi

hdfs dfs -chmod -R 777 /data/divvy
hdfs dfs -ls -h /data/divvy/raw

echo "=== [Exercise 2] Step 2: Creating Database & External Table divvy_trips_raw ==="
beeline -u jdbc:hive2://localhost:10000 -n huser -e "
CREATE DATABASE IF NOT EXISTS divvy_db;
USE divvy_db;

DROP TABLE IF EXISTS divvy_trips_raw;

CREATE EXTERNAL TABLE IF NOT EXISTS divvy_trips_raw (
    ride_id STRING,
    rideable_type STRING,
    started_at STRING,
    ended_at STRING,
    start_station_name STRING,
    start_station_id STRING,
    end_station_name STRING,
    end_station_id STRING,
    start_lat STRING,
    start_lng STRING,
    end_lat STRING,
    end_lng STRING,
    member_casual STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar'     = '\"',
    'escapeChar'    = '\\\\'
)
STORED AS TEXTFILE
LOCATION '/data/divvy/raw'
TBLPROPERTIES ('skip.header.line.count'='1');

DESCRIBE FORMATTED divvy_trips_raw;
SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, member_casual FROM divvy_trips_raw WHERE ride_id != 'ride_id' LIMIT 5;
"

echo "=== [Exercise 2 - Part 1] Raw Data Ingestion Completed! ==="
