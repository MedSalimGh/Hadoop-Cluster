#!/usr/bin/env bash
set -e

# Source environment
export HIVE_HOME=/opt/hive
export HADOOP_HOME=/home/huser/hadoop-3.3.6
export PATH=$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Ensure HDFS directories exist if HDFS is up and out of safemode
if hdfs dfsadmin -safemode get 2>/dev/null | grep -q "OFF"; then
    echo "Ensuring Hive warehouse and scratch directories exist in HDFS..."
    hadoop fs -mkdir -p /user/hive/warehouse /tmp/hive
    hadoop fs -chmod -R 777 /user/hive/warehouse /tmp/hive /tmp
fi

# Stop any stale instances cleanly before launching new daemons
if [ -f /vagrant/scripts/stop-hive.sh ]; then
    bash /vagrant/scripts/stop-hive.sh 2>/dev/null || true
fi

wait_for_port() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    local service_name="$4"

    echo "Waiting for $service_name to bind to $host:$port (timeout: ${timeout}s)..."
    for ((i = 1; i <= timeout; i++)); do
        if ss -tulpn | grep -q ":${port} "; then
            echo "$service_name is listening on port $port."
            return 0
        fi
        sleep 1
    done

    echo "ERROR: $service_name ($host:$port) failed to become ready after ${timeout}s!" >&2
    return 1
}

echo "Starting Hive Metastore service..."
nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &
echo $! > /tmp/hive-metastore.pid

wait_for_port localhost 9083 30 "Hive Metastore"

echo "Starting HiveServer2 service..."
nohup hive --service hiveserver2 > /tmp/hiveserver2.log 2>&1 &
echo $! > /tmp/hiveserver2.pid

wait_for_port localhost 10000 45 "HiveServer2"

echo "=========================================================="
echo "Hive Metastore (Port 9083) and HiveServer2 (Port 10000) are active."
echo "Connect with: beeline -u jdbc:hive2://localhost:10000 -n huser"
echo "=========================================================="
