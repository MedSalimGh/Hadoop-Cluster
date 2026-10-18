#!/usr/bin/env bash
set -e

OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED"

for DIR in /home/huser/hadoop-3.3.6/etc/hadoop; do
    sed -i '/--add-opens/d' "$DIR/hadoop-env.sh" 2>/dev/null || true
    sed -i '/--add-opens/d' "$DIR/yarn-env.sh" 2>/dev/null || true
    sed -i '/PDSH_RCMD_TYPE/d' "$DIR/hadoop-env.sh" 2>/dev/null || true

    echo "export PDSH_RCMD_TYPE=ssh" >> "$DIR/hadoop-env.sh"
    echo "export HADOOP_OPTS=\"\$HADOOP_OPTS $OPTS\"" >> "$DIR/hadoop-env.sh"
    echo "export YARN_RESOURCEMANAGER_OPTS=\"\$YARN_RESOURCEMANAGER_OPTS $OPTS\"" >> "$DIR/yarn-env.sh"
    echo "export YARN_NODEMANAGER_OPTS=\"\$YARN_NODEMANAGER_OPTS $OPTS\"" >> "$DIR/yarn-env.sh"
done

# If Hive is installed, configure hive-env.sh with HADOOP_OPTS ONLY (not HIVE_OPTS)
HIVE_CONF=/home/huser/apache-hive-4.0.1-bin/conf/hive-env.sh
if [ -f "$HIVE_CONF" ]; then
    sed -i '/--add-opens/d' "$HIVE_CONF" 2>/dev/null || true
    sed -i '/HIVE_OPTS/d' "$HIVE_CONF" 2>/dev/null || true
    echo "export HADOOP_OPTS=\"\$HADOOP_OPTS $OPTS\"" >> "$HIVE_CONF"
    chown huser:huser "$HIVE_CONF"
fi

chown -R huser:huser /home/huser/hadoop-3.3.6/etc/hadoop/
