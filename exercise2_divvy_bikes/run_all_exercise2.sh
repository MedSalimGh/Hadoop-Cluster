#!/usr/bin/env bash
set -e

export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

LOG_FILE="/vagrant/exercise2_divvy_bikes/divvy_execution_log.txt"
echo "=== Starting Complete Divvy Bikes Exercise 2 Pipeline ===" > "$LOG_FILE"
date >> "$LOG_FILE"

echo -e "\n>>> [1/4] Running Part 1: Raw Ingestion..." | tee -a "$LOG_FILE"
bash /vagrant/exercise2_divvy_bikes/01_load_divvy.sh 2>&1 | tee -a "$LOG_FILE"

echo -e "\n>>> [2/4] Running Part 2: ORC Cleaning & Typing..." | tee -a "$LOG_FILE"
bash /vagrant/exercise2_divvy_bikes/02_clean_and_orc.sh 2>&1 | tee -a "$LOG_FILE"

echo -e "\n>>> [3/4] Running Part 3: Data Analysis (8 Questions)..." | tee -a "$LOG_FILE"
beeline -u jdbc:hive2://localhost:10000/divvy_db -n huser --outputformat=table2 -f /vagrant/exercise2_divvy_bikes/03_analyze_divvy.sql 2>&1 | tee -a "$LOG_FILE"

echo -e "\n>>> [4/4] Running Part 4: Partitioning & Aug. 15 Benchmark..." | tee -a "$LOG_FILE"
beeline -u jdbc:hive2://localhost:10000/divvy_db -n huser --outputformat=table2 -f /vagrant/exercise2_divvy_bikes/04_partition_and_benchmark.sql 2>&1 | tee -a "$LOG_FILE"

echo -e "\n=== All 4 Parts of Exercise 2 Completed Successfully! ===" | tee -a "$LOG_FILE"
date >> "$LOG_FILE"
