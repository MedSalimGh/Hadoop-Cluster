# Apache Hadoop 3.3.6 & Apache Hive 4.0.1 Multi-Node Cluster

[![Hadoop Version](https://img.shields.io/badge/Apache%20Hadoop-3.3.6-E65225.svg?logo=apache&logoColor=white)](https://hadoop.apache.org/)
[![Hive Version](https://img.shields.io/badge/Apache%20Hive-4.0.1-FDEE21.svg?logo=apachehive&logoColor=black)](https://hive.apache.org/)
[![Metastore](https://img.shields.io/badge/Metastore-MariaDB%20%2F%20MySQL-003545.svg?logo=mariadb&logoColor=white)](https://mariadb.org/)
[![Runtime](https://img.shields.io/badge/Java-OpenJDK%2017%20LTS-ED8B00.svg?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![IaC](https://img.shields.io/badge/Vagrant-2.x-1563FF.svg?logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![Virtualization](https://img.shields.io/badge/VirtualBox-7.x-246BB3.svg?logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![OS](https://img.shields.io/badge/OS-Debian%2012%20(Bookworm)-A80030.svg?logo=debian&logoColor=white)](https://www.debian.org/)

An enterprise-grade, fully automated 3-node **Apache Hadoop 3.3.6** and **Apache Hive 4.0.1** distributed cluster provisioned as Infrastructure-as-Code (IaC) using **Vagrant** and **Oracle VirtualBox**. 

Engineered with an independent **MariaDB-backed relational metastore**, comprehensive **Java 17 LTS reflection patches (JEP 403)**, optimized classpath isolation, automated system services, and verified on real-world datasets exceeding **1.0M+ records**.

---

## 📑 Table of Contents
- [Cluster Architecture \& Topology](#-cluster-architecture--topology)
- [Repository Structure](#-repository-structure)
- [Quick Start Guide](#-quick-start-guide)
- [Web Interfaces \& Endpoints](#-web-interfaces--endpoints)
- [Analytical Workloads](#-analytical-workloads)
  - [Workload 1: Large-Scale Crime Analytics (1.0M+ Records)](#workload-1-large-scale-crime-analytics-10m-records)
  - [Workload 2: Mobility Data Pipeline \& Partitioning Benchmark (~800K Records)](#workload-2-mobility-data-pipeline--partitioning-benchmark-800k-records)
- [Performance Benchmark Results](#-performance-benchmark-results)
- [Production Hardening \& Solved Pitfalls](#-production-hardening--solved-pitfalls)
- [Cluster Management Commands](#-cluster-management-commands)
- [License](#-license)

---

## 🌐 Cluster Architecture & Topology

The cluster operates across three Debian 12 (Bookworm) virtual machines communicating over a dedicated private network (`192.168.56.0/24`):

```
                       +--------------------------------------------------+
                       |              master (192.168.56.10)              |
                       |  - HDFS: NameNode (Port 9000, WebUI 9870)        |
                       |  - HDFS: SecondaryNameNode (Port 9868)           |
                       |  - YARN: ResourceManager (Port 8032, WebUI 8088) |
                       |  - RDBMS: MariaDB Metastore DB (Port 3306)       |
                       |  - Hive: Hive Metastore Thrift (Port 9083)       |
                       |  - Hive: HiveServer2 JDBC/ODBC (Port 10000)      |
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

### Node Specifications

| Node | Hostname | IP Address | Assigned Roles & Daemons | vCPUs | RAM | Swap |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Master** | `master` | `192.168.56.10` | NameNode, ResourceManager, MariaDB, Metastore, HiveServer2 | 2 | 2048 MB | 2048 MB |
| **Worker 1** | `worker1` | `192.168.56.11` | DataNode 1, NodeManager 1 | 1 | 1280 MB | 1024 MB |
| **Worker 2** | `worker2` | `192.168.56.12` | DataNode 2, NodeManager 2 | 1 | 1280 MB | 1024 MB |

---

## 📁 Repository Structure

```text
├── Vagrantfile                       # Multi-node VM provisioning & resource definitions
├── README.md                         # Project documentation and operational guide
├── config/                           # Distributed service configuration templates
│   ├── core-site.xml                 # HDFS defaultFS & proxyuser authorization
│   ├── hdfs-site.xml                 # Replication factor (2) & storage paths
│   ├── yarn-site.xml                 # ResourceManager address & shuffle service
│   ├── mapred-site.xml               # MapReduce framework & Java 17 JVM options
│   ├── hive-site.xml                 # MariaDB JDBC connection & Metastore URI
│   └── workers                       # Worker hostname registry (worker1, worker2)
├── scripts/                          # Automated cluster lifecycle scripts
│   ├── setup-hosts.sh                # /etc/hosts resolution & networking
│   ├── setup-common.sh               # OpenJDK 17 installation & system dependencies
│   ├── setup-hadoop.sh               # Hadoop directory structures & profile environment
│   ├── setup-master.sh               # MariaDB initialization & Hive schema initialization
│   ├── setup-worker.sh               # Worker-specific configurations
│   ├── start-hive.sh                 # Metastore & HiveServer2 background launcher
│   ├── stop-hive.sh                  # Graceful Hive service termination
│   └── verify-cluster.sh             # JPS and daemon status validator
├── exercise1_la_crime/               # Workload 1: 1M+ Records Crime Analytics
│   ├── 01_load_crime.sh              # HDFS ingestion & OpenCSVSerde table DDL
│   ├── 02_analyze_crime.sql          # Analytical SQL queries (trends, areas, weapons)
│   ├── 02_run_analysis.sh            # Automated query runner & log exporter
│   ├── analysis_results.txt          # Raw empirical query output logs
│   ├── report_exercise1_la_crime.pdf # Complete technical execution report
│   └── images/                       # Terminal verification screenshots
├── exercise2_divvy_bikes/            # Workload 2: 800K Records Mobility Pipeline & Benchmark
│   ├── 01_load_divvy.sh              # HDFS ingestion & raw staging schema
│   ├── 02_clean_and_orc.sh           # ORC columnar table creation & Snappy compression
│   ├── 03_analyze_divvy.sql          # 8 Core business intelligence questions
│   ├── 04_partition_and_benchmark.sql# Dynamic partitioning & benchmark suite
│   ├── run_all_exercise2.sh          # End-to-end workload pipeline runner
│   ├── divvy_execution_log.txt       # Execution logs with MapReduce counters
│   ├── report_exercise2_divvy_bikes.pdf # Complete benchmark & optimization report
│   └── images/                       # Terminal verification screenshots
├── docs/                             # Additional operational guides & screenshots
│   ├── SCREENSHOT_GUIDE.md           # Step-by-step query verification guide
│   └── screenshots/                  # Master collection of execution screenshots
└── keys/                             # Passwordless cluster SSH keypairs
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **Git**
- **Oracle VirtualBox** (Version 7.0+)
- **Vagrant** (Version 2.3+)
- Recommended: 8 GB+ Host RAM and 30 GB free storage.

*(Optional)* If your primary drive has limited space, redirect Vagrant VM disks to an external drive before launching:
```powershell
setx VAGRANT_HOME "E:\.vagrant.d"
$env:VAGRANT_HOME="E:\.vagrant.d"
```

### 2. Launch the Cluster
```bash
git clone https://github.com/MedSalimGh/Hadoop-Cluster.git
cd Hadoop-Cluster
vagrant up
```
Vagrant provisions all three nodes, installs OpenJDK 17, configures passwordless SSH under user `huser`, configures MariaDB, and formats HDFS.

### 3. Start Hadoop Daemons
Log into the master node:
```bash
vagrant ssh master
```
Switch to the dedicated cluster user `huser`:
```bash
su - huser
```
Start HDFS and YARN:
```bash
start-dfs.sh
start-yarn.sh
```

### 4. Start Hive Metastore & HiveServer2
```bash
bash /vagrant/scripts/start-hive.sh
```
Verify running services with `jps`:
```bash
jps
```
Expected output on `master`:
```text
NameNode
SecondaryNameNode
ResourceManager
RunJar (Hive Metastore)
RunJar (HiveServer2)
```

### 5. Connect to Hive via Beeline
Connect interactively over JDBC:
```bash
beeline -u "jdbc:hive2://localhost:10000" -n huser
```

---

## 🖥️ Web Interfaces & Endpoints

| Service | Target Node | URL | Default Port | Description |
| :--- | :--- | :--- | :--- | :--- |
| **HDFS NameNode** | `master` | [http://192.168.56.10:9870](http://192.168.56.10:9870) | `9870` | HDFS browser, storage capacity & datanode health |
| **YARN ResourceManager** | `master` | [http://192.168.56.10:8088](http://192.168.56.10:8088) | `8088` | Active & completed MapReduce applications |
| **HiveServer2** | `master` | `jdbc:hive2://192.168.56.10:10000` | `10000` | JDBC/ODBC client connection endpoint |
| **Hive Metastore** | `master` | `thrift://192.168.56.10:9083` | `9083` | Thrift metadata catalog service |
| **MariaDB RDBMS** | `master` | `localhost:3306` | `3306` | Relational metastore backend |

---

## 📊 Analytical Workloads

### Workload 1: Large-Scale Crime Analytics (1.0M+ Records)
- **Dataset:** Los Angeles Crime Data (2020–2024), 243.6 MB raw CSV, 1,004,894 records.
- **Challenge:** Textual fields contain commas inside quotes (e.g. `"ROBBERY, ATTEMPTED"`), causing standard delimiters to break column alignment.
- **Solution:** Implemented `OpenCSVSerde` with explicit quote and escape character parsing.
- **Execution Script:**
  ```bash
  bash /vagrant/exercise1_la_crime/01_load_crime.sh
  bash /vagrant/exercise1_la_crime/02_run_analysis.sh
  ```
- **Key Findings:**
  - Total records: **1,004,894** (100% unique primary key `dr_no`).
  - Top geographic hotspot: **Central Division** (69,668 incidents).
  - Most common crime: **Vehicle Theft** (115,184 incidents, 11.4% of total).
  - Firearm involvement: Exactly **20,182** incidents isolated with `HAND GUN`.
  - Demographic peak: Adults aged **25–34** represent the largest victim group (20.4%).

---

### Workload 2: Mobility Data Pipeline & Partitioning Benchmark (~800K Records)
- **Dataset:** Chicago Divvy Bikes Trip Data, 150.2 MB raw CSV, 790,177 trips.
- **Pipeline Architecture:**
  1. **Staging:** Ingestion into HDFS `/data/divvy/raw` via `OpenCSVSerde`.
  2. **Storage Optimization:** Converted raw strings to native `TIMESTAMP` and `DOUBLE` types, uppercased station names, and stored as **ORC (Optimized Row Columnar)** with **Snappy compression**.
  3. **Analytics:** Executed 8 core aggregation queries (trip durations, bike distributions, top routes, busiest hours).
  4. **Dynamic Partitioning:** Segmented into **33 daily partitions** (`start_date=2025-07-30` to `2025-08-31`).
- **Execution Script:**
  ```bash
  bash /vagrant/exercise2_divvy_bikes/run_all_exercise2.sh
  ```

---

## ⚡ Performance Benchmark Results

### 1. Storage Optimization: CSV vs. ORC + Snappy

| Storage Metric | Raw CSV Format | Managed ORC + Snappy | Reduction Factor |
| :--- | :--- | :--- | :--- |
| **Disk Footprint** | 150.2 MB | **29.9 MB** | **80.1% Storage Reduction** |
| **Column Projection** | Full file scan | Column-level read | Significant I/O reduction |

---

### 2. Query Benchmark: Full Table Scan vs. Dynamic Partition Pruning
Query: *Count total trips on August 15, 2025 (isolating 28,502 records)*.

| Metric | Non-Partitioned (`divvy_trips_cleaned`) | Partitioned (`divvy_trips_partitioned`) | Improvement |
| :--- | :--- | :--- | :--- |
| **HDFS Data Read** | **4,788,008 bytes (4.78 MB)** | **35,752 bytes (35.7 KB)** | **133.8× Less Data Read** |
| **Execution Time** | 34.62 seconds | **23.83 seconds** | **31.2% Faster** |
| **Cumulative CPU Time** | 3.95 seconds | **1.83 seconds** | **53.7% CPU Reduction** |
| **Execution Plan** | Full TableScan across all files | PartitionPruning (`start_date=2025-08-15`) | Targeted partition isolation |

---

## 🛠️ Production Hardening & Solved Pitfalls

During deployment and scaling, the following critical enterprise pitfalls were resolved:

1. **Java 17 InaccessibleObjectException (JEP 403 Strong Encapsulation):**
   - *Problem:* Java 17 blocks reflective access to internal JDK fields during Hive MapReduce serialization (e.g. Kryo / `java.util.regex`).
   - *Fix:* Added `--add-opens=java.base/java.lang=ALL-UNNAMED`, `--add-opens=java.base/java.util=ALL-UNNAMED`, and `--add-opens=java.base/java.util.regex=ALL-UNNAMED` to `mapred-site.xml` (`yarn.app.mapreduce.am.command-opts` and `mapreduce.map/reduce.java.opts`).

2. **Hadoop Protobuf 2.5 vs. Hive 3.x/4.x Classpath Clash:**
   - *Problem:* Writing ORC files failed with `NoSuchMethodError: java.lang.Object com.google.protobuf.Internal.checkNotNull` due to Hadoop's older Protobuf library taking precedence.
   - *Fix:* Configured `mapreduce.job.user.classpath.first=true` and `yarn.app.mapreduce.am.admin.user.class.paths.first=true` in `mapred-site.xml` across all nodes.

3. **Linux OOM Killer on HiveServer2:**
   - *Problem:* Multi-gigabyte MapReduce jobs triggered the Linux Out-Of-Memory killer on the master node, terminating HiveServer2 (`Connection refused on port 10000`).
   - *Fix:* Configured 2048 MB swap on `master` and 1024 MB swap on each worker in `/etc/fstab` with swappiness tuning.

4. **Tez SplitInfo Missing Dependency during EXPLAIN:**
   - *Problem:* Running `EXPLAIN` with Cost-Based Optimizer crashed with `ClassNotFoundException: org.apache.tez.mapreduce.hadoop.InputSplitInfo`.
   - *Fix:* Deployed `tez-mapreduce-0.10.4.jar` into Hive's `lib/` directory and configured `SET hive.cbo.enable=false;` for lightweight partition validation.

---

## 🔧 Cluster Management Commands

```bash
# Check cluster health & running processes
jps
hdfs dfsadmin -report
yarn node -list

# HDFS Storage Management
hdfs dfs -ls -h /data/
hdfs dfs -du -h /user/hive/warehouse/

# Hive Background Services
bash /vagrant/scripts/start-hive.sh
bash /vagrant/scripts/stop-hive.sh

# Run SQL files non-interactively
beeline -u "jdbc:hive2://localhost:10000/divvy_db" -n huser -f /path/to/query.sql
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
