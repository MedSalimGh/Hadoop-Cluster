# Apache Hadoop 3.3.6 & Apache Hive 4.0.1 Multi-Node Cluster (IaC with Vagrant)

[![Hadoop Version](https://img.shields.io/badge/Apache%20Hadoop-3.3.6-E65225.svg)](https://hadoop.apache.org/)
[![Hive Version](https://img.shields.io/badge/Apache%20Hive-4.0.1-FDEE21.svg?logo=apachehive&logoColor=black)](https://hive.apache.org/)
[![Database](https://img.shields.io/badge/Metastore-MySQL%20%2F%20MariaDB-003545.svg?logo=mariadb)](https://mariadb.org/)
[![Java Version](https://img.shields.io/badge/Java-OpenJDK%2017-ED8B00.svg?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.x-1563FF.svg?logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.x-246BB3.svg?logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)

An enterprise-grade, fully functional 3-node **Apache Hadoop 3.3.6** and **Apache Hive 4.0.1** cluster deployed as Infrastructure as Code (IaC) using **Vagrant** and **Oracle VirtualBox**. Engineered with drive redirection (`E:\`) to bypass host SSD storage limits, comprehensive OpenJDK 17 reflection patches (JEP 403), resilient parallel shell execution, and an independent MySQL/MariaDB relational metastore backend.

---

## 🏛️ Academic Context
- **Institution:** University of Sfax --- Faculty of Sciences of Sfax
- **Department:** Computer Science and Communications
- **Course / Module:** Analytical Data Architectures based on Big Data
- **Student / Author:** Mohamed Salim Gharsellaoui
- **Supervisor / TA:** Montasser AKERMI

---

## 🌐 Cluster Architecture & Topology

The cluster consists of three Debian Bookworm 64-bit nodes connected via a dedicated Host-Only private network (`192.168.56.0/24`):

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

## 🚀 Part 1: Hadoop 3.3.6 Cluster Setup

### 1. Prerequisites (Host Machine)
- Git, Oracle VirtualBox 7.x, Vagrant 2.3+
- *(Optional: Redirection to Drive `E:\` if `C:\` has low space)*:
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

### 3. Connect to Master
```powershell
vagrant ssh master
```

### 4. Format & Start Hadoop Cluster (as `huser`)
```bash
su - huser

# Initialize NameNode metadata
hdfs namenode -format -force

# Start HDFS storage daemons
start-dfs.sh

# Start YARN compute daemons
start-yarn.sh
```

### 5. Verify Hadoop Cluster Health
```bash
# Check running Java processes
jps
# Master expected: NameNode, SecondaryNameNode, ResourceManager

# Verify live storage nodes
hdfs dfsadmin -report
# Expected: Live datanodes: 2 (worker1, worker2), ~180 GB usable capacity

# Verify active compute workers
yarn node -list
# Expected: Total Nodes: 2 in RUNNING state
```

---

## 🐝 Part 2: Apache Hive 4.0.1 Installation & Metastore Setup

### Step 0: Install MySQL / MariaDB Server on `master`
Hive requires an external relational database for its metastore. In Debian/Ubuntu, MariaDB is the official drop-in replacement for MySQL:

```bash
# Run on master as root / sudo
sudo apt-get update && sudo apt-get install -y default-mysql-server
sudo systemctl enable --now mariadb

# Initialize the metastore database and 'hive' user
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

### Step 1 & 2: Extract Apache Hive 4.0.1
Switch to user **`huser`** on **`master`**:
```bash
su - huser
cd /home/huser

# Extract Hive (you can use the local cached copy from /vagrant/resources/)
tar -xvf /vagrant/resources/apache-hive-4.0.1-bin.tar.gz
```

### Step 3: Configure Environment Variables in `~/.bashrc`
```bash
cat << 'EOF' >> ~/.bashrc
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HIVE_HOME/bin
EOF

source ~/.bashrc
```

### Step 4: Configure `HADOOP_HOME` in `hive-env.sh`
```bash
cp $HIVE_HOME/conf/hive-env.sh.template $HIVE_HOME/conf/hive-env.sh
echo "export HADOOP_HOME=/home/huser/hadoop-3.3.6" >> $HIVE_HOME/conf/hive-env.sh
```

### Step 5: Configure `hive-site.xml`
Create `$HIVE_HOME/conf/hive-site.xml` with JDBC parameters:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost/metastore_db?createDatabaseIfNotExist=true&amp;allowPublicKeyRetrieval=true</value>
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

### Step 6 & 7: Prepare HDFS Directories & Permissions
```bash
hadoop fs -mkdir -p /user/hive/warehouse
hadoop fs -mkdir -p /tmp/hive
hadoop fs -chmod 777 /user/hive/warehouse
hadoop fs -chmod 777 /tmp/hive
hadoop fs -chmod 777 /tmp
```

### Step 8 & 9: Install & Link JDBC Connector
```bash
sudo apt-get install -y libmariadb-java
cp /usr/share/java/mariadb-java-client.jar $HIVE_HOME/lib/mysql-connector-java.jar
```

### Step 10: Initialize Metastore Schema
```bash
schematool -initSchema -dbType mysql
```
*Expected: `schemaTool completed` and `Initialization script completed`.*

### Step 11: Start Hive Metastore & HiveServer2 Daemons
```bash
nohup hive --service metastore > /tmp/hive-metastore.log 2>&1 &
sleep 5
nohup hive --service hiveserver2 > /tmp/hiveserver2.log 2>&1 &
```
*(Or use the provided launcher script: `bash /vagrant/scripts/start-hive.sh`)*

### Step 12 & 13: Connect via Beeline & Test SQL Execution
```bash
beeline -u jdbc:hive2://localhost:10000 -n huser
```

Inside Beeline prompt:
```sql
SHOW DATABASES;
CREATE DATABASE university_hive;
USE university_hive;
CREATE TABLE course (id INT, title STRING, credits INT);
INSERT INTO course VALUES (1, 'Big Data Architecture', 4);
SELECT * FROM course;
```

---

## ⚠️ Pitfalls, Encountered Issues & How to Avoid Them

### 1. Parallel Shell (PDSH) Socket Permission Denied
- **Symptom:** Running `start-dfs.sh` or `start-yarn.sh` produces:
  ```text
  pdsh@master: worker1: rcmd: socket: Permission denied
  ```
- **Root Cause:** In Debian, `pdsh` defaults to the BSD `rcmd` module which demands setuid root capabilities on reserved ports.
- **Solution:** Add `export PDSH_RCMD_TYPE=ssh` into `$HADOOP_HOME/etc/hadoop/hadoop-env.sh` and `~/.bashrc`. This forces `pdsh` to use standard, passwordless SSH.

---

### 2. Java 17 InaccessibleObjectException on YARN Startup (JEP 403)
- **Symptom:** ResourceManager terminates immediately upon launch:
  ```text
  Caused by: java.lang.reflect.InaccessibleObjectException: Unable to make protected final 
  ClassLoader.defineClass(...) accessible: module java.base does not "opens java.lang" to unnamed module
  ```
- **Root Cause:** Java 17 strictly enforces modular encapsulation. Internal Google Guice libraries used by YARN fail to perform deep reflection unless explicitly opened.
- **Solution:** In `yarn-env.sh` and `hadoop-env.sh`, inject explicit module opening flags:
  ```bash
  export YARN_RESOURCEMANAGER_OPTS="$YARN_RESOURCEMANAGER_OPTS --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED"
  ```

---

### 3. YARN InvalidResourceRequestException (Container Exceeds Node Limit)
- **Symptom:** MapReduce jobs fail with:
  ```text
  Invalid resource request! Cannot allocate containers as requested resource is greater than maximum allowed allocation.
  Requested resource=<memory:1536, vCores:1>, maximum allowed allocation=<memory:1024, vCores:4>
  ```
- **Root Cause:** By default, Hadoop assigns 1536 MB to the MapReduce ApplicationMaster (`yarn.app.mapreduce.am.resource.mb`), which exceeds the total container size configured on small virtual machine workers.
- **Solution:** In `mapred-site.xml`, scale down container requirements:
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

### 4. Container ClassNotFoundException: `MRAppMaster`
- **Symptom:** Job fails during container launch with:
  ```text
  Error: Could not find or load main class org.apache.hadoop.mapreduce.v2.app.MRAppMaster
  ```
- **Root Cause:** Worker NodeManagers spawn container execution in clean child shells where `$HADOOP_MAPRED_HOME` is not inherited.
- **Solution:** Explicitly pass the distribution path via `mapred-site.xml`:
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

### 5. Hive Kryo Serialization Error: `Error caching map.xml`
- **Symptom:** Running `INSERT` or query plans in Hive fails with:
  ```text
  ERROR : Job Submission failed with exception 'java.lang.RuntimeException(Error caching map.xml)'
  Caused by: org.apache.hive.com.esotericsoftware.kryo.KryoException: java.lang.reflect.InaccessibleObjectException: 
  Unable to make field private volatile int java.util.concurrent.atomic.AtomicBoolean.value accessible: 
  module java.base does not "opens java.util.concurrent.atomic" to unnamed module
  ```
- **Root Cause:** Hive's Kryo serializer serializes `MapWork` plans. In Java 17, deep reflective access to `AtomicBoolean` inside `java.util.concurrent.atomic` is blocked.
- **Solution:** Add `--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED` to `HADOOP_OPTS` inside `$HIVE_HOME/conf/hive-env.sh` and in `mapred-site.xml` container options.

---

### 6. Passing JVM Flags: `HADOOP_OPTS` vs `HIVE_OPTS`
- **Symptom:** Starting HiveServer2 outputs:
  ```text
  Error starting HiveServer2 with given arguments:
  Unrecognized option: --add-opens=java.base/java.lang=ALL-UNNAMED
  ```
- **Root Cause:** In the `bin/hive` startup script, `HIVE_OPTS` are passed as **command-line arguments to the Java application**, not to the JVM itself.
- **Solution:** Always pass `--add-opens` and JVM-level flags through `HADOOP_OPTS`, keeping `HIVE_OPTS` strictly for Hive CLI parameters.

---

## 🖥️ Live Web Monitoring Dashboards

Directly accessible from your host machine's browser:
- **HDFS NameNode UI:** [http://192.168.56.10:9870](http://192.168.56.10:9870)
- **YARN ResourceManager UI:** [http://192.168.56.10:8088](http://192.168.56.10:8088)
- **HiveServer2 Web UI:** [http://192.168.56.10:10002](http://192.168.56.10:10002)
- **DataNode 1 UI:** [http://192.168.56.11:9864](http://192.168.56.11:9864)
- **DataNode 2 UI:** [http://192.168.56.12:9864](http://192.168.56.12:9864)

---

## 📄 Comprehensive Academic Lab Report
A complete LaTeX technical report with mathematical analysis, architecture diagrams, command references, and troubleshooting breakdowns is included at:
[`report/hadoop_hive_cluster_report.tex`](report/hadoop_hive_cluster_report.tex)
