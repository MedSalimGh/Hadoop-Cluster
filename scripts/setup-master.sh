#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "=== Step 1: Installing and Configuring MariaDB Server ==="
echo "=========================================================="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mariadb-server libmariadb-java

systemctl enable mariadb
systemctl start mariadb

# Configure Hive Metastore Database and User in MariaDB (Matches PDF Prerequisites)
echo "Configuring MySQL/MariaDB database and user 'hive'..."
mysql -u root << 'EOF'
CREATE DATABASE IF NOT EXISTS metastore_db CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hive';
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'localhost';
GRANT ALL PRIVILEGES ON metastore_db.* TO 'hive'@'%';
FLUSH PRIVILEGES;
EOF

echo "MariaDB metastore_db and user 'hive' configured successfully."

echo "=========================================================="
echo "=== Step 2: Downloading and Installing Apache Hive 4.0.1 ="
echo "=========================================================="
HIVE_VERSION="4.0.1"
HIVE_TAR="apache-hive-${HIVE_VERSION}-bin.tar.gz"
RESOURCE_DIR="/vagrant/resources"

mkdir -p "$RESOURCE_DIR"

if [ ! -f "$RESOURCE_DIR/$HIVE_TAR" ]; then
    echo "Downloading Apache Hive ${HIVE_VERSION}..."
    HIVE_MIRRORS=(
        "https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/${HIVE_TAR}"
        "https://dlcdn.apache.org/hive/hive-${HIVE_VERSION}/${HIVE_TAR}"
    )
    DOWNLOADED=false
    for URL in "${HIVE_MIRRORS[@]}"; do
        echo "Attempting download from: $URL"
        if curl -fSL -A "Mozilla/5.0" -o "$RESOURCE_DIR/$HIVE_TAR" "$URL"; then
            echo "Successfully downloaded $HIVE_TAR"
            DOWNLOADED=true
            break
        fi
    done
    if [ "$DOWNLOADED" = false ]; then
        echo "Error: Failed to download Hive tarball from mirrors."
        exit 1
    fi
else
    echo "Hive tarball already present in $RESOURCE_DIR/$HIVE_TAR"
fi

if [ ! -d "/opt/apache-hive-${HIVE_VERSION}-bin" ]; then
    echo "Extracting Hive into /opt..."
    tar -xzf "$RESOURCE_DIR/$HIVE_TAR" -C /opt/
    ln -sfn "/opt/apache-hive-${HIVE_VERSION}-bin" /opt/hive
fi

echo "=========================================================="
echo "=== Step 3: Installing MariaDB Java Connector for Hive ==="
echo "=========================================================="
# Matches PDF Steps 8 & 9
if [ -f /usr/share/java/mariadb-java-client.jar ]; then
    cp /usr/share/java/mariadb-java-client.jar /opt/hive/lib/mysql-connector-java.jar
    echo "Copied mariadb-java-client.jar to /opt/hive/lib/mysql-connector-java.jar"
fi

# Also copy official mysql-connector-j if present in resources
if [ -f /vagrant/resources/mysql-connector-j-8.4.0.jar ]; then
    cp /vagrant/resources/mysql-connector-j-8.4.0.jar /opt/hive/lib/
fi

echo "=========================================================="
echo "=== Step 4: Configuring Hive Environment & hive-site.xml ="
echo "=========================================================="
# Matches PDF Step 4
echo "export HADOOP_HOME=/home/huser/hadoop-3.3.6" > /opt/hive/conf/hive-env.sh

# Matches PDF Step 5
cp /vagrant/config/hive-site.xml /opt/hive/conf/hive-site.xml

chown -R huser:huser /opt/apache-hive-${HIVE_VERSION}-bin
chown -R huser:huser /opt/hive

echo "=========================================================="
echo "=== Step 5: Formatting HDFS and Starting Hadoop Daemons =="
echo "=========================================================="
# Format NameNode only if not formatted yet
if [ ! -d "/home/huser/hadoopdata/dfs/name/current" ]; then
    echo "Formatting HDFS NameNode..."
    su - huser -c "hdfs namenode -format -force -nonInteractive"
fi

echo "Starting HDFS Daemons (NameNode, DataNodes, SecondaryNameNode)..."
su - huser -c "start-dfs.sh"

echo "Starting YARN Daemons (ResourceManager, NodeManagers)..."
su - huser -c "start-yarn.sh"

echo "Waiting for HDFS safe mode to clear..."
su - huser -c "hdfs dfsadmin -safemode wait"

echo "=========================================================="
echo "=== Step 6: Creating HDFS Directories for Hive ==========="
echo "=========================================================="
# Matches PDF Steps 6 & 7
echo "Creating /user/hive/warehouse and /tmp/hive..."
su - huser -c "hadoop fs -mkdir -p /user/hive/warehouse"
su - huser -c "hadoop fs -mkdir -p /tmp/hive"
su - huser -c "hadoop fs -chmod 777 /user/hive/warehouse"
su - huser -c "hadoop fs -chmod 777 /tmp/hive"
su - huser -c "hadoop fs -chmod 777 /tmp"

echo "=========================================================="
echo "=== Step 7: Initializing Hive Metastore Schema ==========="
echo "=========================================================="
# Matches PDF Step 10
echo "Initializing Hive Metastore schema in MariaDB..."
su - huser -c "schematool -initSchema -dbType mysql --verbose" || true

echo "=========================================================="
echo "=== Step 8: Starting Hive Metastore & HiveServer2 ========"
echo "=========================================================="
# Matches PDF Step 11
echo "Starting Hive Metastore service in background..."
su - huser -c "nohup hive --service metastore > /home/huser/hive-metastore.log 2>&1 &"

echo "Starting HiveServer2 service in background..."
su - huser -c "nohup hive --service hiveserver2 > /home/huser/hive-hiveserver2.log 2>&1 &"

echo "Waiting for services to initialize..."
sleep 10

echo "=== Master Node Provisioning Finished Successfully ==="
