# Apache Hadoop 3.3.6 & Apache Hive 4.0.1 Multi-Node Cluster (IaC with Vagrant)

[![Hadoop Version](https://img.shields.io/badge/Apache%20Hadoop-3.3.6-E65225.svg)](https://hadoop.apache.org/)
[![Hive Version](https://img.shields.io/badge/Apache%20Hive-4.0.1-FDEE21.svg?logo=apachehive&logoColor=black)](https://hive.apache.org/)
[![Database](https://img.shields.io/badge/Metastore-MySQL%20%2F%20MariaDB-003545.svg?logo=mariadb)](https://mariadb.org/)
[![Java Version](https://img.shields.io/badge/Java-OpenJDK%2017-ED8B00.svg?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.x-1563FF.svg?logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.x-246BB3.svg?logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)

An enterprise-grade, fully functional 3-node **Apache Hadoop 3.3.6** and **Apache Hive 4.0.1** cluster deployed as Infrastructure as Code (IaC) using **Vagrant** and **Oracle VirtualBox**. Engineered with secondary drive redirection (`E:\`) to bypass host SSD storage constraints, comprehensive OpenJDK 17 reflection patches (JEP 403), resilient parallel shell execution, and an independent MySQL/MariaDB relational metastore backend.

---

## 🏛️ Academic Context
- **Institution:** University of Sfax --- Faculty of Sciences of Sfax
- **Department:** Computer Science and Communications
- **Course / Module:** Analytical Data Architectures based on Big Data
- **Student / Author:** Mohamed Salim Gharsellaoui
- **Supervisor / TA:** Montasser AKERMI

---

## 🌐 Cluster Architecture & Topology

The cluster consists of three Debian Bookworm 64-bit virtual machines connected via a dedicated Host-Only private network (`192.168.56.0/24`):

```
                       +--------------------------------------------------+
                       |              master (192.168.56.10)              |
                       |  - HDFS: NameNode (Port 9000, WebUI 9870)        |
                       |  - HDFS: SecondaryNameNode (Port 9868)           |
                       |  - YARN: ResourceManager (Port 8032, WebUI 8088) |
                       |  - RDBMS: MySQL / MariaDB (Port 3306)            |
                       |  - Hive: Metastore Thrift Service (Port 9083)    |
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

| Node | Hostname | IP Address | Roles & Daemons | vCPUs | RAM |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Master** | `master` | `192.168.56.10` | NameNode, ResourceManager, MySQL, HiveServer2, Metastore | 2 | 2048 MB |
| **Worker 1** | `worker1` | `192.168.56.11` | DataNode 1, NodeManager 1 | 1 | 1280 MB |
| **Worker 2** | `worker2` | `192.168.56.12` | DataNode 2, NodeManager 2 | 1 | 1280 MB |

---

## 🚀 Part 1: Hadoop 3.3.6 Cluster Deployment

### 1. Prerequisites (Host Machine)
- Git, Oracle VirtualBox 7.x, Vagrant 2.3+
- *(Optional but Recommended: Redirection to Drive `E:\` if `C:\` has low storage)*:
  ```powershell
  setx VAGRANT_HOME "E:\.vagrant.d"
  $env:VAGRANT_HOME="E:\.vagrant.d"
  ```

### 2. Launch Virtual Machines
```powershell
git clone https://github.com/MedSalimGh/Hadoop-Cluster.git
cd Hadoop-Cluster
vagrant up
```

### 3. Connect to Master Node
```powershell
vagrant ssh master
```

### 4. Format & Start Hadoop Cluster (as `huser`)
```bash
su - huser

# Initialize NameNode metadata
hdfs namenode -format -force

# Start HDFS storage daemons (NameNode, SecondaryNameNode, DataNodes)
start-dfs.sh

# Start YARN compute daemons (ResourceManager, NodeManagers)
start-yarn.sh
```

### 5. Verify Hadoop Cluster Health
```bash
# Check running Java processes on master
jps
# Expected: NameNode, SecondaryNameNode, ResourceManager

# Verify live storage datanodes
hdfs dfsadmin -report
# Expected: Live datanodes: 2 (worker1, worker2), ~180 GB usable capacity

# Verify active compute workers
yarn node -list
# Expected: Total Nodes: 2 in RUNNING state
```

---

## 🐝 Part 2: Apache Hive 4.0.1 Installation & Configuration (Step-by-Step)

This guide follows the official lab curriculum from University of Sfax with enterprise-grade enhancements for Java 17 compatibility and automated orchestration.

### Step 0: Install MySQL / MariaDB Server on `master`
Hive requires an external relational database for its metastore. In modern Debian/Ubuntu distributions, MariaDB is the official drop-in replacement for MySQL:

```bash
# Run on master as root / sudo
sudo apt-get update && sudo apt-get install -y default-mysql-server
sudo systemctl enable --now mariadb

# Initialize metastore database and configure the 'hive' user
sudo mysql -u root << 'EOF'
CREATE DATABASE IF NOT EXISTS metastore_db;
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hive';
CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'%';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'localhost';
FLUSH PRIVILEGES;
EOF

# Verify connectivity as hive user
mysql -u hive -phive -e "SHOW DATABASES;"
```

### Step 1 & 2: Download & Extract Apache Hive 4.0.1
Switch to the dedicated Hadoop user **`huser`** on **`master`**:
```bash
su - huser
cd /home/huser

# Option A: Download directly from Apache archive
wget https://archive.apache.org/dist/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz
tar -xvf apache-hive-4.0.1-bin.tar.gz

# Option B: Extract from the pre-cached Vagrant shared folder
# tar -xvf /vagrant/resources/apache-hive-4.0.1-bin.tar.gz
```

### Step 3: Configure Environment Variables in `~/.bashrc`
Add `HIVE_HOME` and update your system `PATH`:
```bash
cat << 'EOF' >> ~/.bashrc
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HIVE_HOME/bin
EOF

source ~/.bashrc
```

### Step 4: Configure `HADOOP_HOME` & Java 17 Flags in `hive-env.sh`
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
Create `$HIVE_HOME/conf/hive-site.xml` with JDBC parameters, scratch paths, and impersonation settings:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <!-- Metastore JDBC connection URL -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost/metastore_db?createDatabaseIfNotExist=true&amp;allowPublicKeyRetrieval=true</value>
    </property>

    <!-- Metastore database username -->
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>

    <!-- Metastore database password -->
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

### Step 6 & 7: Prepare HDFS Directories & Permissions
Hive requires dedicated directories in HDFS with open read/write/execute permissions for scratch storage and table warehouses:
```bash
# Create Hive warehouse and scratch locations in HDFS
hadoop fs -mkdir -p /user/hive/warehouse
hadoop fs -mkdir -p /tmp/hive

# Grant full read/write/execute permissions
hadoop fs -chmod 777 /user/hive/warehouse
hadoop fs -chmod 777 /tmp/hive
hadoop fs -chmod 777 /tmp
```

### Step 8 & 9: Install & Link JDBC Connector
Install the MariaDB/MySQL JDBC driver package and copy the library to Hive's `lib` directory:
```bash
sudo apt-get install -y libmariadb-java
cp /usr/share/java/mariadb-java-client.jar $HIVE_HOME/lib/mysql-connector-java.jar
```

### Step 10: Initialize Metastore Schema
Run the schema tool to create all relational metadata tables in MySQL/MariaDB:
```bash
schematool -initSchema -dbType mysql
```
*Expected Output:* `schemaTool completed` and `Initialization script completed`.

### Step 11: Start Hive Metastore & HiveServer2 Daemons
You can start the background services manually:
```bash
nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &
sleep 5
nohup hive --service hiveserver2 > /tmp/hiveserver2.log 2>&1 &
```
*(Or use our automated launcher scripts located in `/vagrant/scripts/`):*
```bash
# Clean start with automated port readiness checks
bash /vagrant/scripts/start-hive.sh

# Stop all Hive background processes
bash /vagrant/scripts/stop-hive.sh
```

### Step 12 & 13: Connect via Beeline & Test SQL Execution
Launch the Beeline CLI client connecting to HiveServer2 on port 10000:
```bash
beeline -u jdbc:hive2://localhost:10000 -n huser
```

Inside the Beeline prompt, run the test scenario:
```sql
-- View existing databases
SHOW DATABASES;

-- Create university database
CREATE DATABASE IF NOT EXISTS university_hive;
USE university_hive;

-- Create course table
CREATE TABLE IF NOT EXISTS course (
    id INT, 
    title STRING, 
    credits INT
);

-- Insert sample records (triggers MapReduce on YARN)
INSERT INTO course VALUES (1, 'Big Data Architecture', 4), (2, 'Distributed Systems', 3);

-- Query the table
SELECT * FROM course;
```

*Expected Query Output:*
```text
+------------+------------------------+-----------------+
| course.id  |      course.title      | course.credits  |
+------------+------------------------+-----------------+
| 1          | Big Data Architecture  | 4               |
| 2          | Distributed Systems    | 3               |
+------------+------------------------+-----------------+
2 rows selected
```

---

## ⚠️ Problems to Avoid (Comprehensive Troubleshooting & Pitfalls)

Deploying a multi-node Hadoop and Hive cluster with modern operating systems and Java versions presents several intricate architectural challenges. Below is a comprehensive catalog of every critical issue encountered, its technical root cause, and the exact preventive solution.

---

### 1. Parallel Shell (PDSH) Socket Permission Denied
- **Symptom:** Running `start-dfs.sh` or `start-yarn.sh` produces:
  ```text
  pdsh@master: worker1: rcmd: socket: Permission denied
  pdsh@master: worker2: rcmd: socket: Permission denied
  ```
- **Root Cause:** In Debian and Ubuntu packages, `pdsh` defaults to the legacy BSD `rcmd` protocol, which requires setuid-root permissions on reserved sockets (`port < 1024`). Non-root users (`huser`) are prohibited from opening these sockets.
- **Problem to Avoid:** Never run `start-dfs.sh` as root or try `chmod u+s` on pdsh binaries.
- **Solution:** Force `pdsh` to use SSH by setting `PDSH_RCMD_TYPE=ssh` in `$HADOOP_HOME/etc/hadoop/hadoop-env.sh` and `~/.bashrc`:
  ```bash
  export PDSH_RCMD_TYPE=ssh
  ```

---

### 2. Java 17 InaccessibleObjectException on YARN Startup (JEP 403)
- **Symptom:** The YARN ResourceManager or NodeManager crashes immediately upon launch with:
  ```text
  Caused by: java.lang.reflect.InaccessibleObjectException: Unable to make protected final 
  java.lang.Class java.lang.ClassLoader.defineClass(...) accessible: 
  module java.base does not "opens java.lang" to unnamed module
  ```
- **Root Cause:** Java 17 enforces JEP 403 (Strong Encapsulation of JDK Internals). Hadoop 3.3.x relies on Google Guice and internal Java reflection that cannot access unexported JDK internals by default.
- **Problem to Avoid:** Do not downgrade your operating system or use deprecated Java 8 runtimes.
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
- **Symptom:** Hive queries that generate MapReduce jobs (`INSERT INTO ...`) fail immediately:
  ```text
  Invalid resource request! Cannot allocate containers as requested resource is greater than maximum allowed allocation.
  Requested resource=<memory:1536, vCores:1>, maximum allowed allocation=<memory:1024, vCores:4>
  ```
- **Root Cause:** By default, Hadoop assigns 1536 MB to the MapReduce ApplicationMaster (`yarn.app.mapreduce.am.resource.mb`), which exceeds the total RAM available to containers on virtual machine worker nodes configured with 1024 MB.
- **Problem to Avoid:** Do not allocate excessive memory to VMs that your host hardware cannot support.
- **Solution:** Configure container allocations in `$HADOOP_HOME/etc/hadoop/mapred-site.xml` to 512 MB:
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
- **Symptom:** YARN allocates a container on `worker1` or `worker2`, but the job fails during container startup:
  ```text
  Error: Could not find or load main class org.apache.hadoop.mapreduce.v2.app.MRAppMaster
  ```
- **Root Cause:** YARN NodeManagers launch containers in isolated, clean subshells that do NOT inherit environment variables from the user's `~/.bashrc`. Without `$HADOOP_MAPRED_HOME`, the container cannot locate MapReduce JARs.
- **Problem to Avoid:** Relying on interactive shell profiles (`~/.bashrc`) for daemon container execution.
- **Solution:** Explicitly pass the distribution path in `$HADOOP_HOME/etc/hadoop/mapred-site.xml`:
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
- **Symptom:** When executing `INSERT INTO course VALUES (...)`, Hive crashes during query plan generation:
  ```text
  ERROR : Job Submission failed with exception 'java.lang.RuntimeException(Error caching map.xml)'
  Caused by: org.apache.hive.com.esotericsoftware.kryo.KryoException: java.lang.reflect.InaccessibleObjectException: 
  Unable to make field private volatile int java.util.concurrent.atomic.AtomicBoolean.value accessible: 
  module java.base does not "opens java.util.concurrent.atomic" to unnamed module
  ```
- **Root Cause:** Hive's query planner uses the Kryo library to serialize `MapWork` execution plans and ship them to worker nodes. Under Java 17, deep reflective access to `AtomicBoolean.value` inside `java.util.concurrent.atomic` is strictly forbidden unless explicitly permitted.
- **Problem to Avoid:** Missing JVM reflection arguments in the Hive client and MapReduce container runners.
- **Solution:** Add `--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED` and `--add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED` to `HADOOP_OPTS` in `$HIVE_HOME/conf/hive-env.sh` and in `mapred-site.xml` container options:
  ```bash
  export HADOOP_OPTS="$HADOOP_OPTS --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED"
  ```

---

### 6. Passing JVM Flags: `HADOOP_OPTS` vs `HIVE_OPTS`
- **Symptom:** Starting HiveServer2 with `--add-opens` flags in `HIVE_OPTS` produces:
  ```text
  Error starting HiveServer2 with given arguments:
  Unrecognized option: --add-opens=java.base/java.lang=ALL-UNNAMED
  ```
- **Root Cause:** In the Apache Hive `bin/hive` execution script:
  - `HADOOP_OPTS` are passed directly to the `java` virtual machine command line (`java $HADOOP_OPTS ...`).
  - `HIVE_OPTS` are passed as **command-line arguments to the Java application class** after the class name (`... org.apache.hive.service.server.HiveServer2 $HIVE_OPTS`).
- **Problem to Avoid:** Placing JVM flags like `-Xmx`, `-D...`, or `--add-opens` into `HIVE_OPTS`.
- **Solution:** Always export JVM-level flags in `HADOOP_OPTS`, keeping `HIVE_OPTS` strictly for Hive CLI parameters.

---

### 7. Hadoop Proxyuser Impersonation Denied (`User: huser is not allowed to impersonate`)
- **Symptom:** HiveServer2 or Beeline fails with:
  ```text
  RemoteException: User: huser is not allowed to impersonate huser (or anonymous)
  ```
- **Root Cause:** HiveServer2 acts as a proxy service that submits queries to HDFS and YARN on behalf of connected clients. Hadoop's security model forbids proxying unless explicitly authorized in `core-site.xml`.
- **Problem to Avoid:** Forgetting to configure proxyuser settings on the NameNode and ResourceManager.
- **Solution:** Add proxyuser wildcard rules to `$HADOOP_HOME/etc/hadoop/core-site.xml`:
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
  Additionally, set `hive.server2.enable.doAs=false` in `hive-site.xml` to ensure queries execute under the trusted daemon identity.

---

### 8. HiveServer2 Startup Delay & Port 10000 Connection Refused
- **Symptom:** Launching Beeline immediately after `nohup hive --service hiveserver2 &` outputs:
  ```text
  Error: Could not open client transport with JDBC Uri: jdbc:hive2://localhost:10000: 
  java.net.ConnectException: Connection refused (Connection refused)
  ```
- **Root Cause:** HiveServer2 performs schema validation, Thrift server initialization, and WebUI startup. This startup process takes **15 to 25 seconds** on virtualized hardware before binding to TCP port 10000.
- **Problem to Avoid:** Do not launch Beeline immediately after starting HiveServer2.
- **Solution:** Poll port 10000 before connecting or use our `start-hive.sh` script which verifies readiness:
  ```bash
  # Check if HiveServer2 has bound to port 10000
  ss -tulpn | grep 10000
  ```

---

### 9. MariaDB / MySQL Driver Class & SSL Handshake Issues
- **Symptom:** Metastore schema initialization fails with:
  ```text
  ClassNotFoundException: com.mysql.jdbc.Driver
  -- OR --
  Communications link failure / SSLHandshakeException
  ```
- **Root Cause:** 
  1. `com.mysql.jdbc.Driver` is deprecated in newer connector versions.
  2. The MariaDB connector driver class is `org.mariadb.jdbc.Driver`.
  3. Default modern MySQL/MariaDB installations require SSL unless disabled or public key retrieval is permitted.
- **Problem to Avoid:** Using outdated driver class names without SSL parameters.
- **Solution:** Use `org.mariadb.jdbc.Driver` and append `createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true` to the JDBC connection string in `hive-site.xml`:
  ```xml
  <property>
      <name>javax.jdo.option.ConnectionURL</name>
      <value>jdbc:mysql://localhost/metastore_db?createDatabaseIfNotExist=true&amp;allowPublicKeyRetrieval=true</value>
  </property>
  <property>
      <name>javax.jdo.option.ConnectionDriverName</name>
      <value>org.mariadb.jdbc.Driver</value>
  </property>
  ```

---

### 10. HDFS Scratch and Warehouse Permissions (`Permission Denied`)
- **Symptom:** Table creation or query execution fails with:
  ```text
  Permission denied: user=huser, access=WRITE, inode="/user/hive/warehouse":drwxr-xr-x
  ```
- **Root Cause:** By default, HDFS directories are owned by the user who created them with restrictive umask permissions. Hive needs open write access to create database directories and temporary stage folders.
- **Problem to Avoid:** Forgetting to grant recursive `777` permissions to HDFS paths before starting Hive.
- **Solution:** Execute permission grants on HDFS:
  ```bash
  hadoop fs -mkdir -p /user/hive/warehouse
  hadoop fs -mkdir -p /tmp/hive
  hadoop fs -chmod -R 777 /user/hive/warehouse
  hadoop fs -chmod -R 777 /tmp/hive
  hadoop fs -chmod 777 /tmp
  ```

---

### 11. Host SSD Exhaustion (Drive Redirection to `E:\`)
- **Symptom:** Vagrant or VirtualBox crashes during VM creation with `VBOX_E_FILE_ERROR` or host drive `C:\` running out of free space.
- **Root Cause:** By default, Vagrant caches base boxes in `C:\Users\<user>\.vagrant.d` and VirtualBox saves VM virtual disks (`.vdi`) in `C:\Users\<user>\VirtualBox VMs`. Deploying three nodes can consume 20--30 GB of storage.
- **Problem to Avoid:** Allowing Vagrant and VirtualBox to default to drive `C:\` when disk capacity is constrained.
- **Solution:** Set `VAGRANT_HOME` and configure VirtualBox to use a secondary drive (e.g., `E:\`):
  ```powershell
  # In PowerShell on host
  setx VAGRANT_HOME "E:\.vagrant.d"
  $env:VAGRANT_HOME="E:\.vagrant.d"
  VBoxManage setproperty machinefolder "E:\Virtual Machines\IAC VMS"
  ```

---

## 🛠️ Management & Automation Scripts

All scripts are located in the [`scripts/`](scripts/) directory and mounted automatically into each VM at `/vagrant/scripts/`:

| Script | Location | Purpose |
| :--- | :--- | :--- |
| `start-hive.sh` | [`scripts/start-hive.sh`](scripts/start-hive.sh) | Cleanly starts Hive Metastore & HiveServer2 with automated port readiness polling (9083, 10000). |
| `stop-hive.sh` | [`scripts/stop-hive.sh`](scripts/stop-hive.sh) | Terminates all running Hive Metastore and HiveServer2 processes. |
| `verify-cluster.sh` | [`scripts/verify-cluster.sh`](scripts/verify-cluster.sh) | Comprehensive 5-stage health check (JPS, HDFS report, YARN nodes, MapReduce Pi calculation, Hive SQL). |
| `test-hive.sql` | [`scripts/test-hive.sql`](scripts/test-hive.sql) | Standard SQL test script for database creation, table creation, insertion, and querying. |
| `setup-common.sh` | [`scripts/setup-common.sh`](scripts/setup-common.sh) | Installs base packages, OpenJDK 17, hosts file, and `huser` SSH credentials across all nodes. |
| `setup-hadoop.sh` | [`scripts/setup-hadoop.sh`](scripts/setup-hadoop.sh) | Provisions Hadoop 3.3.6 binaries, environment variables, and symlinks. |
| `setup-master.sh` | [`scripts/setup-master.sh`](scripts/setup-master.sh) | Provisions MariaDB, initializes database, and deploys Apache Hive 4.0.1 on master. |

---

## 🖥️ Live Web Monitoring Dashboards

Directly accessible from your host machine's browser via host-only networking:

- **HDFS NameNode UI:** [http://192.168.56.10:9870](http://192.168.56.10:9870)
- **YARN ResourceManager UI:** [http://192.168.56.10:8088](http://192.168.56.10:8088)
- **HiveServer2 Web UI:** [http://192.168.56.10:10002](http://192.168.56.10:10002)
- **DataNode 1 UI:** [http://192.168.56.11:9864](http://192.168.56.11:9864)
- **DataNode 2 UI:** [http://192.168.56.12:9864](http://192.168.56.12:9864)

---

## 📄 Comprehensive Academic Lab Report
A complete LaTeX technical report with mathematical analysis, architecture diagrams, command references, and troubleshooting breakdowns is included at:
[`report/hadoop_hive_cluster_report.tex`](report/hadoop_hive_cluster_report.tex)
