#!/usr/bin/env bash
set -e

export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "=== [Exercise 1] Step 1: Uploading LA Crime Data to HDFS ==="
hdfs dfs -mkdir -p /data/crime/raw

if hdfs dfs -test -e /data/crime/raw/Crime_Data_from_2020_to_2024.csv; then
    echo "Crime dataset already exists in HDFS at /data/crime/raw/Crime_Data_from_2020_to_2024.csv."
else
    echo "Copying /vagrant/data/Crime_Data_from_2020_to_2024.csv to HDFS /data/crime/raw/ ..."
    hdfs dfs -put -f /vagrant/data/Crime_Data_from_2020_to_2024.csv /data/crime/raw/
fi

hdfs dfs -chmod -R 777 /data/crime
hdfs dfs -ls -h /data/crime/raw

echo "=== [Exercise 1] Step 2: Creating Database & Hive External Table ==="
beeline -u jdbc:hive2://localhost:10000 -n huser -e "
CREATE DATABASE IF NOT EXISTS crime_data_db;
USE crime_data_db;

DROP TABLE IF EXISTS crime_data_raw;

CREATE EXTERNAL TABLE IF NOT EXISTS crime_data_raw (
    dr_no STRING,
    date_rptd STRING,
    date_occ STRING,
    time_occ STRING,
    area STRING,
    area_name STRING,
    rpt_dist_no STRING,
    part_1_2 STRING,
    crm_cd STRING,
    crm_cd_desc STRING,
    mocodes STRING,
    vict_age STRING,
    vict_sex STRING,
    vict_descent STRING,
    premis_cd STRING,
    premis_desc STRING,
    weapon_used_cd STRING,
    weapon_desc STRING,
    status STRING,
    status_desc STRING,
    crm_cd_1 STRING,
    crm_cd_2 STRING,
    crm_cd_3 STRING,
    crm_cd_4 STRING,
    location STRING,
    cross_street STRING,
    lat STRING,
    lon STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar'     = '\"',
    'escapeChar'    = '\\\\'
)
STORED AS TEXTFILE
LOCATION '/data/crime/raw'
TBLPROPERTIES ('skip.header.line.count'='1');

DESCRIBE FORMATTED crime_data_raw;
SELECT dr_no, date_occ, area_name, crm_cd_desc, vict_age, vict_sex, weapon_desc FROM crime_data_raw LIMIT 5;
"

echo "=== [Exercise 1] Hive External Table Created and Verified! ==="
