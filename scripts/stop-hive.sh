#!/usr/bin/env bash
echo "Stopping HiveServer2 and Metastore services..."

stop_service() {
    local name="$1"
    local pidfile="$2"
    local pattern="$3"

    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "Stopping $name (PID $pid)..."
            kill "$pid" 2>/dev/null || true
            for i in {1..10}; do
                kill -0 "$pid" 2>/dev/null || break
                sleep 0.5
            done
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "$pidfile"
    fi

    # Fallback to targeted pgrep if process still exists
    local remaining_pids
    remaining_pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [ -n "$remaining_pids" ]; then
        echo "Terminating remaining $name process(es): $remaining_pids"
        kill $remaining_pids 2>/dev/null || true
        sleep 1
        kill -9 $remaining_pids 2>/dev/null || true
    fi
}

stop_service "HiveServer2" "/tmp/hiveserver2.pid" "org.apache.hive.service.server.HiveServer2"
stop_service "Hive Metastore" "/tmp/hive-metastore.pid" "org.apache.hadoop.hive.metastore.HiveMetaStore"

echo "Hive services stopped."
