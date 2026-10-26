#!/usr/bin/env bash
set -eo pipefail

# Ensure execution as huser
if [ "$(id -un)" != "huser" ]; then
    exec su - huser -c "bash /vagrant/scripts/verify-cluster.sh"
fi

export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

echo "=========================================================="
echo "=== Hadoop & Hive Cluster Health and Verification Tool ==="
echo "=========================================================="

echo -e "\n[1/6] Checking Java Processes (jps) across cluster nodes:"
echo "--- Master (192.168.56.10) ---"
jps
echo "--- Worker 1 (192.168.56.11) ---"
ssh -o BatchMode=yes -o ConnectTimeout=5 worker1 "jps" || echo "Warning: Unable to reach worker1 via SSH"
echo "--- Worker 2 (192.168.56.12) ---"
ssh -o BatchMode=yes -o ConnectTimeout=5 worker2 "jps" || echo "Warning: Unable to reach worker2 via SSH"

echo -e "\n[2/6] Verifying HDFS Live DataNodes (assertion: >= 2):"
LIVE_DN=$(hdfs dfsadmin -report 2>/dev/null | grep -E "Live datanodes \([0-9]+\):" | grep -oE "[0-9]+" || echo "0")
echo "Detected Live DataNodes: ${LIVE_DN}"
if [ -z "$LIVE_DN" ] || [ "$LIVE_DN" -lt 2 ]; then
    echo "ERROR: HDFS assertion failed! Expected >= 2 Live DataNodes, but detected: ${LIVE_DN}" >&2
    exit 1
fi
echo "PASS: HDFS storage layer healthy with ${LIVE_DN} Live DataNodes."

echo -e "\n[3/6] Verifying YARN Running NodeManagers (assertion: >= 2):"
RUNNING_NM=$(yarn node -list -states RUNNING 2>/dev/null | grep -c "RUNNING" || echo "0")
echo "Detected Running NodeManagers: ${RUNNING_NM}"
if [ -z "$RUNNING_NM" ] || [ "$RUNNING_NM" -lt 2 ]; then
    echo "ERROR: YARN assertion failed! Expected >= 2 Running NodeManagers, but detected: ${RUNNING_NM}" >&2
    exit 1
fi
echo "PASS: YARN compute layer healthy with ${RUNNING_NM} Running NodeManagers."

echo -e "\n[4/6] Testing Distributed MapReduce Computation (Pi Estimation):"
hadoop jar "$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar" pi 2 10
echo "PASS: MapReduce job executed successfully."

echo -e "\n[5/6] Testing Hive Metastore & DDL/DML via Hive CLI:"
hive -e '
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS cluster_verify (id INT, node STRING, verified_at STRING);
INSERT INTO cluster_verify VALUES (1, "master", "OK"), (2, "worker", "OK");
SELECT * FROM cluster_verify;
'
echo "PASS: Hive Metastore and DDL/DML operations verified."

echo -e "\n[6/6] Testing HiveServer2 Client Access via Beeline JDBC:"
if ss -tulpn 2>/dev/null | grep -q ":10000 "; then
    echo "HiveServer2 is active on port 10000. Executing query over JDBC..."
    beeline -u "jdbc:hive2://master:10000/test_db" -n huser -e "SELECT count(*) FROM cluster_verify;"
    echo "PASS: HiveServer2 JDBC connectivity verified successfully."
elif ss -tulpn 2>/dev/null | grep -q ":2181 "; then
    echo "ZooKeeper active. Testing ZooKeeper dynamic discovery JDBC string..."
    beeline -u "jdbc:hive2://master:2181,worker1:2181,worker2:2181/test_db;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n huser -e "SELECT count(*) FROM cluster_verify;"
    echo "PASS: HiveServer2 ZooKeeper HA JDBC connectivity verified successfully."
else
    echo "Notice: HiveServer2 is not running on port 10000. Start it with 'make start' or 'scripts/start-hive.sh' to test JDBC connectivity."
fi

echo -e "\n=========================================================="
echo "=== All Cluster Assertions and Tests Passed Successfully! ==="
echo "=========================================================="

