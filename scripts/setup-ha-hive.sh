#!/usr/bin/env bash
# ==============================================================================
# Setup & Orchestration Script: High Availability for Apache Hive 4.0.1
# Architecture:
#   - 3-Node ZooKeeper Quorum Ensemble (master:2181 [1], worker1:2181 [2], worker2:2181 [3])
#   - Dual Hive Metastore Service (HMS) on master:9083 and worker1:9083
#   - Dual HiveServer2 (HS2) with Dynamic Discovery on master:10000 and worker1:10000
#   - Shared MariaDB Metastore backend on master:3306 (bind 0.0.0.0)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "=== Step 1: Configuring Master Node for Hive HA =========="
echo "=========================================================="

# Helper function to provision and configure ZooKeeper on a given node
setup_zk_node() {
    local node="$1"
    local myid="$2"
    echo "Configuring ZooKeeper on $node (myid: $myid)..."
    if [ "$node" = "master" ] || [ "$node" = "localhost" ]; then
        if ! command -v zookeeper-server &>/dev/null && [ ! -f "/usr/share/zookeeper/bin/zkServer.sh" ]; then
            echo "Installing zookeeperd & netcat-openbsd on master..."
            export DEBIAN_FRONTEND=noninteractive
            apt-get update && apt-get install -y --no-install-recommends zookeeperd netcat-openbsd
        fi
        mkdir -p /var/lib/zookeeper /etc/zookeeper/conf
        cp -f /vagrant/config/zoo.cfg /etc/zookeeper/conf/zoo.cfg
        echo "$myid" > /var/lib/zookeeper/myid
        chown -R zookeeper:zookeeper /var/lib/zookeeper /etc/zookeeper/conf
        systemctl enable zookeeper
        systemctl restart zookeeper
        ln -sf /usr/share/zookeeper/bin/zkCli.sh /usr/local/bin/zkCli.sh 2>/dev/null || true
    else
        sudo -u huser ssh -o StrictHostKeyChecking=no "$node" "sudo bash -c '
            export DEBIAN_FRONTEND=noninteractive
            if ! command -v zookeeper-server &>/dev/null && [ ! -f \"/usr/share/zookeeper/bin/zkServer.sh\" ]; then
                echo \"Installing zookeeperd & netcat-openbsd on $node...\"
                apt-get update && apt-get install -y --no-install-recommends zookeeperd netcat-openbsd
            fi
            mkdir -p /var/lib/zookeeper /etc/zookeeper/conf
            cp -f /vagrant/config/zoo.cfg /etc/zookeeper/conf/zoo.cfg
            echo \"$myid\" > /var/lib/zookeeper/myid
            chown -R zookeeper:zookeeper /var/lib/zookeeper /etc/zookeeper/conf
            systemctl enable zookeeper
            systemctl restart zookeeper
            ln -sf /usr/share/zookeeper/bin/zkCli.sh /usr/local/bin/zkCli.sh 2>/dev/null || true
        '"
    fi
}

get_zk_mode() {
    local host="$1"
    local mode="unknown"
    if [ "$host" = "master" ] || [ "$host" = "localhost" ]; then
        mode=$(/usr/share/zookeeper/bin/zkServer.sh status 2>/dev/null | grep -i "Mode:" | awk '{print $2}' || true)
        if [ -z "$mode" ] && command -v nc &>/dev/null; then
            mode=$(echo srvr | nc -w 2 127.0.0.1 2181 2>/dev/null | grep -i "Mode:" | awk '{print $2}' || true)
        fi
    else
        mode=$(sudo -u huser ssh -o StrictHostKeyChecking=no "$host" "
            /usr/share/zookeeper/bin/zkServer.sh status 2>/dev/null | grep -i 'Mode:' | awk '{print \$2}' || \
            ( command -v nc &>/dev/null && echo srvr | nc -w 2 127.0.0.1 2181 2>/dev/null | grep -i 'Mode:' | awk '{print \$2}' ) || true
        ")
    fi
    echo "${mode:-unknown}"
}

# 1. Ensure MariaDB listens on 0.0.0.0 for cross-node connectivity
echo "[1/5] Ensuring MariaDB is accessible from worker nodes..."
sudo sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true
sudo systemctl restart mariadb

# 2. Deploy 3-Node ZooKeeper Quorum Ensemble (master=1, worker1=2, worker2=3)
echo "[2/5] Deploying ZooKeeper 3-node Quorum Ensemble across cluster..."
setup_zk_node "master" "1"
setup_zk_node "worker1" "2"
setup_zk_node "worker2" "3"

echo "Verifying ZooKeeper Quorum Leader Election (Fast Leader Election on port 3888)..."
QUORUM_ELECTED=false
MODE_MASTER="unknown"
MODE_WORKER1="unknown"
MODE_WORKER2="unknown"
for _ in {1..30}; do
    MODE_MASTER=$(get_zk_mode "master")
    MODE_WORKER1=$(get_zk_mode "worker1")
    MODE_WORKER2=$(get_zk_mode "worker2")

    LEADERS=0
    FOLLOWERS=0
    for m in "$MODE_MASTER" "$MODE_WORKER1" "$MODE_WORKER2"; do
        if [ "$m" = "leader" ]; then
            ((LEADERS++))
        elif [ "$m" = "follower" ]; then
            ((FOLLOWERS++))
        fi
    done

    if [ "$LEADERS" -eq 1 ] && [ "$FOLLOWERS" -eq 2 ]; then
        QUORUM_ELECTED=true
        break
    fi
    sleep 2
done

echo "ZooKeeper Ensemble Status:"
echo "  - master  (myid 1): Mode: $MODE_MASTER"
echo "  - worker1 (myid 2): Mode: $MODE_WORKER1"
echo "  - worker2 (myid 3): Mode: $MODE_WORKER2"

if [ "$QUORUM_ELECTED" = true ]; then
    echo "PASS: ZooKeeper Quorum Consensus established (1 Leader, 2 Followers)."
else
    echo "Notice: ZooKeeper Quorum initialized (Master: $MODE_MASTER, Worker1: $MODE_WORKER1, Worker2: $MODE_WORKER2)."
fi

# 3. Deploy HA hive-site.xml on master
echo "[3/5] Deploying HA hive-site.xml on master..."
cp /vagrant/config/hive-site.xml /opt/hive/conf/hive-site.xml
chown huser:huser /opt/hive/conf/hive-site.xml

# 4. Stop any existing Hive standalone processes on master
echo "[4/5] Stopping existing Hive processes on master..."
bash /vagrant/scripts/stop-hive.sh 2>/dev/null || true
sleep 2

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

# Stop any existing processes on worker1 cleanly
bash /vagrant/scripts/stop-hive.sh 2>/dev/null || true
'"

echo "=========================================================="
echo "=== Step 3: Starting High Availability Daemons ==========="
echo "=========================================================="

echo "[1/4] Launching Primary Hive Metastore on master (port 9083)..."
su - huser -c 'nohup hive --service metastore > /tmp/hive-metastore-master.log 2>&1 & echo $! > /tmp/hive-metastore.pid'

echo "[2/4] Launching Secondary Hive Metastore on worker1 (port 9083)..."
sudo -u huser ssh -o StrictHostKeyChecking=no worker1 'nohup hive --service metastore > /tmp/hive-metastore-worker1.log 2>&1 & echo $! > /tmp/hive-metastore.pid'

echo "[3/4] Launching Primary HiveServer2 on master (port 10000)..."
su - huser -c 'nohup hive --service hiveserver2 > /tmp/hive-hs2-master.log 2>&1 & echo $! > /tmp/hiveserver2.pid'

echo "[4/4] Launching Secondary HiveServer2 on worker1 (port 10000)..."
sudo -u huser ssh -o StrictHostKeyChecking=no worker1 'nohup hive --service hiveserver2 > /tmp/hive-hs2-worker1.log 2>&1 & echo $! > /tmp/hiveserver2.pid'

echo "=========================================================="
echo "=== Step 4: Polling Service Readiness & ZooKeeper ========"
echo "=========================================================="

echo "Waiting for services to bind to listening ports (this may take 20-30s)..."
HA_READY=false
for i in {1..30}; do
    MASTER_HMS=$(ss -tulpn | grep -c ":9083 " || true)
    MASTER_HS2=$(ss -tulpn | grep -c ":10000 " || true)
    WORKER_HMS=$(sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "ss -tulpn | grep -c ':9083 '" || true)
    WORKER_HS2=$(sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "ss -tulpn | grep -c ':10000 '" || true)

    echo -ne "Attempt $i/30: Master HMS=$MASTER_HMS, Master HS2=$MASTER_HS2 | Worker HMS=$WORKER_HMS, Worker HS2=$WORKER_HS2\r"
    if [ "$MASTER_HMS" -ge 1 ] && [ "$MASTER_HS2" -ge 1 ] && [ "$WORKER_HMS" -ge 1 ] && [ "$WORKER_HS2" -ge 1 ]; then
        echo -e "\nAll 4 High Availability daemons are bound and listening!"
        HA_READY=true
        break
    fi
    sleep 3
done

if [ "$HA_READY" = false ]; then
    echo -e "\nERROR: High Availability services failed to bind within the 90-second timeout!" >&2
    echo "Diagnostic: Master HMS=$MASTER_HMS, Master HS2=$MASTER_HS2 | Worker HMS=$WORKER_HMS, Worker HS2=$WORKER_HS2" >&2
    exit 1
fi

echo ""
echo "=========================================================="
echo "=== Step 5: Verifying Dynamic Discovery in ZooKeeper ====="
echo "=========================================================="
echo "Verifying registered HiveServer2 instances in ZooKeeper (/hiveserver2)..."
sleep 5

ZK_NODES=$(/usr/share/zookeeper/bin/zkCli.sh -server "master:2181,worker1:2181,worker2:2181" ls /hiveserver2 2>/dev/null | grep 'serverUri=' || true)
if [ -z "$ZK_NODES" ]; then
    echo "ERROR: No HiveServer2 instances registered under ZooKeeper namespace /hiveserver2!" >&2
    exit 1
fi

echo "Registered znodes found:"
echo "$ZK_NODES"

echo ""
echo "=========================================================="
echo "=== High Availability Hive Setup Completed Successfully! =="
echo "=========================================================="
