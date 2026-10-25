# Apache Hadoop 3.3.6 & Apache Hive 4.0.1 Multi-Node Cluster (IaC with Vagrant)

[![Hadoop Version](https://img.shields.io/badge/Apache%20Hadoop-3.3.6-E65225.svg)](https://hadoop.apache.org/)
[![Hive Version](https://img.shields.io/badge/Apache%20Hive-4.0.1-FDEE21.svg?logo=apachehive&logoColor=black)](https://hive.apache.org/)
[![Database](https://img.shields.io/badge/Metastore-MariaDB%2010.11%20%2F%20MySQL-003545.svg?logo=mariadb)](https://mariadb.org/)
[![Java Version](https://img.shields.io/badge/Java-OpenJDK%2017%20LTS-ED8B00.svg?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.x-1563FF.svg?logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.x-246BB3.svg?logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![OS](https://img.shields.io/badge/OS-Debian%2012%20Bookworm-D70A53.svg?logo=debian&logoColor=white)](https://www.debian.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An enterprise-grade, fully automated 3-node **Apache Hadoop 3.3.6** distributed storage/compute cluster integrated with **Apache Hive 4.0.1** and a **MariaDB 10.11 relational metastore backend**. Deployed as Infrastructure as Code (IaC) using **Vagrant** and **Oracle VirtualBox**.

Engineered for modern production environments running on **OpenJDK 17 LTS (HotSpot)** with comprehensive JEP 403 reflection access flags, custom drive path redirection (`E:\`) to avoid host disk exhaustion, resilient parallel shell execution (`pdsh`), automated daemon supervision, and low-level JVM classpath resolution.

---

## 🌐 Cluster Architecture & Topology

The cluster consists of three Debian 12 Bookworm 64-bit virtual machines interconnected via a dedicated, non-routed Host-Only private network (`192.168.56.0/24`):

```
                       +--------------------------------------------------+
                       |              master (192.168.56.10)              |
                       |  - HDFS: NameNode (Port 9000, WebUI 9870)        |
                       |  - HDFS: SecondaryNameNode (Port 9868)           |
                       |  - YARN: ResourceManager (Port 8032, WebUI 8088) |
                       |  - RDBMS: MariaDB / MySQL Metastore (Port 3306)  |
                       |  - Hive: Metastore Thrift Service (Port 9083)    |
                       |  - Hive: HiveServer2 JDBC/ODBC (Port 10000)      |
                       |  - HiveServer2 WebUI (Port 10002)                |
                       +------------------------+-------------------------+
                                                |
                       +------------------------+-------------------------+
                       |                                                  |
        +--------------+--------------+                    +--------------+--------------+
        |    worker1 (192.168.56.11)  |                    |    worker2 (192.168.56.12)  |
        | - HDFS: DataNode 1          |                    | - HDFS: DataNode 2          |
        | - YARN: NodeManager 1       |                    | - YARN: NodeManager 2       |
        +-----------------------------+                    +-----------------------------+
```

### Node Specifications & Resource Allocations

| Node | Hostname | IP Address | Roles & Daemons | vCPUs | RAM | Disk / Storage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Master** | `master` | `192.168.56.10` | NameNode, SecondaryNameNode, ResourceManager, MariaDB, Hive Metastore, HiveServer2 | 2 | 2048 MB | Root (20GB) + Shared `/vagrant` |
| **Worker 1** | `worker1` | `192.168.56.11` | DataNode 1, NodeManager 1 | 1 | 1280 MB | Root (20GB) + Shared `/vagrant` |
| **Worker 2** | `worker2` | `192.168.56.12` | DataNode 2, NodeManager 2 | 1 | 1280 MB | Root (20GB) + Shared `/vagrant` |

---

## 📁 Repository Structure

```
Hadoop-Cluster/
├── config/                          # Centralized Hadoop & Hive XML configurations
│   ├── core-site.xml                # HDFS defaultFS, IPC timeouts & proxyuser authorization
│   ├── hdfs-site.xml                # Replication factor (2), NameNode/DataNode data paths
│   ├── hive-site.xml                # HiveServer2, MariaDB JDBC connection & warehouse path
│   ├── mapred-site.xml              # MapReduce framework, memory allocation & Java 17 JVM flags
│   └── yarn-site.xml                # ResourceManager, NodeManager & auxiliary shuffle services
├── docs/                            # Guides, diagrams & visual audit references
│   ├── Apache Hive Setup.pdf        # Architecture setup reference guide
│   ├── SCREENSHOT_GUIDE.md          # Verification and execution screenshot reference
│   └── screenshots/                 # High-resolution cluster validation captures
├── exercise1_la_crime/              # Analytical Workload 1: LA Crime Analysis (1M+ rows)
│   ├── 01_load_crime.sh             # HDFS staging & external table ingestion script
│   ├── 02_analyze_crime.sql         # 8 analytical SQL queries
│   ├── 02_run_analysis.sh           # Automated batch execution runner
│   ├── analysis_results.txt         # Query execution logs and output tables
│   ├── images/                      # Query execution screenshot evidence
│   ├── report_exercise1_la_crime.pdf# Technical execution report (5 pages)
│   └── report_exercise1_la_crime.tex# LaTeX source
├── exercise2_divvy_bikes/           # Analytical Workload 2: Divvy Bikes & Partitioning Benchmark
│   ├── 01_load_divvy.sh             # HDFS ingestion pipeline
│   ├── 02_clean_and_orc.sh          # ORC Snappy cleaning table conversion
│   ├── 03_analyze_divvy.sql         # 8 business metric queries
│   ├── 04_partition_and_benchmark.sql # Dynamic partitioning & 133.8x I/O speedup benchmark
│   ├── divvy_execution_log.txt      # Execution log
│   ├── images/                      # Benchmark execution screenshot evidence
│   ├── report_exercise2_divvy_bikes.pdf # Technical execution report (7 pages)
│   ├── report_exercise2_divvy_bikes.tex # LaTeX source
│   └── run_all_exercise2.sh         # Master automation script
├── hadoop_hive_agent_skills/        # AI Agent skill definitions and playbooks
├── report/                          # Technical architecture report
│   └── hadoop_hive_cluster_report.tex # Complete cluster deployment architecture in LaTeX
├── scripts/                         # Cluster lifecycle and automation shell scripts
│   ├── setup-common.sh              # Base Debian 12 packages, OpenJDK 17 & SSH keys
│   ├── setup-hadoop.sh              # Hadoop 3.3.6 installation & environment setup
│   ├── setup-master.sh              # MariaDB metastore provisioning & Hive 4.0.1 installation
│   ├── setup-worker.sh              # Worker NodeManager/DataNode initialization
│   ├── start-hive.sh                # Metastore & HiveServer2 launcher with port polling
│   ├── stop-hive.sh                 # Graceful Hive process shutdown script
│   ├── test-hive.sql                # Verification SQL script
│   └── verify-cluster.sh            # 5-stage automated cluster health check
├── .gitignore                       # Git exclusion rules (large datasets, temp files)
├── LICENSE                          # MIT License
├── README.md                        # Master cluster documentation
└── Vagrantfile                      # 3-Node VirtualBox IaC definition
```

---

## ⚡ Quick Start Guide (Automated Deployment)

### 1. Host Machine Prerequisites
- **Git**, **Oracle VirtualBox 7.x**, and **Vagrant 2.3+**.
- *(Recommended)* If host drive `C:\` has limited space, redirect Vagrant box storage and VirtualBox machine folders to drive `E:\`:
  ```powershell
  # Run in PowerShell as Administrator
  setx VAGRANT_HOME "E:\.vagrant.d"
  $env:VAGRANT_HOME="E:\.vagrant.d"
  VBoxManage setproperty machinefolder "E:\Virtual Machines\IAC VMS"
  ```

### 2. Clone Repository & Boot Cluster
```powershell
git clone https://github.com/MedSalimGh/Hadoop-Cluster.git
cd Hadoop-Cluster
vagrant up
```
*Vagrant will provision all 3 virtual machines, install OpenJDK 17, distribute passwordless SSH keys, configure hostnames, install Hadoop 3.3.6, initialize MariaDB, and deploy Apache Hive 4.0.1.*

### 3. Access Master Node
```powershell
vagrant ssh master
```

### 4. Start Distributed Services (as `huser`)
```bash
su - huser

# Format NameNode (only required on very first initial boot)
hdfs namenode -format -force

# Start HDFS storage daemons across master and workers
start-dfs.sh

# Start YARN compute daemons across master and workers
start-yarn.sh

# Start Hive Metastore (port 9083) and HiveServer2 (port 10000)
bash /vagrant/scripts/start-hive.sh
```

### 5. Run Cluster Verification Suite
Execute the automated 5-stage health check:
```bash
bash /vagrant/scripts/verify-cluster.sh
```
*Checks JPS daemons, HDFS live datanodes, YARN active nodes, runs a MapReduce Pi calculation job, and executes a full Hive DDL/DML query via Beeline.*

---

## 🛠️ Step-by-Step Installation & Configuration Deep Dive

This section details the low-level manual configuration implemented across the cluster.

### Step 0: MariaDB Metastore Backend Setup (`master`)
Hive requires an external relational database for metadata persistence. MariaDB 10.11 is configured on `master`:

```bash
# Install MariaDB
sudo apt-get update && sudo apt-get install -y default-mysql-server
sudo systemctl enable --now mariadb

# Initialize metastore schema database and user credentials
sudo mysql -u root << 'EOF'
CREATE DATABASE IF NOT EXISTS metastore_db;
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hive';
CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'%';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'localhost';
FLUSH PRIVILEGES;
EOF

# Verify connectivity
mysql -u hive -phive -e "SHOW DATABASES;"
```

### Step 1 & 2: Apache Hive 4.0.1 Installation
```bash
su - huser
cd /home/huser

# Download and unpack Hive binaries
wget https://archive.apache.org/dist/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz
tar -xvf apache-hive-4.0.1-bin.tar.gz
```

### Step 3: Environment Profile Configuration (`~/.bashrc`)
```bash
cat << 'EOF' >> ~/.bashrc
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HIVE_HOME/bin
EOF

source ~/.bashrc
```

### Step 4: Configure `hive-env.sh` with Java 17 JEP 403 JVM Flags
Modern OpenJDK 17 strictly enforces module boundaries. The JVM flags below open essential packages for Hive and Kryo serialization:

```bash
cp $HIVE_HOME/conf/hive-env.sh.template $HIVE_HOME/conf/hive-env.sh

cat << 'EOF' >> $HIVE_HOME/conf/hive-env.sh
export HADOOP_HOME=/home/huser/hadoop-3.3.6

# Java 17 reflection access flags for Hive and Kryo serialization
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
EOF
```

### Step 5: Configure `hive-site.xml`
Create `$HIVE_HOME/conf/hive-site.xml`:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <!-- Metastore JDBC connection URL -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost/metastore_db?createDatabaseIfNotExist=true&amp;allowPublicKeyRetrieval=true</value>
    </property>

    <!-- Metastore database credentials -->
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive</value>
    </property>

    <!-- MariaDB / MySQL JDBC Driver class -->
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.mariadb.jdbc.Driver</value>
    </property>

    <!-- Local scratch directory for temporary Hive artifacts -->
    <property>
        <name>hive.exec.local.scratchdir</name>
        <value>/tmp/hive</value>
    </property>

    <!-- Directory for downloaded resources -->
    <property>
        <name>hive.downloaded.resources.dir</name>
        <value>/tmp/hive_resources</value>
    </property>

    <!-- Impersonation setting: set to false so queries execute as hive service -->
    <property>
        <name>hive.server2.enable.doAs</name>
        <value>false</value>
    </property>
</configuration>
```

### Step 6 & 7: Prepare HDFS Directories & Open Permissions
```bash
# Create Hive warehouse and scratch locations in HDFS
hadoop fs -mkdir -p /user/hive/warehouse
hadoop fs -mkdir -p /tmp/hive

# Grant full read/write/execute permissions
hadoop fs -chmod -R 777 /user/hive/warehouse
hadoop fs -chmod -R 777 /tmp/hive
hadoop fs -chmod 777 /tmp
```

### Step 8 & 9: Install & Link MariaDB JDBC Connector
```bash
sudo apt-get install -y libmariadb-java
cp /usr/share/java/mariadb-java-client.jar $HIVE_HOME/lib/mysql-connector-java.jar
```

### Step 10: Initialize Metastore Relational Schema
```bash
schematool -initSchema -dbType mysql
```
*Expected confirmation:* `schemaTool completed` and `Initialization script completed`.

### Step 11: Launch Daemons
```bash
# Automated launcher with port verification
bash /vagrant/scripts/start-hive.sh
```

### Step 12 & 13: Beeline JDBC Connection & SQL Execution
Connect to HiveServer2 on port 10000:
```bash
beeline -u "jdbc:hive2://localhost:10000" -n huser
```
Run validation queries:
```sql
SHOW DATABASES;
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE cluster_nodes (id INT, node_name STRING, role STRING);
INSERT INTO cluster_nodes VALUES (1, 'master', 'NameNode'), (2, 'worker1', 'DataNode');
SELECT * FROM cluster_nodes;
```

---

## ⚙️ Core Distributed Configuration Reference

### 1. `core-site.xml`
| Parameter | Value | Technical Rationale |
| :--- | :--- | :--- |
| `fs.defaultFS` | `hdfs://master:9000` | Points HDFS root to active NameNode IPC daemon. |
| `hadoop.proxyuser.huser.hosts` | `*` | Authorizes `huser` to proxy requests from any host. |
| `hadoop.proxyuser.huser.groups` | `*` | Allows `huser` to submit jobs on behalf of any group. |
| `hadoop.proxyuser.hive.hosts` | `*` | Enables HiveServer2 daemon delegation to YARN. |

### 2. `hdfs-site.xml`
| Parameter | Value | Technical Rationale |
| :--- | :--- | :--- |
| `dfs.replication` | `2` | Matches the cluster's two physical DataNodes. |
| `dfs.namenode.name.dir` | `file:///home/huser/hadoop_data/hdfs/namenode` | Dedicated local storage directory for FSImage and EditLogs. |
| `dfs.datanode.data.dir` | `file:///home/huser/hadoop_data/hdfs/datanode` | Dedicated local storage path for block replicas. |
| `dfs.permissions.enabled` | `false` | Streamlines development operations across nodes. |

### 3. `mapred-site.xml`
| Parameter | Value | Technical Rationale |
| :--- | :--- | :--- |
| `mapreduce.framework.name` | `yarn` | Routes MapReduce job orchestration to YARN. |
| `yarn.app.mapreduce.am.resource.mb` | `512` | Restricts AM container RAM to fit within 1280 MB worker limits. |
| `mapreduce.map.memory.mb` | `512` | Prevents Container-Killed-by-YARN failures. |
| `mapreduce.reduce.memory.mb` | `512` | Memory allocated to reduce tasks. |
| `yarn.app.mapreduce.am.env` | `HADOOP_MAPRED_HOME=/home/huser/hadoop-3.3.6` | Injects MapReduce JAR path into isolated container subshells. |
| `mapreduce.job.user.classpath.first` | `true` | Prevents Protobuf 2.5 vs 3.x shaded dependency conflicts. |
| `yarn.app.mapreduce.am.command-opts` | `--add-opens=java.base/...=ALL-UNNAMED` | Java 17 reflection access flags for MRAppMaster. |

### 4. `yarn-site.xml`
| Parameter | Value | Technical Rationale |
| :--- | :--- | :--- |
| `yarn.resourcemanager.hostname` | `master` | Cluster-wide ResourceManager endpoint. |
| `yarn.nodemanager.aux-services` | `mapreduce_shuffle` | Enables Shuffle and Sort phase auxiliary service. |
| `yarn.nodemanager.resource.memory-mb` | `1024` | Caps memory allocatable to containers on each worker. |
| `yarn.nodemanager.vmem-check-enabled` | `false` | Bypasses virtual memory check threshold on virtualized kernels. |

---

## 🛡️ Production Hardening & Low-Level Solutions

### 1. Java 17 JEP 403 Strong Encapsulation Workaround
In OpenJDK 17, deep reflective access across package boundaries is blocked by default (`java.lang.reflect.InaccessibleObjectException`). Hadoop and Hive components (specifically Google Guice, Kryo, and Java serialization) require explicit access permissions.

The cluster solves this uniformly across **interactive clients**, **background daemons**, and **YARN child containers**:
- **Hadoop daemons**: Configured via `HADOOP_OPTS` in `hadoop-env.sh` and `yarn-env.sh`.
- **Hive daemons**: Configured via `HADOOP_OPTS` in `hive-env.sh`.
- **YARN Map/Reduce containers**: Injected into `yarn.app.mapreduce.am.command-opts`, `mapreduce.map.java.opts`, and `mapreduce.reduce.java.opts` in `mapred-site.xml`.

### 2. Protobuf Dependency Version Collision
Hadoop 3.3.6 ships with Google Protocol Buffers 2.5.0 in its core libraries. Hive 4.0.1 embeds modern dependencies that require Protobuf 3.x. When MapReduce jobs run, having Hadoop libraries first in the classpath causes `NoSuchMethodError` or `IncompatibleClassChangeError`.

**Solution**:
```xml
<property>
    <name>mapreduce.job.user.classpath.first</name>
    <value>true</value>
</property>
<property>
    <name>yarn.app.mapreduce.am.admin.user.class.paths.first</name>
    <value>true</value>
</property>
```

### 3. Linux Kernel Swap & Low-Memory Stability
On constrained VMs (1280 MB - 2048 MB RAM), JVM heaps and OS page caches can trigger Linux Out-Of-Memory (OOM) killer terminations.
Each VM is configured during provisioning with a **1.5 GB swapfile**:
```bash
fallocate -l 1536M /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## ⚠️ 11 Critical Problems to Avoid (Troubleshooting Catalog)

Below is an exhaustive catalog of every critical issue encountered during deployment, its technical root cause, and the preventive fix:

---

### 1. Parallel Shell (PDSH) Socket Permission Denied
- **Symptom:** Running `start-dfs.sh` or `start-yarn.sh` produces:
  ```text
  pdsh@master: worker1: rcmd: socket: Permission denied
  pdsh@master: worker2: rcmd: socket: Permission denied
  ```
- **Root Cause:** In Debian/Ubuntu packages, `pdsh` defaults to the legacy BSD `rcmd` protocol, which requires setuid-root permissions on reserved sockets (`port < 1024`). Non-root user `huser` is forbidden from opening them.
- **Problem to Avoid:** Never run `start-dfs.sh` as root or execute `chmod u+s` on pdsh binaries.
- **Solution:** Force `pdsh` to use SSH by exporting `PDSH_RCMD_TYPE=ssh` in `$HADOOP_HOME/etc/hadoop/hadoop-env.sh` and `~/.bashrc`:
  ```bash
  export PDSH_RCMD_TYPE=ssh
  ```

---

### 2. Java 17 InaccessibleObjectException on YARN Startup (JEP 403)
- **Symptom:** ResourceManager or NodeManager crashes immediately upon launch:
  ```text
  Caused by: java.lang.reflect.InaccessibleObjectException: Unable to make protected final 
  java.lang.Class java.lang.ClassLoader.defineClass(...) accessible: 
  module java.base does not "opens java.lang" to unnamed module
  ```
- **Root Cause:** Java 17 enforces JEP 403 (Strong Encapsulation of JDK Internals). Hadoop's Guice and reflection layers cannot access unexported JDK internals.
- **Problem to Avoid:** Do not downgrade your operating system or switch back to deprecated Java 8 runtimes.
- **Solution:** Inject explicit `--add-opens` flags into `$HADOOP_HOME/etc/hadoop/yarn-env.sh` and `hadoop-env.sh`:
  ```bash
  export YARN_RESOURCEMANAGER_OPTS="$YARN_RESOURCEMANAGER_OPTS \
    --add-opens=java.base/java.lang=ALL-UNNAMED \
    --add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
    --add-opens=java.base/java.io=ALL-UNNAMED \
    --add-opens=java.base/java.util=ALL-UNNAMED"
  ```

---

### 3. YARN InvalidResourceRequestException (Container Exceeds Node Limits)
- **Symptom:** MapReduce queries (`INSERT INTO ...`) fail immediately:
  ```text
  Invalid resource request! Cannot allocate containers as requested resource is greater than maximum allowed allocation.
  Requested resource=<memory:1536, vCores:1>, maximum allowed allocation=<memory:1024, vCores:4>
  ```
- **Root Cause:** Hadoop defaults to 1536 MB for the ApplicationMaster (`yarn.app.mapreduce.am.resource.mb`), which exceeds the 1024 MB container limit configured on worker VMs.
- **Problem to Avoid:** Do not allocate excessive memory that host hardware cannot support.
- **Solution:** Cap container allocations to 512 MB in `mapred-site.xml`:
  ```xml
  <property>
      <name>yarn.app.mapreduce.am.resource.mb</name>
      <value>512</value>
  </property>
  <property>
      <name>mapreduce.map.memory.mb</name>
      <value>512</value>
  </property>
  <property>
      <name>mapreduce.reduce.memory.mb</name>
      <value>512</value>
  </property>
  ```

---

### 4. Container ClassNotFoundException: `MRAppMaster` on Worker Nodes
- **Symptom:** YARN allocates a container on `worker1` or `worker2`, but the job crashes during container initialization:
  ```text
  Error: Could not find or load main class org.apache.hadoop.mapreduce.v2.app.MRAppMaster
  ```
- **Root Cause:** YARN NodeManagers launch containers in clean subshells that do not inherit variables from interactive `~/.bashrc`. Without `$HADOOP_MAPRED_HOME`, the container cannot locate MapReduce JARs.
- **Problem to Avoid:** Relying on interactive shell profiles (`~/.bashrc`) for daemon container execution.
- **Solution:** Pass the environment variables explicitly in `mapred-site.xml`:
  ```xml
  <property>
      <name>yarn.app.mapreduce.am.env</name>
      <value>HADOOP_MAPRED_HOME=/home/huser/hadoop-3.3.6</value>
  </property>
  <property>
      <name>mapreduce.map.env</name>
      <value>HADOOP_MAPRED_HOME=/home/huser/hadoop-3.3.6</value>
  </property>
  <property>
      <name>mapreduce.reduce.env</name>
      <value>HADOOP_MAPRED_HOME=/home/huser/hadoop-3.3.6</value>
  </property>
  ```

---

### 5. Hive Kryo Serialization Failure: `Error caching map.xml` (Java 17)
- **Symptom:** Executing `INSERT INTO ...` fails during query plan generation:
  ```text
  ERROR : Job Submission failed with exception 'java.lang.RuntimeException(Error caching map.xml)'
  Caused by: org.apache.hive.com.esotericsoftware.kryo.KryoException: java.lang.reflect.InaccessibleObjectException: 
  Unable to make field private volatile int java.util.concurrent.atomic.AtomicBoolean.value accessible: 
  module java.base does not "opens java.util.concurrent.atomic" to unnamed module
  ```
- **Root Cause:** Hive's query planner uses Kryo to serialize `MapWork` execution plans. Under Java 17, deep reflective access to `AtomicBoolean.value` is blocked unless opened.
- **Problem to Avoid:** Missing JVM reflection arguments in the Hive client and MapReduce container runners.
- **Solution:** Add `--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED` and `--add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED` to `HADOOP_OPTS` in `hive-env.sh` and container options in `mapred-site.xml`.

---

### 6. Passing JVM Flags: `HADOOP_OPTS` vs `HIVE_OPTS`
- **Symptom:** Starting HiveServer2 with `--add-opens` flags in `HIVE_OPTS` produces:
  ```text
  Error starting HiveServer2 with given arguments:
  Unrecognized option: --add-opens=java.base/java.lang=ALL-UNNAMED
  ```
- **Root Cause:** In the `bin/hive` runner script, `HADOOP_OPTS` are passed to the `java` JVM command line (`java $HADOOP_OPTS ...`), whereas `HIVE_OPTS` are passed as **arguments to the Java main class** (`... HiveServer2 $HIVE_OPTS`).
- **Problem to Avoid:** Placing JVM flags like `-Xmx`, `-D...`, or `--add-opens` into `HIVE_OPTS`.
- **Solution:** Always export JVM flags in `HADOOP_OPTS`.

---

### 7. Hadoop Proxyuser Impersonation Denied
- **Symptom:** HiveServer2 or Beeline fails with:
  ```text
  RemoteException: User: huser is not allowed to impersonate huser (or anonymous)
  ```
- **Root Cause:** HiveServer2 proxies client queries to HDFS/YARN. Hadoop forbids proxying unless explicitly authorized in `core-site.xml`.
- **Problem to Avoid:** Forgetting proxyuser wildcard rules on the NameNode and ResourceManager.
- **Solution:** Add proxyuser rules to `core-site.xml`:
  ```xml
  <property>
      <name>hadoop.proxyuser.huser.hosts</name>
      <value>*</value>
  </property>
  <property>
      <name>hadoop.proxyuser.huser.groups</name>
      <value>*</value>
  </property>
  <property>
      <name>hadoop.proxyuser.hive.hosts</name>
      <value>*</value>
  </property>
  <property>
      <name>hadoop.proxyuser.hive.groups</name>
      <value>*</value>
  </property>
  ```
  Set `hive.server2.enable.doAs=false` in `hive-site.xml` to execute queries under the trusted daemon service account.

---

### 8. HiveServer2 Startup Delay & Port 10000 Connection Refused
- **Symptom:** Launching Beeline immediately after `nohup hive --service hiveserver2 &` outputs:
  ```text
  Error: Could not open client transport with JDBC Uri: jdbc:hive2://localhost:10000: 
  java.net.ConnectException: Connection refused
  ```
- **Root Cause:** HiveServer2 initializes schema validation, Thrift endpoints, and WebUI services, taking **15 to 25 seconds** to bind to port 10000.
- **Problem to Avoid:** Connecting Beeline immediately without polling port availability.
- **Solution:** Use [`scripts/start-hive.sh`](scripts/start-hive.sh) which automatically loops until port 10000 responds:
  ```bash
  ss -tulpn | grep 10000
  ```

---

### 9. MariaDB / MySQL Driver Class & SSL Handshake
- **Symptom:** Metastore initialization fails with `ClassNotFoundException: com.mysql.jdbc.Driver` or `SSLHandshakeException`.
- **Root Cause:** Newer connectors use `org.mariadb.jdbc.Driver`, and modern MariaDB installations enforce SSL handshakes unless disabled or allowed public key retrieval.
- **Problem to Avoid:** Using legacy driver class names or omitting JDBC parameter flags.
- **Solution:** Use `org.mariadb.jdbc.Driver` and append `createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true` to the JDBC connection string in `hive-site.xml`.

---

### 10. HDFS Scratch and Warehouse Permissions (`Permission Denied`)
- **Symptom:** Table creation fails with `Permission denied: user=huser, access=WRITE, inode="/user/hive/warehouse"`.
- **Root Cause:** HDFS directories inherit restrictive umask permissions from their creator.
- **Problem to Avoid:** Omitting recursive open permissions before initializing Hive.
- **Solution:** Execute recursive permission grants on HDFS:
  ```bash
  hadoop fs -mkdir -p /user/hive/warehouse /tmp/hive
  hadoop fs -chmod -R 777 /user/hive/warehouse /tmp/hive /tmp
  ```

---

### 11. Host SSD Exhaustion (Drive Redirection to `E:\`)
- **Symptom:** Host drive `C:\` runs out of disk space during VM provisioning.
- **Root Cause:** Vagrant and VirtualBox default to caching boxes and creating virtual disks (`.vdi`) in `C:\Users\<user>\`. A 3-node cluster can require 20--30 GB of storage.
- **Problem to Avoid:** Letting Vagrant/VirtualBox allocate images to a constrained `C:\` partition.
- **Solution:** Configure environment redirection to a secondary drive (e.g. `E:\`):
  ```powershell
  setx VAGRANT_HOME "E:\.vagrant.d"
  $env:VAGRANT_HOME="E:\.vagrant.d"
  VBoxManage setproperty machinefolder "E:\Virtual Machines\IAC VMS"
  ```

---

## 🛠️ Cluster Management & Automation Scripts

All scripts are located in [`scripts/`](scripts/) and mounted at `/vagrant/scripts/` inside each VM:

| Script | Path | Command | Description |
| :--- | :--- | :--- | :--- |
| `start-hive.sh` | [`scripts/start-hive.sh`](scripts/start-hive.sh) | `bash /vagrant/scripts/start-hive.sh` | Starts Hive Metastore & HiveServer2 with automated port readiness polling (9083, 10000). |
| `stop-hive.sh` | [`scripts/stop-hive.sh`](scripts/stop-hive.sh) | `bash /vagrant/scripts/stop-hive.sh` | Gracefully terminates all running Hive background processes. |
| `verify-cluster.sh` | [`scripts/verify-cluster.sh`](scripts/verify-cluster.sh) | `bash /vagrant/scripts/verify-cluster.sh` | Automated 5-stage health check (JPS, HDFS live nodes, YARN nodes, Pi calculation, Beeline SQL). |
| `test-hive.sql` | [`scripts/test-hive.sql`](scripts/test-hive.sql) | `beeline -u jdbc:hive2://localhost:10000 -n huser -f /vagrant/scripts/test-hive.sql` | Verification SQL script for schema creation, table creation, insertion, and querying. |
| `setup-common.sh` | [`scripts/setup-common.sh`](scripts/setup-common.sh) | Provisioning | Installs base packages, OpenJDK 17, hosts file, and `huser` SSH credentials across all nodes. |
| `setup-hadoop.sh` | [`scripts/setup-hadoop.sh`](scripts/setup-hadoop.sh) | Provisioning | Downloads and configures Hadoop 3.3.6 binaries and environment paths. |
| `setup-master.sh` | [`scripts/setup-master.sh`](scripts/setup-master.sh) | Provisioning | Configures MariaDB, initializes schema, and deploys Apache Hive 4.0.1 on `master`. |

---

## 🖥️ Live Web Monitoring Dashboards

Directly accessible from your host machine's browser via the private network:

| Service / Daemon | Node | Direct URL | Port | Default Credentials |
| :--- | :--- | :--- | :--- | :--- |
| **HDFS NameNode WebUI** | `master` | [http://192.168.56.10:9870](http://192.168.56.10:9870) | `9870` | *None* |
| **YARN ResourceManager WebUI** | `master` | [http://192.168.56.10:8088](http://192.168.56.10:8088) | `8088` | *None* |
| **HiveServer2 WebUI** | `master` | [http://192.168.56.10:10002](http://192.168.56.10:10002) | `10002` | *None* |
| **DataNode 1 WebUI** | `worker1` | [http://192.168.56.11:9864](http://192.168.56.11:9864) | `9864` | *None* |
| **DataNode 2 WebUI** | `worker2` | [http://192.168.56.12:9864](http://192.168.56.12:9864) | `9864` | *None* |

---

## 📄 Technical Architecture Specification
A full LaTeX technical specification detailing the distributed systems architecture, network layout, memory models, and command reference is available at:
[`report/hadoop_hive_cluster_report.tex`](report/hadoop_hive_cluster_report.tex)

---

## 📜 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
