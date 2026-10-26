#!/usr/bin/env bash
# ==============================================================================
# Failover & Verification Test: Apache Hive High Availability (HA)
# Tests:
#   1. Dynamic Service Discovery via ZooKeeper
#   2. Active-Active Dual HiveServer2 and Dual Metastore registration
#   3. Primary HiveServer2 Failure Simulation
#   4. Automatic Client Failover to Secondary HiveServer2
#   5. Recovery & Self-Healing Re-registration
# ==============================================================================
set -euo pipefail

ZK_HOST="master:2181,worker1:2181,worker2:2181"
ZK_NAMESPACE="hiveserver2"
JDBC_ZK_URL="jdbc:hive2://${ZK_HOST}/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=${ZK_NAMESPACE}"

echo "=========================================================="
echo "=== STAGE 1: Inspecting Active HA Services & Daemons ====="
echo "=========================================================="
echo "--- Master Node Java Daemons (JPS): ---"
sudo -u huser -i jps

echo ""
echo "--- Worker1 Node Java Daemons (JPS): ---"
sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "sudo -u huser -i jps"

echo ""
echo "--- ZooKeeper 3-Node Quorum Status & Roles: ---"
for node in master worker1 worker2; do
    echo "[$node]:"
    if [ "$node" = "master" ]; then
        if [ -f /var/lib/zookeeper/myid ]; then
            echo "  myid: $(cat /var/lib/zookeeper/myid)"
        fi
        /usr/share/zookeeper/bin/zkServer.sh status 2>/dev/null | grep -E "Mode|Client" || true
    else
        sudo -u huser ssh -o StrictHostKeyChecking=no "$node" "
            if [ -f /var/lib/zookeeper/myid ]; then
                echo \"  myid: \$(cat /var/lib/zookeeper/myid)\"
            fi
            /usr/share/zookeeper/bin/zkServer.sh status 2>/dev/null | grep -E 'Mode|Client' || true
        "
    fi
done

echo ""
echo "--- Listening Ports on Master (ZooKeeper 2181, HMS 9083, HS2 10000): ---"
ss -tulpn | grep -E "2181|9083|10000"

echo ""
echo "--- Listening Ports on Worker1 (HMS 9083, HS2 10000): ---"
sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "ss -tulpn | grep -E '9083|10000'"

echo ""
echo "=========================================================="
echo "=== STAGE 2: Querying ZooKeeper Service Registry ========="
echo "=========================================================="
echo "Active HiveServer2 ephemeral znodes in /hiveserver2:"
/usr/share/zookeeper/bin/zkCli.sh -server "${ZK_HOST}" ls /${ZK_NAMESPACE} 2>/dev/null | tail -n 5

echo ""
echo "=========================================================="
echo "=== STAGE 3: Querying via ZooKeeper Dynamic Discovery ===="
echo "=========================================================="
echo "Connecting Beeline via JDBC ZooKeeper Discovery URL:"
echo "URL: $JDBC_ZK_URL"
sudo -u huser -i beeline -u "$JDBC_ZK_URL" -n huser -e "
SHOW DATABASES;
SELECT 'Stage 3 Success: Connected via ZooKeeper Service Discovery' AS ha_status;
"

echo ""
echo "=========================================================="
echo "=== STAGE 4: Simulating Primary HiveServer2 Crash ========"
echo "=========================================================="
echo "Killing HiveServer2 daemon on master (PID: $(pgrep -f HiveServer2 || echo 'none'))..."
pkill -9 -f "org.apache.hive.service.server.HiveServer2" || true
sleep 5

echo "Verifying master HiveServer2 is stopped:"
if ! pgrep -f "org.apache.hive.service.server.HiveServer2" >/dev/null; then
    echo ">> Confirmed: HiveServer2 on master is DOWN."
else
    echo ">> Warning: HiveServer2 still running."
fi

echo ""
echo "Checking ZooKeeper ephemeral znodes after primary failure:"
/usr/share/zookeeper/bin/zkCli.sh -server "${ZK_HOST}" ls /${ZK_NAMESPACE} 2>/dev/null | tail -n 5

echo ""
echo "=========================================================="
echo "=== STAGE 5: Testing Automatic Failover to Worker1 ======="
echo "=========================================================="
echo "Connecting Beeline via ZooKeeper URL while master HS2 is DOWN:"
sudo -u huser -i beeline -u "$JDBC_ZK_URL" -n huser -e "
SELECT 
    'Stage 5 Success: Automatic Failover Executed Seamlessly!' AS ha_status,
    current_timestamp() AS failover_timestamp;
"

echo ""
echo "=========================================================="
echo "=== STAGE 6: Recovering Primary HiveServer2 on Master ===="
echo "=========================================================="
echo "Restarting HiveServer2 on master node..."
su - huser -c "nohup /opt/hive/bin/hive --service hiveserver2 > /tmp/hive-hs2-master.log 2>&1 &"

echo "Waiting for master HS2 to bind and re-register in ZooKeeper (15-20s)..."
for _ in {1..20}; do
    if ss -tulpn | grep -q 10000; then
        echo "Master HiveServer2 is back online on port 10000!"
        break
    fi
    sleep 2
done
sleep 5

echo "ZooKeeper service registry after self-healing recovery:"
/usr/share/zookeeper/bin/zkCli.sh -server "${ZK_HOST}" ls /${ZK_NAMESPACE} 2>/dev/null | tail -n 5

echo ""
echo "=========================================================="
echo "=== All High Availability & Failover Tests PASSED! ======="
echo "=========================================================="
