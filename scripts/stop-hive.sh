#!/usr/bin/env bash
echo "Stopping HiveServer2 and Metastore services..."
pkill -f "org.apache.hadoop.hive.metastore.HiveMetaStore" 2>/dev/null || true
pkill -f "org.apache.hive.service.server.HiveServer2" 2>/dev/null || true
sleep 2
echo "Hive services stopped."
