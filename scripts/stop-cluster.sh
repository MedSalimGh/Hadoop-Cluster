#!/usr/bin/env bash
# Source environment
export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "=========================================================="
echo "=== [1/3] Stopping Apache Hive Services ================="
echo "=========================================================="
bash /vagrant/scripts/stop-hive.sh 2>/dev/null || true

echo "=========================================================="
echo "=== [2/3] Stopping YARN Compute Daemons =================="
echo "=========================================================="
stop-yarn.sh 2>/dev/null || true

echo "=========================================================="
echo "=== [3/3] Stopping HDFS Storage Daemons =================="
echo "=========================================================="
stop-dfs.sh 2>/dev/null || true

echo "=========================================================="
echo "=== Hadoop & Hive Cluster Daemons Stopped Cleanly. ======="
echo "=========================================================="
