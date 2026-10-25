# Complete Implementation Guide: Apache Hive High Availability (HA)

[![Hive Version](https://img.shields.io/badge/Apache%20Hive-4.0.1-FDEE21.svg?logo=apachehive&logoColor=black)](https://hive.apache.org/)
[![ZooKeeper Version](https://img.shields.io/badge/Apache%20ZooKeeper-3.8.0-D22128.svg?logo=apache&logoColor=white)](https://zookeeper.apache.org/)
[![Hadoop Version](https://img.shields.io/badge/Apache%20Hadoop-3.3.6-E65225.svg)](https://hadoop.apache.org/)
[![Metastore](https://img.shields.io/badge/Metastore-MariaDB%2010.11-003545.svg?logo=mariadb)](https://mariadb.org/)

---

## 1. High Availability Architecture Overview

In an enterprise Big Data infrastructure, a single Hive instance represents two critical **Single Points of Failure (SPOF)**:
1. **Hive Metastore Service (HMS)**: If the Thrift metastore daemon goes down, query compilation halts cluster-wide.
2. **HiveServer2 (HS2)**: If the JDBC/ODBC endpoint crashes, all client applications and BI dashboards disconnect.

This deployment implements a **Dual-Tier Active-Active High Availability** architecture using **Apache ZooKeeper 3.8.0** for dynamic service discovery and automatic client failover across `master` and `worker1`.

```
                                  +---------------------------------------+
                                  |      Client Application (Beeline)     |
                                  +-------------------+-------------------+
                                                      |
                                                      | 1. Discovers active HS2 instances
                                                      v
                                  +---------------------------------------+
                                  |     Apache ZooKeeper (Port 2181)      |
                                  |        zNode: /hiveserver2            |
                                  +-------------------+-------------------+
                                                      |
                                    +-----------------+-----------------+
                                    | 2. Dynamic Routing / Failover     |
                                    v                                   v
             +----------------------------------+   +----------------------------------+
             |      master (192.168.56.10)      |   |     worker1 (192.168.56.11)      |
             |  - HiveServer2 (Port 10000)      |   |  - HiveServer2 (Port 10000)      |
             |  - Hive Metastore (Port 9083)    |   |  - Hive Metastore (Port 9083)    |
             |  - ZooKeeper Server (Port 2181)  |   |                                  |
             +-----------------+----------------+   +-----------------+----------------+
                               |                                      |
                               +------------------+-------------------+
                                                  | Both connect to shared RDBMS
                                                  v
                               +--------------------------------------+
                               |    MariaDB Metastore (master:3306)   |
                               |          Database: metastore_db      |
                               +--------------------------------------+
```

### High Availability Specifications

| Component | Primary Node | Secondary Node | HA Mechanism | Port |
| :--- | :--- | :--- | :--- | :--- |
| **Apache ZooKeeper** | `master` | — | Coordination & Service Registry | `2181` |
| **Hive Metastore (HMS)** | `master` | `worker1` | Active-Active Multi-URI Client Failover | `9083` |
| **HiveServer2 (HS2)** | `master` | `worker1` | Dynamic ZooKeeper Discovery & Load Balancing | `10000` |
| **HiveServer2 WebUI** | `master` | `worker1` | Independent Monitoring Endpoints | `10002` |
| **Metastore Database** | `master` | Remote Access | Centralized MariaDB (bind `0.0.0.0`) | `3306` |

---

## 2. Configuration Code Snippets

### A. High-Availability `hive-site.xml`
The following configuration is deployed identically across all cluster nodes (`/opt/hive/conf/hive-site.xml`):

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <!-- ==================================================================== -->
    <!-- 1. Shared Relational Metastore Database Configuration                -->
    <!-- ==================================================================== -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://master/metastore_db?createDatabaseIfNotExist=true&amp;allowPublicKeyRetrieval=true</value>
        <description>Points to master node hostname mapped across all cluster nodes</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.mariadb.jdbc.Driver</value>
    </property>

    <!-- ==================================================================== -->
    <!-- 2. Hive Metastore Service (HMS) High Availability                    -->
    <!-- ==================================================================== -->
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://master:9083,thrift://worker1:9083</value>
        <description>Comma-separated list of active metastore URIs for client automatic failover</description>
    </property>
    <property>
        <name>hive.metastore.failure.retries</name>
        <value>5</value>
        <description>Number of retries upon metastore Thrift connection failure</description>
    </property>
    <property>
        <name>hive.metastore.client.connect.retry.delay</name>
        <value>2s</value>
        <description>Delay between metastore connection retries</description>
    </property>

    <!-- ==================================================================== -->
    <!-- 3. HiveServer2 Dynamic Service Discovery via ZooKeeper               -->
    <!-- ==================================================================== -->
    <property>
        <name>hive.server2.support.dynamic.service.discovery</name>
        <value>true</value>
        <description>Enables HS2 dynamic registration into ZooKeeper</description>
    </property>
    <property>
        <name>hive.server2.zookeeper.namespace</name>
        <value>hiveserver2</value>
        <description>ZooKeeper root znode namespace</description>
    </property>
    <property>
        <name>hive.zookeeper.quorum</name>
        <value>master:2181</value>
        <description>ZooKeeper ensemble quorum host:port</description>
    </property>
    <property>
        <name>hive.zookeeper.client.port</name>
        <value>2181</value>
    </property>
    <property>
        <name>hive.zookeeper.session.timeout</name>
        <value>30000</value>
    </property>

    <!-- ==================================================================== -->
    <!-- 4. Operational & Storage Settings                                    -->
    <!-- ==================================================================== -->
    <property>
        <name>hive.exec.local.scratchdir</name>
        <value>/tmp/hive</value>
    </property>
    <property>
        <name>hive.downloaded.resources.dir</name>
        <value>/tmp/hive_resources</value>
    </property>
    <property>
        <name>hive.server2.enable.doAs</name>
        <value>false</value>
    </property>
</configuration>
```

### B. MariaDB Cross-Node Access (`/etc/mysql/mariadb.conf.d/50-server.cnf`)
Ensure MariaDB accepts connections from worker nodes:
```ini
bind-address = 0.0.0.0
```

Grant remote access permissions:
```sql
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'%' IDENTIFIED BY 'hive';
FLUSH PRIVILEGES;
```

### C. Java 17 Reflection Flags (`/opt/hive/conf/hive-env.sh`)
```bash
export HADOOP_HOME=/home/huser/hadoop-3.3.6

export HADOOP_OPTS="$HADOOP_OPTS --add-opens=java.base/java.lang=ALL-UNNAMED \
--add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
--add-opens=java.base/java.lang.invoke=ALL-UNNAMED \
--add-opens=java.base/java.io=ALL-UNNAMED \
--add-opens=java.base/java.net=ALL-UNNAMED \
--add-opens=java.base/java.nio=ALL-UNNAMED \
--add-opens=java.base/java.util=ALL-UNNAMED \
--add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \
--add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED \
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
```

---

## 3. Implementation Steps

### Step 1: Install & Start Apache ZooKeeper on `master`
```bash
sudo apt-get update && sudo apt-get install -y zookeeperd
sudo systemctl enable --now zookeeper
```
*Verify port `2181` is listening:*
```bash
ss -tulpn | grep 2181
```

### Step 2: Configure MariaDB for Cross-Node Metastore Access
Edit `/etc/mysql/mariadb.conf.d/50-server.cnf`:
```bash
sudo sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
```

### Step 3: Deploy Hive Binaries and Config on `worker1`
On `master`, deploy Hive to `worker1` over SSH:
```bash
sudo -u huser ssh worker1 "sudo bash -c '
tar -zxf /vagrant/resources/apache-hive-4.0.1-bin.tar.gz -C /opt/
ln -sf /opt/apache-hive-4.0.1-bin /opt/hive
cp /vagrant/resources/mysql-connector-j-8.4.0.jar /opt/hive/lib/
cp /vagrant/config/hive-site.xml /opt/hive/conf/hive-site.xml
chown -R huser:huser /opt/apache-hive-4.0.1-bin /opt/hive
'"
```

### Step 4: Start Dual Hive Metastore Daemons (Port 9083)
- On `master`:
  ```bash
  sudo -u huser -i bash -c "nohup /opt/hive/bin/hive --service metastore > /tmp/hive-metastore-master.log 2>&1 &"
  ```
- On `worker1`:
  ```bash
  sudo -u huser ssh worker1 "sudo -u huser -i bash -c 'nohup /opt/hive/bin/hive --service metastore > /tmp/hive-metastore-worker1.log 2>&1 &'"
  ```

### Step 5: Start Dual HiveServer2 Daemons (Port 10000)
- On `master`:
  ```bash
  sudo -u huser -i bash -c "nohup /opt/hive/bin/hive --service hiveserver2 > /tmp/hive-hs2-master.log 2>&1 &"
  ```
- On `worker1`:
  ```bash
  sudo -u huser ssh worker1 "sudo -u huser -i bash -c 'nohup /opt/hive/bin/hive --service hiveserver2 > /tmp/hive-hs2-worker1.log 2>&1 &'"
  ```

### Step 6: Verify Dynamic ZooKeeper Registration
Run the ZooKeeper CLI to inspect the registered ephemeral znodes:
```bash
/usr/share/zookeeper/bin/zkCli.sh -server localhost:2181 ls /hiveserver2
```
*Expected Output:*
```text
[serverUri=master:10000;version=4.0.1;sequence=0000000000, serverUri=worker1:10000;version=4.0.1;sequence=0000000001]
```

### Step 7: Client Connection via ZooKeeper Discovery
Connect via Beeline using the discovery URL:
```bash
beeline -u "jdbc:hive2://master:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n huser -e "SHOW DATABASES;"
```

### Step 8: Failover Simulation & Recovery
Simulate a catastrophic failure on `master`:
```bash
pkill -9 -f "org.apache.hive.service.server.HiveServer2"
```
Execute query again via the exact same ZooKeeper URL:
```bash
beeline -u "jdbc:hive2://master:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n huser -e "SELECT current_timestamp();"
```
*Beeline automatically detects `master:10000` is offline, falls over, and routes the query directly to `worker1:10000`.*

---

## 4. Verification Evidence & Automated Testing Script

To run the complete automated test suite on your cluster:
```bash
sudo bash /vagrant/scripts/test-ha-failover.sh
```
