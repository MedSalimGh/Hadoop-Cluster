#!/usr/bin/env bash
set -e

echo "=== Finalizing Worker Configuration on $(hostname) ==="
chown -R huser:huser /home/huser/hadoop-3.3.6
chown -R huser:huser /home/huser/hadoopdata

echo "Worker node $(hostname) is ready for NameNode orchestration."
