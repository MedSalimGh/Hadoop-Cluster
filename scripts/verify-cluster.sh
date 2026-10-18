#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "=== Hadoop & Hive Cluster Health and Verification Tool ==="
echo "=========================================================="

echo -e "\n[1/5] Checking Java Processes (jps) on Master:"
su - huser -c "jps"

echo -e "\n[2/5] HDFS Cluster Report (hdfs dfsadmin -report):"
su - huser -c "hdfs dfsadmin -report"

echo -e "\n[3/5] YARN Cluster Nodes (yarn node -list):"
su - huser -c "yarn node -list"

echo -e "\n[4/5] Testing MapReduce with Hadoop Pi Calculation:"
su - huser -c "hadoop jar /home/huser/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar pi 2 10"

echo -e "\n[5/5] Testing Hive Metastore & SQL Query execution:"
su - huser -c "hive -e '
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS student (id INT, name STRING, dept STRING);
INSERT INTO student VALUES (1, \"Salim\", \"Data Science\"), (2, \"Montasser\", \"Big Data\");
SELECT * FROM student;
'"

echo -e "\n=========================================================="
echo "=== All Cluster Tests Completed Successfully! ==="
echo "=========================================================="
