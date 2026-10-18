#!/usr/bin/env bash
set -e

HADOOP_VERSION="3.3.6"
HADOOP_TAR="hadoop-${HADOOP_VERSION}.tar.gz"
RESOURCE_DIR="/vagrant/resources"
TARGET_DIR="/home/huser/hadoop-${HADOOP_VERSION}"

echo "=== [1/4] Checking and Acquiring Hadoop ${HADOOP_VERSION} Binary ==="
mkdir -p "$RESOURCE_DIR"

# Verify existing tarball integrity if present
if [ -f "$RESOURCE_DIR/$HADOOP_TAR" ]; then
    if ! tar -tzf "$RESOURCE_DIR/$HADOOP_TAR" >/dev/null 2>&1; then
        echo "Found incomplete or corrupted Hadoop tarball in $RESOURCE_DIR/$HADOOP_TAR. Removing it..."
        rm -f "$RESOURCE_DIR/$HADOOP_TAR"
    fi
fi

if [ ! -f "$RESOURCE_DIR/$HADOOP_TAR" ]; then
    echo "Downloading Hadoop ${HADOOP_VERSION} to shared storage..."
    MIRROR_URLS=(
        "https://repo.huaweicloud.com/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_TAR}"
        "https://mirrors.aliyun.com/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_TAR}"
        "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_TAR}"
    )
    DOWNLOADED=false
    for URL in "${MIRROR_URLS[@]}"; do
        echo "Downloading/resuming from: $URL"
        if curl -fSL -C - -# -A "Mozilla/5.0" -o "$RESOURCE_DIR/${HADOOP_TAR}.tmp" "$URL"; then
            echo "Verifying archive integrity..."
            if tar -tzf "$RESOURCE_DIR/${HADOOP_TAR}.tmp" >/dev/null 2>&1; then
                mv "$RESOURCE_DIR/${HADOOP_TAR}.tmp" "$RESOURCE_DIR/$HADOOP_TAR"
                echo "Successfully acquired verified $HADOOP_TAR"
                DOWNLOADED=true
                break
            else
                echo "Warning: Downloaded file from $URL failed archive validation."
                rm -f "$RESOURCE_DIR/${HADOOP_TAR}.tmp"
            fi
        fi
    done
    if [ "$DOWNLOADED" = false ]; then
        echo "Error: Failed to download Hadoop tarball from all mirrors."
        exit 1
    fi
else
    echo "Verified Hadoop tarball already present in $RESOURCE_DIR/$HADOOP_TAR"
fi

echo "=== [2/4] Extracting Hadoop into /home/huser ==="
if [ ! -f "$TARGET_DIR/share/hadoop/hdfs/hadoop-hdfs-${HADOOP_VERSION}.jar" ]; then
    echo "Extracting clean Hadoop archive to /home/huser/..."
    rm -rf "$TARGET_DIR"
    tar -xzf "$RESOURCE_DIR/$HADOOP_TAR" -C /home/huser/
    echo "Extracted Hadoop to $TARGET_DIR"
else
    echo "Hadoop installation directory already verified at $TARGET_DIR"
fi

echo "=== [3/4] Deploying Cluster Configuration Files ==="
cp /vagrant/config/core-site.xml "$TARGET_DIR/etc/hadoop/core-site.xml"
cp /vagrant/config/hdfs-site.xml "$TARGET_DIR/etc/hadoop/hdfs-site.xml"
cp /vagrant/config/yarn-site.xml "$TARGET_DIR/etc/hadoop/yarn-site.xml"
cp /vagrant/config/mapred-site.xml "$TARGET_DIR/etc/hadoop/mapred-site.xml"
cp /vagrant/config/workers "$TARGET_DIR/etc/hadoop/workers"

# Configure JAVA_HOME and HADOOP_HOME inside hadoop-env.sh
JAVA_DETECTED=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
sed -i "/export JAVA_HOME=/c\export JAVA_HOME=${JAVA_DETECTED}" "$TARGET_DIR/etc/hadoop/hadoop-env.sh" || \
echo "export JAVA_HOME=${JAVA_DETECTED}" >> "$TARGET_DIR/etc/hadoop/hadoop-env.sh"

echo "export HADOOP_HOME=/home/huser/hadoop-${HADOOP_VERSION}" >> "$TARGET_DIR/etc/hadoop/hadoop-env.sh"
echo "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" >> "$TARGET_DIR/etc/hadoop/hadoop-env.sh"
echo "export PDSH_RCMD_TYPE=ssh" >> "$TARGET_DIR/etc/hadoop/hadoop-env.sh"

echo "=== [4/4] Creating HDFS and TMP Storage Directories ==="
mkdir -p /home/huser/hadoopdata/tmp
mkdir -p /home/huser/hadoopdata/dfs/name
mkdir -p /home/huser/hadoopdata/dfs/data

chown -R huser:huser /home/huser/hadoop-${HADOOP_VERSION}
chown -R huser:huser /home/huser/hadoopdata

echo "Hadoop installation and configuration completed on $(hostname)."
