# Apache Hadoop 3.3.6 & Apache Hive 4.0.1 Multi-Node Cluster with High Availability (IaC with Vagrant)

[![Hadoop Version](https://img.shields.io/badge/Apache%20Hadoop-3.3.6-E65225.svg)](https://hadoop.apache.org/)
[![Hive Version](https://img.shields.io/badge/Apache%20Hive-4.0.1-FDEE21.svg?logo=apachehive&logoColor=black)](https://hive.apache.org/)
[![ZooKeeper Version](https://img.shields.io/badge/Apache%20ZooKeeper-3.8.0-0B8E36.svg)](https://zookeeper.apache.org/)
[![Database](https://img.shields.io/badge/Metastore-MariaDB%2010.11%20%2F%20MySQL-003545.svg?logo=mariadb)](https://mariadb.org/)
[![Java Version](https://img.shields.io/badge/Java-OpenJDK%2017%20LTS-ED8B00.svg?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.x-1563FF.svg?logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.x-246BB3.svg?logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![OS](https://img.shields.io/badge/OS-Debian%2012%20Bookworm-D70A53.svg?logo=debian&logoColor=white)](https://www.debian.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An enterprise-grade, fully automated 3-node distributed Big Data cluster deploying **Apache Hadoop 3.3.6** (HDFS storage & YARN resource negotiation) and **Apache Hive 4.0.1** in an **Active-Active High Availability (HA)** architecture coordinated by **Apache ZooKeeper 3.8.0** with a **MariaDB 10.11 relational metastore backend**. Deployed completely as Infrastructure as Code (IaC) using **Vagrant** and **Oracle VirtualBox**.

Engineered for modern production environments running on **OpenJDK 17 LTS (HotSpot)** with comprehensive JEP 403 reflection access flags, dynamic runtime SSH key generation, resilient parallel shell execution (`pdsh`), automated daemon supervision, dual HiveServer2 endpoints with dynamic service discovery, dual Hive Metastore failover, and automated self-healing disaster recovery scripts.

---

## 🌐 Cluster Architecture & Topology

The cluster consists of three Debian 12 (Bookworm) 64-bit virtual machines interconnected via a dedicated, non-routed private network (`192.168.56.0/24`):

```
                               +-------------------------------------------------------------+
                               |                   master (192.168.56.10)                    |
                               |  - Apache ZooKeeper (Port 2181) [HA Consensus Coordinator]  |
                               |  - HDFS: NameNode (Port 9000, WebUI 9870)                   |
                               |  - HDFS: SecondaryNameNode (Port 9868)                      |
                               |  - YARN: ResourceManager (Port 8032, WebUI 8088)            |
                               |  - RDBMS: MariaDB Metastore Backend (Port 3306)             |
                               |  - Hive: Metastore Service HMS 1 (Port 9083)                |
                               |  - Hive: HiveServer2 HS2 1 (Port 10000, WebUI 10002)        |
                               +------------------------------+------------------------------+
                                                              |
                               +------------------------------+------------------------------+
                               |                                                             |
                +--------------+---------------+                             +---------------+--------------+
                |    worker1 (192.168.56.11)   |                             |    worker2 (192.168.56.12)   |
                | - HDFS: DataNode 1 (Port 9864|                             | - HDFS: DataNode 2 (Port 9864|
                | - YARN: NodeManager 1        |                             | - YARN: NodeManager 2        |
                | - Hive: Metastore HMS 2      |                             +------------------------------+
                |   (Port 9083 - HA Active)    |
                | - Hive: HiveServer2 HS2 2    |
                |   (Port 10000, WebUI 10002)  |
                +------------------------------+
```

### High Availability (HA) Multi-Tier Design

1. **Coordination Tier (ZooKeeper 3.8.0):** Runs on `master:2181`. HiveServer2 instances register ephemeral sequential znodes under namespace `/hiveserver2`. Clients query ZooKeeper to dynamically discover available live HS2 instances with automatic random load balancing and transparent failover.
2. **Compute & Query Serving Tier (Active-Active HiveServer2):** Dual HS2 instances run simultaneously on `master:10000` and `worker1:10000`. If one instance crashes or is killed, its ephemeral znode expires; ZooKeeper immediately directs incoming JDBC/ODBC queries to the surviving node with zero service downtime.
3. **Metadata Catalog Tier (Dual Hive Metastore Services):** Dual HMS instances run on `master:9083` and `worker1:9083`. Clients and execution engines connect via fallback URI list `thrift://master:9083,thrift://worker1:9083`.
4. **Relational Database Tier (MariaDB 10.11 Metastore):** Centralized on `master:3306` with remote network binding (`bind-address = 0.0.0.0`), allowing both HMS instances to synchronize metadata safely and concurrently.

### Node Specifications & Resource Allocation

| Node | Hostname | IP Address | Roles & Daemons | vCPUs | RAM | Storage / Disk |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Master** | `master` | `192.168.56.10` | NameNode, SecondaryNameNode, ResourceManager, MariaDB 10.11, ZooKeeper 3.8.0, Hive Metastore 1, HiveServer2 1 | 2 | 2048 MB | Root (20GB) + Shared `/vagrant` |
| **Worker 1** | `worker1` | `192.168.56.11` | DataNode 1, NodeManager 1, Hive Metastore 2 (HA), HiveServer2 2 (HA) | 1 | 1280 MB | Root (20GB) + Shared `/vagrant` |
| **Worker 2** | `worker2` | `192.168.56.12` | DataNode 2, NodeManager 2 | 1 | 1280 MB | Root (20GB) + Shared `/vagrant` |

---

## 📁 Repository Structure

```
Hadoop-Cluster/
├── config/                          # Centralized Hadoop & Hive XML configuration templates
│   ├── core-site.xml                # HDFS defaultFS, IPC timeouts & proxyuser authorization
│   ├── fix-java17-yarn.sh           # Helper utility for YARN container Java 17 reflection flags
│   ├── hdfs-site.xml                # Block replication (2), NameNode/DataNode local paths
│   ├── hive-site.xml                # Metastore JDBC, ZooKeeper discovery & dual HMS URIs
│   ├── mapred-site.xml              # MapReduce framework, memory allocation & AM classpath
│   ├── workers                      # DataNode & NodeManager worker node inventory
│   └── yarn-site.xml                # ResourceManager, NodeManager & auxiliary shuffle services
├── resources/                       # Binary connectors and driver dependencies
│   └── mysql-connector-j-8.4.0.jar  # Official MySQL/MariaDB JDBC Connector (Type 4)
├── scripts/                         # Cluster lifecycle, deployment, and testing shell scripts
│   ├── fix-path.sh                  # Profile path resolution utility
│   ├── setup-common.sh              # Base OS packages, OpenJDK 17 & dynamic ed25519 SSH keys
│   ├── setup-ha-hive.sh             # ZooKeeper deployment, MariaDB remote binding & HA Hive
│   ├── setup-hadoop.sh              # Hadoop 3.3.6 automated installation & profile setup
│   ├── setup-master.sh              # MariaDB metastore provisioning & Hive master deployment
│   ├── setup-worker.sh              # Worker NodeManager/DataNode provisioning
│   ├── start-cluster.sh             # Automated cluster-wide launcher (HDFS + YARN + Hive)
│   ├── start-hive.sh                # Metastore & HiveServer2 launcher with port polling
│   ├── stop-cluster.sh              # Graceful cluster-wide shutdown (Hive + YARN + HDFS)
│   ├── stop-hive.sh                 # Graceful Hive process shutdown script
│   ├── test-ha-failover.sh          # 6-stage automated crash simulation & failover validator
│   ├── test-hive.sql                # Verification DDL/DML SQL script
│   └── verify-cluster.sh            # 5-stage automated cluster health check
├── .gitignore                       # Git exclusion rules (keys, datasets, temp files)
├── LICENSE                          # MIT License
├── Makefile                         # Unified cluster automation commands (make up/start/stop)
├── README.md                        # Master cluster architecture and operational manual
├── SECURITY.md                      # Security policy, threat model, and hardening guide
└── Vagrantfile                      # 3-Node VirtualBox Infrastructure-as-Code definition
```

---

## ⚡ Quick Start (Automated 1-Click Deployment)

### 1. Prerequisites
- **Git** ([Download](https://git-scm.com/))
- **Oracle VirtualBox 7.x** ([Download](https://www.virtualbox.org/))
- **Vagrant 2.3+** ([Download](https://www.vagrantup.com/))
- System Hardware: Minimum 8 GB Host RAM and 25 GB free disk space. Supported across Windows, macOS, and Linux.

### 2. Clone Repository & Boot Cluster
```bash
git clone https://github.com/MedSalimGh/Hadoop-Cluster.git
cd Hadoop-Cluster
vagrant up
```
*(Alternatively, run `make up`)*

*Vagrant sequentially boots and fully provisions all 3 virtual machines:*
1. Installs OpenJDK 17 LTS, base utilities, and configures private IP networking.
2. Dynamically generates an `ed25519` SSH keypair on `master` and securely authorizes it on workers (private key never leaves `master`).
3. Downloads, installs, and configures Apache Hadoop 3.3.6 across all nodes.
4. Formats the HDFS NameNode on `master`.
5. Installs MariaDB 10.11, configures remote network binding (`0.0.0.0`), downloads Apache Hive 4.0.1, links the JDBC connector, and initializes the metastore schema.

### 3. Start Distributed Cluster Services
```bash
# Start HDFS, YARN, and Hive services with a single command
vagrant ssh master -c "bash /vagrant/scripts/start-cluster.sh"
```
*(Alternatively, run `make start`)*

### 4. Optional: Enable High Availability (HA) & Test Failover
To activate Apache ZooKeeper dynamic service discovery and deploy Hive on `worker1` in an Active-Active HA topology:
```bash
# Deploy ZooKeeper and launch secondary HA instances on worker1
vagrant ssh master -c "bash /vagrant/scripts/setup-ha-hive.sh"
# (or: make ha-setup)

# Run 6-stage automated disaster recovery and failover verification
vagrant ssh master -c "bash /vagrant/scripts/test-ha-failover.sh"
# (or: make ha-test)
```

### 5. Validate Cluster Health
```bash
# Run 5-stage automated cluster verification suite
vagrant ssh master -c "bash /vagrant/scripts/verify-cluster.sh"
# (or: make verify)
```

---

## 🛠️ Complete End-to-End Installation & Architecture Tutorial

This section provides a comprehensive technical walkthrough of how every component is constructed, configured, and integrated across the cluster.

---

### Phase 1: Operating System & Network Architecture

#### 1. Host-Only Private Networking & Hostname Resolution
All nodes communicate over a non-routed `192.168.56.0/24` subnet. On every VM, `/etc/hosts` maps hostnames to private IPs to guarantee deterministic routing:
```text
127.0.0.1 localhost
192.168.56.10 master namenode
192.168.56.11 worker1 datanode1
192.168.56.12 worker2 datanode2
```

#### 2. Dedicated Cluster Account (`huser`)
To adhere to the principle of least privilege, all Hadoop and Hive daemons execute under a dedicated non-root user `huser` with passwordless `sudo` privileges:
```bash
useradd -m -s /bin/bash -U huser
echo "huser:huser" | chpasswd
usermod -aG sudo huser
echo "huser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/huser
chmod 0440 /etc/sudoers.d/huser
```

#### 3. Dynamic Runtime SSH Key Generation (No Stored Secrets)
Rather than hardcoding static private keys in version control, `scripts/setup-common.sh` generates an `ed25519` keypair during provisioning if one does not already exist, sharing it across `/vagrant/keys/` (which is excluded from Git):
```bash
mkdir -p /home/huser/.ssh /vagrant/keys

if [ ! -f /vagrant/keys/id_rsa ]; then
    if [ ! -f /home/huser/.ssh/id_rsa ]; then
        ssh-keygen -t ed25519 -N '' \
          -f /home/huser/.ssh/id_rsa \
          -C "hadoop-vagrant"
    fi
    cp /home/huser/.ssh/id_rsa /vagrant/keys/id_rsa
    cp /home/huser/.ssh/id_rsa.pub /vagrant/keys/id_rsa.pub
else
    cp /vagrant/keys/id_rsa /home/huser/.ssh/id_rsa
    cp /vagrant/keys/id_rsa.pub /home/huser/.ssh/id_rsa.pub
fi

cat /home/huser/.ssh/id_rsa.pub >> /home/huser/.ssh/authorized_keys

cat << 'EOF' > /home/huser/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

chmod 700 /home/huser/.ssh
chmod 600 /home/huser/.ssh/id_rsa
chmod 644 /home/huser/.ssh/id_rsa.pub
chmod 600 /home/huser/.ssh/authorized_keys
chmod 600 /home/huser/.ssh/config
chown -R huser:huser /home/huser/.ssh
```

---

### Phase 2: Apache Hadoop 3.3.6 (HDFS & YARN) Setup

#### 1. Binary Installation & Environment Variables
Hadoop 3.3.6 is deployed to `/home/huser/hadoop-3.3.6`. Global environment paths are registered in `/etc/profile.d/hadoop-hive.sh` and appended to `~/.bashrc`:
```bash
JAVA_DETECTED=$(readlink -f /usr/bin/java | sed "s:/bin/java::")

cat << EOF > /etc/profile.d/hadoop-hive.sh
export JAVA_HOME=${JAVA_DETECTED}
export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
export HIVE_HOME=/opt/hive
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$HIVE_HOME/bin
export PDSH_RCMD_TYPE=ssh
EOF
```

#### 2. Parallel Shell (`pdsh`) Configuration
Debian's `pdsh` package defaults to the legacy `rcmd` protocol, which fails with `rcmd: socket: Permission denied` when invoked by non-root user `huser`. By exporting `PDSH_RCMD_TYPE=ssh` in `hadoop-env.sh`, cluster scripts (`start-dfs.sh`, `start-yarn.sh`) use SSH sockets.

#### 3. Core Distributed Files
- **`config/core-site.xml`**: Directs default file system calls to `hdfs://master:9000` and configures wildcard proxyuser authorization for `huser` and `hive` to submit jobs on behalf of other users.
- **`config/hdfs-site.xml`**: Sets block replication to `2` (matching the two physical DataNodes) and defines dedicated local storage directories for NameNode metadata (`FSImage`, `EditLogs`) and DataNode block pools.
- **`config/workers`**: Lists active worker nodes:
  ```text
  worker1
  worker2
  ```
- **`config/yarn-site.xml`**: Binds the ResourceManager to `master` (port 8032, WebUI 8088), enables `mapreduce_shuffle` auxiliary service, and sets memory allocation limits (`yarn.nodemanager.resource.memory-mb = 1024`).
- **`config/mapred-site.xml`**: Selects YARN as the execution framework, caps container memory (`mapreduce.map.memory.mb = 512`, `mapreduce.reduce.memory.mb = 512`), and injects container classpath variables and Java 17 reflection flags.

---

### Phase 3: Relational Metastore Backend (MariaDB 10.11)

Apache Hive requires an external RDBMS to manage schema catalogs, partitions, column types, and serde information.

#### 1. MariaDB Installation & Remote Network Binding
By default, Debian's MariaDB binds only to `127.0.0.1`. In an HA topology, `worker1`'s Hive Metastore must connect remotely to MariaDB on `master`.
In `/etc/mysql/mariadb.conf.d/50-server.cnf`:
```ini
bind-address = 0.0.0.0
```
Restart MariaDB to apply:
```bash
sudo systemctl restart mariadb
```

#### 2. Metastore Database & User Grants
```sql
CREATE DATABASE IF NOT EXISTS metastore_db;
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hive';
CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'%';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'localhost';
FLUSH PRIVILEGES;
```

---

### Phase 4: Apache Hive 4.0.1 & Java 17 (JEP 403) Compatibility

#### 1. Binary Installation & MySQL JDBC Connector
Hive 4.0.1 is deployed to `/opt/hive`. The Type 4 MySQL connector `mysql-connector-j-8.4.0.jar` is copied into `/opt/hive/lib/`:
```bash
sudo cp /vagrant/resources/mysql-connector-j-8.4.0.jar /opt/hive/lib/
```

#### 2. OpenJDK 17 Strong Encapsulation Workaround (`hive-env.sh`)
Java 17 strictly enforces JEP 403, which blocks deep reflective access across package boundaries. Without explicit flags, Hive query planning and Kryo serialization fail with `InaccessibleObjectException`.
In `/opt/hive/conf/hive-env.sh`:
```bash
export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HADOOP_OPTS="$HADOOP_OPTS \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
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

#### 3. HDFS Scratch & Warehouse Directories
```bash
hadoop fs -mkdir -p /user/hive/warehouse
hadoop fs -mkdir -p /tmp/hive
hadoop fs -chmod -R 777 /user/hive/warehouse
hadoop fs -chmod -R 777 /tmp/hive
hadoop fs -chmod 777 /tmp
```

#### 4. Metastore Schema Initialization
```bash
schematool -initSchema -dbType mysql
```

---

### Phase 5: High Availability (HA) Architecture with Apache ZooKeeper

The High Availability deployment eliminates Single Points of Failure (SPOF) across the Hive stack.

#### 1. ZooKeeper 3.8.0 Coordination Service
Installed via `zookeeperd` on `master`, listening on port `2181`:
```bash
sudo apt-get install -y zookeeper zookeeperd
sudo systemctl enable --now zookeeper
```

#### 2. Dynamic Service Discovery in `hive-site.xml`
The following properties enable dynamic discovery and dual-metastore failover:
```xml
<!-- Enable Dynamic Service Discovery via ZooKeeper -->
<property>
    <name>hive.server2.support.dynamic.service.discovery</name>
    <value>true</value>
</property>

<!-- ZooKeeper Ensemble Address -->
<property>
    <name>hive.zookeeper.quorum</name>
    <value>master:2181</value>
</property>

<!-- ZooKeeper Namespace for HiveServer2 Instances -->
<property>
    <name>hive.server2.zookeeper.namespace</name>
    <value>hiveserver2</value>
</property>

<!-- Dual Hive Metastore Service URIs for Client Failover -->
<property>
    <name>hive.metastore.uris</name>
    <value>thrift://master:9083,thrift://worker1:9083</value>
</property>

<!-- Metastore Relational Backend Connection URL -->
<property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://master:3306/metastore_db?createDatabaseIfNotExist=true&amp;allowPublicKeyRetrieval=true&amp;useSSL=false</value>
</property>
```

#### 3. Worker 1 Provisioning as Secondary HA Node
`scripts/setup-ha-hive.sh` automatically synchronizes the complete Hive 4.0.1 environment from `master` to `worker1`, including binaries, configurations, libraries, and profile scripts:
```bash
rsync -a -e ssh /opt/hive worker1:/opt/
ssh worker1 "sudo cp /opt/hive/conf/hive.sh /etc/profile.d/hive.sh"
```

#### 4. Automated Cluster-Wide HA Launch
`scripts/setup-ha-hive.sh` starts all 4 service instances concurrently:
- `master`: Hive Metastore (port `9083`) & HiveServer2 (port `10000`, WebUI `10002`)
- `worker1`: Hive Metastore (port `9083`) & HiveServer2 (port `10000`, WebUI `10002`)

Both HS2 instances register ephemeral sequential znodes in ZooKeeper:
```text
/hiveserver2/serverUri=master:10000;version=4.0.1;sequence=0000000001
/hiveserver2/serverUri=worker1:10000;version=4.0.1;sequence=0000000002
```

---

## 🔍 Understanding `RunJar` in JVM Process Listings (`jps`)

When executing `jps` on cluster nodes, you will observe multiple processes listed with the name **`RunJar`**:

```text
huser@master:~$ jps
6605 RunJar
7786 RunJar
5083 NameNode
5337 SecondaryNameNode
5585 ResourceManager
```

### Why Does This Occur?
In Hadoop and Hive architectures, Java processes are launched using the universal entrypoint wrapper class:
$$\texttt{org.apache.hadoop.util.RunJar}$$

The `jps` command inspects the JVM process table and outputs only the simple class name of the main entrypoint (`RunJar`), rather than the application context.

### Identifying Which Process is Which
You can correlate the PID directly to its active listening port using `ss -tulpn` or `netstat`:

| Node | PID Example | Process Class | Active Port(s) | Service Function |
| :--- | :--- | :--- | :--- | :--- |
| **`master`** | `6605` | `org.apache.hadoop.hive.metastore.HiveMetaStore` | `9083` | Primary Hive Metastore Thrift Service |
| **`master`** | `7786` | `org.apache.apache.hive.service.server.HiveServer2` | `10000` (RPC), `10002` (WebUI) | Primary HiveServer2 Query Engine |
| **`worker1`** | `2406` | `org.apache.hadoop.hive.metastore.HiveMetaStore` | `9083` | Active Secondary Metastore Service |
| **`worker1`** | `2130` | `org.apache.apache.hive.service.server.HiveServer2` | `10000` (RPC), `10002` (WebUI) | Active Secondary HiveServer2 Query Engine |

To view full command line details directly:
```bash
jps -v | grep RunJar
# or inspect via port
ss -tulpn | grep -E "9083|10000"
```

---

## 🚀 Connecting to Hive via Beeline

### 1. Dynamic Discovery Mode via ZooKeeper (Production Recommended)
Clients do not need to hardcode a specific node IP. Instead, they provide the ZooKeeper quorum and namespace. ZooKeeper automatically routes the connection to an active instance:
```bash
beeline -u "jdbc:hive2://master:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n huser
```

### 2. Direct Node Connection (Inspection Mode)
To connect directly to a specific HiveServer2 instance:
```bash
# Connect to master HS2
beeline -u "jdbc:hive2://master:10000" -n huser

# Connect to worker1 HS2
beeline -u "jdbc:hive2://worker1:10000" -n huser
```

---

## 💥 Automated Disaster Recovery & Failover Testing

The cluster includes an automated test script (`scripts/test-ha-failover.sh`) that simulates a catastrophic crash of the primary HiveServer2 instance, validates failover routing, and verifies self-healing:

```bash
bash /vagrant/scripts/test-ha-failover.sh
```

### What the Test Executes:
1. **Stage 1 (Pre-Flight Port Audit):** Confirms ports `9083`, `10000`, `10002` on `master` and `worker1`.
2. **Stage 2 (ZooKeeper Registry Check):** Verifies both active znodes in `/hiveserver2`.
3. **Stage 3 (Baseline Query):** Connects via Beeline using the ZooKeeper JDBC discovery URL and executes `SHOW DATABASES;`.
4. **Stage 4 (Simulated Hard Crash):** Sends `kill -9` to `master`'s HiveServer2 PID.
5. **Stage 5 (Failover Validation):** Re-executes the query via the ZooKeeper discovery URL. ZooKeeper detects the missing ephemeral znode and instantly routes the connection to `worker1:10000` with zero client failure (typical response time $\approx 0.32\text{s}$).
6. **Stage 6 (Self-Healing Recovery):** Restarts HiveServer2 on `master`. The restored instance dynamically re-registers with ZooKeeper under a new sequential znode (`...sequence=0000000003`), returning the cluster to a dual-active balanced state.

---

## ⚙️ Core Configuration Reference

### 1. `config/core-site.xml`
| Property | Value | Rationale |
| :--- | :--- | :--- |
| `fs.defaultFS` | `hdfs://master:9000` | Points HDFS root to the active NameNode IPC daemon. |
| `hadoop.proxyuser.huser.hosts` | `*` | Authorizes `huser` to proxy requests from any host. |
| `hadoop.proxyuser.huser.groups` | `*` | Allows `huser` to submit jobs on behalf of any user group. |
| `hadoop.proxyuser.hive.hosts` | `*` | Authorizes HiveServer2 daemon delegation to YARN. |
| `hadoop.proxyuser.hive.groups` | `*` | Authorizes HiveServer2 daemon delegation across all groups. |

### 2. `config/hdfs-site.xml`
| Property | Value | Rationale |
| :--- | :--- | :--- |
| `dfs.replication` | `2` | Matches the cluster's two physical DataNodes. |
| `dfs.namenode.name.dir` | `file:///home/huser/hadoop_data/hdfs/namenode` | Local storage directory for FSImage and EditLogs. |
| `dfs.datanode.data.dir` | `file:///home/huser/hadoop_data/hdfs/datanode` | Local storage path for DataNode block replicas. |
| `dfs.permissions.enabled` | `false` | Streamlines development operations and multi-user access. |

### 3. `config/mapred-site.xml`
| Property | Value | Rationale |
| :--- | :--- | :--- |
| `mapreduce.framework.name` | `yarn` | Routes MapReduce job execution to YARN. |
| `yarn.app.mapreduce.am.resource.mb` | `512` | Restricts ApplicationMaster container RAM to fit worker limits. |
| `mapreduce.map.memory.mb` | `512` | Memory allocated to each Map task container. |
| `mapreduce.reduce.memory.mb` | `512` | Memory allocated to each Reduce task container. |
| `yarn.app.mapreduce.am.env` | `HADOOP_MAPRED_HOME=...` | Passes MapReduce home path into isolated container subshells. |
| `mapreduce.job.user.classpath.first` | `true` | Prevents Protobuf version conflicts (Protobuf 2.5 vs 3.x). |

### 4. `config/yarn-site.xml`
| Property | Value | Rationale |
| :--- | :--- | :--- |
| `yarn.resourcemanager.hostname` | `master` | Cluster-wide ResourceManager endpoint. |
| `yarn.nodemanager.aux-services` | `mapreduce_shuffle` | Enables Shuffle and Sort phase auxiliary service. |
| `yarn.nodemanager.resource.memory-mb` | `1024` | Caps memory allocatable to containers on each worker VM. |
| `yarn.nodemanager.vmem-check-enabled` | `false` | Disables virtual memory checking on virtualized Linux kernels. |

### 5. `config/hive-site.xml`
| Property | Value | Rationale |
| :--- | :--- | :--- |
| `hive.server2.support.dynamic.service.discovery` | `true` | Enables ZooKeeper registration and dynamic client routing. |
| `hive.zookeeper.quorum` | `master:2181` | ZooKeeper ensemble host and port. |
| `hive.server2.zookeeper.namespace` | `hiveserver2` | ZooKeeper znode tree root for HS2 instances. |
| `hive.metastore.uris` | `thrift://master:9083,thrift://worker1:9083` | Comma-delimited list for client-side Metastore failover. |
| `javax.jdo.option.ConnectionDriverName` | `org.mariadb.jdbc.Driver` | MariaDB / MySQL Type 4 JDBC driver class. |
| `hive.server2.enable.doAs` | `false` | Executes queries under the trusted service account. |

---

## 🛡️ Production Hardening & Low-Level Troubleshooting Catalog

An exhaustive reference of critical distributed systems pitfalls, root causes, and solutions:

---

### 1. Parallel Shell (PDSH) Socket Permission Denied
- **Symptom:** Running `start-dfs.sh` or `start-yarn.sh` produces:
  ```text
  pdsh@master: worker1: rcmd: socket: Permission denied
  ```
- **Root Cause:** In Debian/Ubuntu packages, `pdsh` defaults to the legacy BSD `rcmd` protocol, which requires setuid-root permissions on reserved ports (`< 1024`). Non-root user `huser` is forbidden from opening them.
- **Solution:** Export `PDSH_RCMD_TYPE=ssh` in `$HADOOP_HOME/etc/hadoop/hadoop-env.sh` and `/etc/profile.d/hadoop-hive.sh`.

---

### 2. Java 17 InaccessibleObjectException (JEP 403)
- **Symptom:** ResourceManager or NodeManager crashes immediately upon launch:
  ```text
  Caused by: java.lang.reflect.InaccessibleObjectException: Unable to make protected final 
  java.lang.Class java.lang.ClassLoader.defineClass(...) accessible
  ```
- **Root Cause:** Java 17 strictly encapsulates JDK internals. Hadoop's reflection and dependency injection layers require explicit access permissions.
- **Solution:** Inject explicit `--add-opens` flags into `yarn-env.sh`, `hadoop-env.sh`, and `mapred-site.xml`.

---

### 3. YARN InvalidResourceRequestException
- **Symptom:** MapReduce queries fail immediately:
  ```text
  Invalid resource request! Cannot allocate containers as requested resource is greater than maximum allowed allocation.
  ```
- **Root Cause:** Default ApplicationMaster allocation (`1536 MB`) exceeds worker memory limits (`1024 MB`).
- **Solution:** Cap `yarn.app.mapreduce.am.resource.mb`, `mapreduce.map.memory.mb`, and `mapreduce.reduce.memory.mb` to `512` in `mapred-site.xml`.

---

### 4. Container ClassNotFoundException: `MRAppMaster`
- **Symptom:** Job fails inside worker container with:
  ```text
  Error: Could not find or load main class org.apache.hadoop.mapreduce.v2.app.MRAppMaster
  ```
- **Root Cause:** NodeManagers launch containers in clean subshells that do not inherit interactive `~/.bashrc` paths.
- **Solution:** Explicitly set `yarn.app.mapreduce.am.env`, `mapreduce.map.env`, and `mapreduce.reduce.env` in `mapred-site.xml` pointing to `$HADOOP_HOME`.

---

### 5. Hive Kryo Serialization Failure: `Error caching map.xml`
- **Symptom:** `INSERT INTO ...` queries fail during query planning with:
  ```text
  ERROR : Job Submission failed with exception 'java.lang.RuntimeException(Error caching map.xml)'
  ```
- **Root Cause:** Hive's query planner uses Kryo to serialize execution plans. Under Java 17, deep reflective access to `AtomicBoolean.value` is blocked unless explicitly opened.
- **Solution:** Add `--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED` and `--add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED` to `HADOOP_OPTS` in `hive-env.sh`.

---

### 6. Passing JVM Flags: `HADOOP_OPTS` vs `HIVE_OPTS`
- **Symptom:** Starting HiveServer2 with `--add-opens` flags in `HIVE_OPTS` produces:
  ```text
  Error starting HiveServer2 with given arguments: Unrecognized option: --add-opens=...
  ```
- **Root Cause:** In the `hive` runner, `HADOOP_OPTS` are passed to the `java` JVM command line, whereas `HIVE_OPTS` are passed as program arguments to the main class.
- **Solution:** Always export JVM system and reflection flags in `HADOOP_OPTS`.

---

### 7. Hadoop Proxyuser Impersonation Denied
- **Symptom:** HiveServer2 or Beeline fails with:
  ```text
  RemoteException: User: huser is not allowed to impersonate huser
  ```
- **Root Cause:** HiveServer2 proxies client queries to HDFS/YARN. Hadoop forbids proxying unless explicitly authorized in `core-site.xml`.
- **Solution:** Add wildcard proxyuser rules to `core-site.xml` for `huser` and `hive`, and set `hive.server2.enable.doAs=false` in `hive-site.xml`.

---

### 8. HiveServer2 Port 10000 Startup Delay
- **Symptom:** Immediate Beeline connection attempts fail with `Connection refused`.
- **Root Cause:** HiveServer2 performs schema validation, Thrift endpoint binding, and WebUI initialization, taking 15--25 seconds before opening port 10000.
- **Solution:** Use [`scripts/start-hive.sh`](scripts/start-hive.sh), which actively polls port 10000 with a timeout loop before releasing control.

---

### 9. Linux Kernel Swap Allocation & Low-Memory Stability
- **Symptom:** JVM heaps and OS caches cause the Linux Out-Of-Memory (OOM) killer to terminate background daemons.
- **Solution:** Each VM is provisioned with a dedicated 1.5 GB swapfile:
  ```bash
  fallocate -l 1536M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  ```

---

## 🛠️ Cluster Management & Automation Scripts Reference

All scripts are stored in [`scripts/`](scripts/) and mounted at `/vagrant/scripts/` inside every VM:

| Script | Location | Invocation | Purpose |
| :--- | :--- | :--- | :--- |
| **`start-cluster.sh`** | [`scripts/start-cluster.sh`](scripts/start-cluster.sh) | `bash /vagrant/scripts/start-cluster.sh` | Orchestrates end-to-end cluster startup (HDFS, YARN, and Hive services). |
| **`stop-cluster.sh`** | [`scripts/stop-cluster.sh`](scripts/stop-cluster.sh) | `bash /vagrant/scripts/stop-cluster.sh` | Gracefully shuts down all cluster services (Hive, YARN, and HDFS). |
| **`setup-ha-hive.sh`** | [`scripts/setup-ha-hive.sh`](scripts/setup-ha-hive.sh) | `bash /vagrant/scripts/setup-ha-hive.sh` | Deploys ZooKeeper, binds MariaDB to `0.0.0.0`, provisions Hive on `worker1`, and launches active-active HA services. |
| **`test-ha-failover.sh`** | [`scripts/test-ha-failover.sh`](scripts/test-ha-failover.sh) | `bash /vagrant/scripts/test-ha-failover.sh` | Executes 6-stage crash simulation, ZooKeeper discovery failover validation, and self-healing verification. |
| **`start-hive.sh`** | [`scripts/start-hive.sh`](scripts/start-hive.sh) | `bash /vagrant/scripts/start-hive.sh` | Launches Hive Metastore & HiveServer2 with automated port polling (`9083`, `10000`). |
| **`stop-hive.sh`** | [`scripts/stop-hive.sh`](scripts/stop-hive.sh) | `bash /vagrant/scripts/stop-hive.sh` | Gracefully terminates all running Hive and Metastore processes. |
| **`verify-cluster.sh`** | [`scripts/verify-cluster.sh`](scripts/verify-cluster.sh) | `bash /vagrant/scripts/verify-cluster.sh` | Automated 5-stage health check (JPS, HDFS live nodes, YARN active nodes, Pi MapReduce benchmark, Beeline query). |
| **`test-hive.sql`** | [`scripts/test-hive.sql`](scripts/test-hive.sql) | `beeline -u ... -f /vagrant/scripts/test-hive.sql` | Verification SQL script for schema creation, table creation, insertion, and querying. |
| **`setup-common.sh`** | [`scripts/setup-common.sh`](scripts/setup-common.sh) | *Provisioning* | Installs base packages, OpenJDK 17, `/etc/hosts`, and generates dynamic `ed25519` SSH keys. |
| **`setup-hadoop.sh`** | [`scripts/setup-hadoop.sh`](scripts/setup-hadoop.sh) | *Provisioning* | Downloads and unpacks Hadoop 3.3.6 binaries and configures storage directories. |
| **`setup-master.sh`** | [`scripts/setup-master.sh`](scripts/setup-master.sh) | *Provisioning* | Installs MariaDB, initializes metastore database, and deploys Hive 4.0.1 on `master`. |
| **`setup-worker.sh`** | [`scripts/setup-worker.sh`](scripts/setup-worker.sh) | *Provisioning* | Initializes worker nodes and synchronizes cluster configurations. |
| **`fix-path.sh`** | [`scripts/fix-path.sh`](scripts/fix-path.sh) | `source /vagrant/scripts/fix-path.sh` | Ensures interactive shells load all Hadoop and Hive binaries on PATH. |

---

## 🖥️ Live Web Monitoring Dashboards

Directly accessible from your host browser via the private network (`192.168.56.0/24`):

| Service / Daemon | Node | Direct URL | Port | Function |
| :--- | :--- | :--- | :--- | :--- |
| **HDFS NameNode WebUI** | `master` | [http://192.168.56.10:9870](http://192.168.56.10:9870) | `9870` | HDFS filesystem health, block pool statistics, browse filesystem |
| **YARN ResourceManager WebUI** | `master` | [http://192.168.56.10:8088](http://192.168.56.10:8088) | `8088` | Active applications, node managers, scheduler queue metrics |
| **HiveServer2 WebUI (Primary)** | `master` | [http://192.168.56.10:10002](http://192.168.56.10:10002) | `10002` | Master HS2 query execution history, active sessions, metrics |
| **HiveServer2 WebUI (Secondary HA)** | `worker1` | [http://192.168.56.11:10002](http://192.168.56.11:10002) | `10002` | Worker1 HS2 failover query execution history and active sessions |
| **DataNode 1 WebUI** | `worker1` | [http://192.168.56.11:9864](http://192.168.56.11:9864) | `9864` | Worker1 DataNode block volume and I/O metrics |
| **DataNode 2 WebUI** | `worker2` | [http://192.168.56.12:9864](http://192.168.56.12:9864) | `9864` | Worker2 DataNode block volume and I/O metrics |

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
