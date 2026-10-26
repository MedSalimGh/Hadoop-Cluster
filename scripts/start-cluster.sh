#!/usr/bin/env bash
set -e

# Ensure execution as huser
if [ "$(id -un)" != "huser" ]; then
    exec su - huser -c "bash /vagrant/scripts/start-cluster.sh"
fi

# Source environment
export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "=========================================================="
echo "=== [1/3] Starting HDFS Distributed Storage Daemons ======"
echo "=========================================================="
start-dfs.sh

echo "Waiting for HDFS safe mode to clear..."
hdfs dfsadmin -safemode wait

echo "=========================================================="
echo "=== [2/3] Starting YARN Resource Compute Daemons ========="
echo "=========================================================="
start-yarn.sh

echo "=========================================================="
echo "=== [3/3] Starting Apache Hive Services =================="
echo "=========================================================="
bash /vagrant/scripts/start-hive.sh

echo "=========================================================="
echo "=== Hadoop & Hive Cluster is Fully Operational! =========="
echo "=========================================================="
echo "HDFS NameNode WebUI:         http://192.168.56.10:9870"
echo "YARN ResourceManager WebUI:  http://192.168.56.10:8088"
echo "HiveServer2 WebUI:           http://192.168.56.10:10002"
echo "Beeline JDBC Connection:     beeline -u jdbc:hive2://localhost:10000 -n huser"
echo "=========================================================="
