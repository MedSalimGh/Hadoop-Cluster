#!/usr/bin/env bash
set -e

echo "=== [1/5] Configuring Hostnames and Network Mapping ==="
cat << 'EOF' > /etc/hosts
127.0.0.1 localhost
192.168.56.10 master namenode
192.168.56.11 worker1 datanode1
192.168.56.12 worker2 datanode2
EOF

echo "=== [2/5] Installing Prerequisites and Dependencies ==="
export DEBIAN_FRONTEND=noninteractive
# Check if cached deb packages exist in /vagrant/resources/deb-cache
if [ -d /vagrant/resources/deb-cache ] && ls /vagrant/resources/deb-cache/*.deb >/dev/null 2>&1; then
    echo "Found local deb package cache. Installing directly from shared cache..."
    dpkg -i --force-depends /vagrant/resources/deb-cache/*.deb || apt-get install -fy
else
    apt-get update
    apt-get install -y --no-install-recommends \
        curl wget rsync net-tools procps tar openssh-server openssh-client \
        pdsh gnupg ca-certificates default-jdk-headless
fi

echo "Java version installed:"
java -version

echo "=== [3/5] Creating dedicated Hadoop user (huser) ==="
if ! id -u huser &>/dev/null; then
    useradd -m -s /bin/bash -U huser
    echo "huser:huser" | chpasswd
    usermod -aG sudo huser
fi

echo "huser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/huser
chmod 0440 /etc/sudoers.d/huser

echo "=== [4/5] Configuring Passwordless Cluster SSH Keys ==="
mkdir -p /home/huser/.ssh /vagrant/keys

# Generate cluster key dynamically during provisioning if not present
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

echo "=== [5/5] Setting Global and User Environment Variables ==="
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
EOF

# Append to huser's .bashrc if not already present
if ! grep -q "HADOOP_HOME" /home/huser/.bashrc; then
    cat /etc/profile.d/hadoop-hive.sh >> /home/huser/.bashrc
fi

chown huser:huser /home/huser/.bashrc
echo "Common setup completed successfully on $(hostname)."
