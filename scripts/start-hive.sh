#!/usr/bin/env bash
set -e

# Kill any stale Hive instances
pkill -f "org.apache.hadoop.hive.metastore.HiveMetaStore" 2>/dev/null || true
pkill -f "org.apache.hive.service.server.HiveServer2" 2>/dev/null || true
sleep 2

# Source environment
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export HADOOP_HOME=/home/huser/hadoop-3.3.6
export PATH=$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo "Starting Hive Metastore..."
nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &

echo "Waiting for Metastore to initialize..."
sleep 6

echo "Starting HiveServer2..."
nohup hive --service hiveserver2 > /tmp/hiveserver2.log 2>&1 &

echo "Hive services launched in background."
