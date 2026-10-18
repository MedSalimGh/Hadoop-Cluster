# Apache Hadoop 3.3.6 Multi-Node Cluster (IaC with Vagrant)

[![Hadoop Version](https://img.shields.io/badge/Apache%20Hadoop-3.3.6-E65225.svg)](https://hadoop.apache.org/)
[![Java Version](https://img.shields.io/badge/Java-OpenJDK%2017-ED8B00.svg)](https://openjdk.org/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.x-1563FF.svg)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.x-246BB3.svg)](https://www.virtualbox.org/)

An automated, production-like 3-node **Apache Hadoop 3.3.6** cluster deployed as Infrastructure as Code (IaC) using **Vagrant** and **Oracle VirtualBox**. Configured with support for custom host drive relocation (Drive `E:\`) to preserve SSD space, optimized Java 17 module reflection flags, and full preparation for **Apache Hive 4.0.1** and **MariaDB Metastore**.

---

## 🏛️ Academic Context
- **Institution:** University of Sfax --- Faculty of Sciences of Sfax
- **Department:** Computer Science and Communications
- **Module:** Analytical Data Architectures based on Big Data
- **Student / Author:** Mohamed Salim Gharsellaoui
- **Supervisor / TA:** Montasser AKERMI

---

## 🌐 Cluster Architecture

The cluster consists of three Debian Bookworm 64-bit nodes connected via a dedicated Host-Only private network (`192.168.56.0/24`):

```
                       +-----------------------------------+
                       |         master (192.168.56.10)    |
                       |  - NameNode (HDFS Storage Master) |
                       |  - SecondaryNameNode              |
                       |  - ResourceManager (YARN Master)  |
                       |  - MariaDB (Hive Metastore)       |
                       |  - HiveServer2 & Hive Metastore   |
                       +-----------------+-----------------+
                                         |
                       +-----------------+-----------------+
                       |                                   |
        +--------------+--------------+     +--------------+--------------+
        |    worker1 (192.168.56.11)  |     |    worker2 (192.168.56.12)  |
        | - DataNode 1                |     | - DataNode 2                |
        | - NodeManager 1             |     | - NodeManager 2             |
        +-----------------------------+     +-----------------------------+
```

### Node Specifications

| Node | Hostname | IP Address | Role | vCPUs | RAM |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Master** | `master` / `namenode` | `192.168.56.10` | NameNode, ResourceManager, MySQL/Hive | 2 | 2048 MB |
| **Worker 1** | `worker1` / `datanode1` | `192.168.56.11` | DataNode 1, NodeManager 1 | 1 | 1280 MB |
| **Worker 2** | `worker2` / `datanode2` | `192.168.56.12` | DataNode 2, NodeManager 2 | 1 | 1280 MB |

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **Git**
- **Oracle VirtualBox 7.x**
- **Vagrant 2.3+**

*(Optional for Windows users with low C: storage)*
```powershell
setx VAGRANT_HOME "E:\.vagrant.d"
$env:VAGRANT_HOME="E:\.vagrant.d"
```

### 2. Clone and Launch Cluster
```powershell
git clone https://github.com/MedSalimGh/Hadoop-Cluster.git
cd Hadoop-Cluster

# Boot all three cluster virtual machines
vagrant up
```

### 3. Connect to the Master Node
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

---

## 🔍 Verification & Health Checks

### 1. Check Running Services (`jps`)
- On **`master`**: `NameNode`, `SecondaryNameNode`, `ResourceManager`
- On **`worker1`** & **`worker2`**: `DataNode`, `NodeManager`

### 2. Verify HDFS Live Storage
```bash
hdfs dfsadmin -report
```
*Expected: 2 Live datanodes (`worker1`, `worker2`), ~180 GB usable DFS storage.*

### 3. Verify YARN Compute Nodes
```bash
yarn node -list
```
*Expected: Total Nodes: 2 in `RUNNING` state.*

### 4. Run Distributed MapReduce Test
```bash
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar pi 2 10
```

---

## 🖥️ Web Dashboards

Directly accessible from your host machine's browser:
- **HDFS NameNode UI:** [http://192.168.56.10:9870](http://192.168.56.10:9870)
- **YARN ResourceManager UI:** [http://192.168.56.10:8088](http://192.168.56.10:8088)
- **DataNode 1 UI:** [http://192.168.56.11:9864](http://192.168.56.11:9864)
- **DataNode 2 UI:** [http://192.168.56.12:9864](http://192.168.56.12:9864)

---

## 🛠️ Key Technical Configurations & Fixes Included

1. **Parallel Shell (PDSH) Socket Fix:** Resolved `rcmd: socket: Permission denied` on Debian by explicitly exporting `PDSH_RCMD_TYPE=ssh` in `hadoop-env.sh`.
2. **Java 17 Strong Encapsulation (JEP 403):** Injected required `--add-opens` flags into `hadoop-env.sh`, `yarn-env.sh`, and `mapred-site.xml` to prevent Guice reflection errors (`InaccessibleObjectException`).
3. **Optimized YARN Container Sizing:** Configured lightweight memory allocations (`512MB` ApplicationMaster and container boundaries) tailored for resource-efficient virtualized environments.
4. **Apache Hive 4.0.1 Readiness:** Proxyuser impersonation configured in `core-site.xml` (`hadoop.proxyuser.huser.*`, `hadoop.proxyuser.hive.*`).

---

## 📄 Comprehensive Lab Report
A complete LaTeX technical report is provided under:
[`report/hadoop_hive_cluster_report.tex`](report/hadoop_hive_cluster_report.tex)
