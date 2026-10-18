#!/usr/bin/env bash
set -e

# Kill any stale Hive instances
echo "Stopping any existing Hive processes..."
pkill -f "org.apache.hadoop.hive.metastore.HiveMetaStore" 2>/dev/null || true
pkill -f "org.apache.hive.service.server.HiveServer2" 2>/dev/null || true
sleep 2

# Source environment
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export HADOOP_HOME=/home/huser/hadoop-3.3.6
export PATH=$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

echo "Starting Hive Metastore service..."
nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &

echo "Waiting for Metastore to bind to port 9083..."
for i in {1..20}; do
  if ss -tulpn | grep -q ":9083 "; then
    echo "Metastore is listening on port 9083."
    break
  fi
  sleep 1
done

echo "Starting HiveServer2 service..."
nohup hive --service hiveserver2 > /tmp/hiveserver2.log 2>&1 &

echo "Waiting for HiveServer2 to bind to port 10000..."
for i in {1..35}; do
  if ss -tulpn | grep -q ":10000 "; then
    echo "HiveServer2 is listening on port 10000. Ready for Beeline!"
    break
  fi
  sleep 1
done

echo "=========================================================="
echo "Hive Metastore (Port 9083) and HiveServer2 (Port 10000) are active."
echo "Connect with: beeline -u jdbc:hive2://localhost:10000 -n huser"
echo "=========================================================="
