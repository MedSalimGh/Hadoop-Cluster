#!/usr/bin/env bash
# ==============================================================================
# Setup & Orchestration Script: High Availability for Apache Hive 4.0.1
# Architecture:
#   - ZooKeeper Quorum Service Discovery on master:2181
#   - Dual Hive Metastore Service (HMS) on master:9083 and worker1:9083
#   - Dual HiveServer2 (HS2) with Dynamic Discovery on master:10000 and worker1:10000
#   - Shared MariaDB Metastore backend on master:3306 (bind 0.0.0.0)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "=== Step 1: Configuring Master Node for Hive HA =========="
echo "=========================================================="

# 1. Ensure MariaDB listens on 0.0.0.0 for cross-node connectivity
echo "[1/4] Ensuring MariaDB is accessible from worker nodes..."
sudo sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true
sudo systemctl restart mariadb

# 2. Ensure ZooKeeper is installed & running on master:2181
echo "[2/4] Verifying ZooKeeper service on master:2181..."
if ! command -v zookeeper-server &>/dev/null && [ ! -f "/usr/share/zookeeper/bin/zkServer.sh" ]; then
    echo "Installing zookeeperd on master..."
    sudo apt-get update && sudo apt-get install -y zookeeperd
fi
sudo systemctl enable --now zookeeper
sudo ln -sf /usr/share/zookeeper/bin/zkCli.sh /usr/local/bin/zkCli.sh 2>/dev/null || true

# 3. Deploy HA hive-site.xml on master
echo "[3/4] Deploying HA hive-site.xml on master..."
cp /vagrant/config/hive-site.xml /opt/hive/conf/hive-site.xml
chown huser:huser /opt/hive/conf/hive-site.xml

# 4. Stop any existing Hive standalone processes on master
echo "[4/4] Stopping existing Hive processes on master..."
pkill -f "org.apache.hadoop.hive.metastore.HiveMetaStore" || true
pkill -f "org.apache.hive.service.server.HiveServer2" || true
sleep 3

echo "=========================================================="
echo "=== Step 2: Provisioning Apache Hive 4.0.1 on worker1 ===="
echo "=========================================================="

sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "sudo bash -c '
set -e
if [ ! -d \"/opt/apache-hive-4.0.1-bin\" ]; then
    echo \"Extracting Hive 4.0.1 binaries on worker1...\"
    tar -zxf /vagrant/resources/apache-hive-4.0.1-bin.tar.gz -C /opt/
    ln -sf /opt/apache-hive-4.0.1-bin /opt/hive
fi

# Link MySQL connector
cp -f /vagrant/resources/mysql-connector-j-8.4.0.jar /opt/hive/lib/ 2>/dev/null || true

# Deploy hive-env.sh with Java 17 reflection access flags
echo \"export HADOOP_HOME=/home/huser/hadoop-3.3.6\" > /opt/hive/conf/hive-env.sh
cat << \"ENV_EOF\" >> /opt/hive/conf/hive-env.sh
export HADOOP_OPTS=\"\$HADOOP_OPTS --add-opens=java.base/java.lang=ALL-UNNAMED \
--add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
--add-opens=java.base/java.lang.invoke=ALL-UNNAMED \
--add-opens=java.base/java.io=ALL-UNNAMED \
--add-opens=java.base/java.net=ALL-UNNAMED \
--add-opens=java.base/java.nio=ALL-UNNAMED \
--add-opens=java.base/java.util=ALL-UNNAMED \
--add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \
--add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED \
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED\"
ENV_EOF

# Copy HA configuration
cp -f /vagrant/config/hive-site.xml /opt/hive/conf/hive-site.xml
chown -R huser:huser /opt/apache-hive-4.0.1-bin /opt/hive

# Ensure profile variables
if ! grep -q \"HIVE_HOME\" /home/huser/.bashrc; then
    echo \"export HIVE_HOME=/opt/hive\" >> /home/huser/.bashrc
    echo \"export PATH=\\\$PATH:\\\$HIVE_HOME/bin\" >> /home/huser/.bashrc
fi

# Stop any existing processes on worker1
pkill -f \"org.apache.hadoop.hive.metastore.HiveMetaStore\" || true
pkill -f \"org.apache.hive.service.server.HiveServer2\" || true
'"

echo "=========================================================="
echo "=== Step 3: Starting High Availability Daemons ==========="
echo "=========================================================="

echo "[1/4] Launching Primary Hive Metastore on master (port 9083)..."
su - huser -c "nohup hive --service metastore > /tmp/hive-metastore-master.log 2>&1 &"

echo "[2/4] Launching Secondary Hive Metastore on worker1 (port 9083)..."
sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "nohup hive --service metastore > /tmp/hive-metastore-worker1.log 2>&1 &"

echo "[3/4] Launching Primary HiveServer2 on master (port 10000)..."
su - huser -c "nohup hive --service hiveserver2 > /tmp/hive-hs2-master.log 2>&1 &"

echo "[4/4] Launching Secondary HiveServer2 on worker1 (port 10000)..."
sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "nohup hive --service hiveserver2 > /tmp/hive-hs2-worker1.log 2>&1 &"

echo "=========================================================="
echo "=== Step 4: Polling Service Readiness & ZooKeeper ========"
echo "=========================================================="

echo "Waiting for services to bind to listening ports (this may take 20-30s)..."
for i in {1..30}; do
    MASTER_HMS=$(ss -tulpn | grep -c 9083 || true)
    MASTER_HS2=$(ss -tulpn | grep -c 10000 || true)
    WORKER_HMS=$(sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "ss -tulpn | grep -c 9083" || true)
    WORKER_HS2=$(sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "ss -tulpn | grep -c 10000" || true)

    echo -ne "Attempt $i/30: Master HMS=$MASTER_HMS, Master HS2=$MASTER_HS2 | Worker HMS=$WORKER_HMS, Worker HS2=$WORKER_HS2\r"
    if [ "$MASTER_HMS" -ge 1 ] && [ "$MASTER_HS2" -ge 1 ] && [ "$WORKER_HMS" -ge 1 ] && [ "$WORKER_HS2" -ge 1 ]; then
        echo -e "\nAll 4 High Availability daemons are bound and listening!"
        break
    fi
    sleep 3
done

echo ""
echo "=========================================================="
echo "=== Step 5: Verifying Dynamic Discovery in ZooKeeper ====="
echo "=========================================================="
echo "Registered HiveServer2 instances in ZooKeeper (/hiveserver2):"
sleep 5
/usr/share/zookeeper/bin/zkCli.sh -server localhost:2181 ls /hiveserver2 2>/dev/null | tail -n 5

echo ""
echo "=========================================================="
echo "=== High Availability Hive Setup Completed Successfully! =="
echo "=========================================================="
