#!/usr/bin/env bash
set -e

OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED"

for DIR in /home/huser/hadoop-3.3.6/etc/hadoop; do
    sed -i '/--add-opens/d' "$DIR/hadoop-env.sh" 2>/dev/null || true
    sed -i '/--add-opens/d' "$DIR/yarn-env.sh" 2>/dev/null || true
    sed -i '/PDSH_RCMD_TYPE/d' "$DIR/hadoop-env.sh" 2>/dev/null || true

    echo "export PDSH_RCMD_TYPE=ssh" >> "$DIR/hadoop-env.sh"
    echo "export HADOOP_OPTS=\"\$HADOOP_OPTS $OPTS\"" >> "$DIR/hadoop-env.sh"
    echo "export YARN_RESOURCEMANAGER_OPTS=\"\$YARN_RESOURCEMANAGER_OPTS $OPTS\"" >> "$DIR/yarn-env.sh"
    echo "export YARN_NODEMANAGER_OPTS=\"\$YARN_NODEMANAGER_OPTS $OPTS\"" >> "$DIR/yarn-env.sh"
done

chown -R huser:huser /home/huser/hadoop-3.3.6/etc/hadoop/
