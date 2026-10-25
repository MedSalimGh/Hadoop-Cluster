# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-10-26

### Added
- **Automated Multi-Stage Vagrantfile Provisioning:** Sequential provisioning of common OS setup, Hadoop 3.3.6, MariaDB metastore, and Hive 4.0.1 across `master`, `worker1`, and `worker2`.
- **Dynamic Ed25519 SSH Guest Key Isolation:** Private keys are generated locally inside `/home/huser/.ssh/id_ed25519` on `master` with mode `0600`; only the public key (`cluster_key.pub`) is shared across `/vagrant/keys/` for workers.
- **Unified Cluster Lifecycle Scripts:** Added `scripts/start-cluster.sh` and `scripts/stop-cluster.sh` for one-command startup and shutdown.
- **Port Readiness Validation & Non-Zero Exit Codes:** Hardened `start-hive.sh` with `wait_for_port()` and timeout-based failure handling.
- **Makefile Automation:** Standard developer commands (`make up`, `make start`, `make stop`, `make ha-setup`, `make ha-test`, `make verify`).
- **Security & Governance Standards:** Added `SECURITY.md`, `.env.example`, `CONTRIBUTING.md`, connector license documentation, and `SHA256SUMS`.
- **GitHub Actions CI:** Automated workflow validating shell scripts, XML configs, and Vagrantfile syntax.

### Changed
- **Hive HA Hardening:** Replaced broad `pkill -f` in `setup-ha-hive.sh` and `stop-hive.sh` with PID file tracking and targeted SIGTERM/SIGKILL escalation.
- **ZooKeeper Verification:** Added failure exits to `setup-ha-hive.sh` if daemons fail to bind or ZooKeeper znodes fail to register under `/hiveserver2`.
- **Documentation Overhaul:** Re-aligned README positioning as an educational/development cluster, eliminated all `id_rsa` references, and added prominent database security alerts.

## [2.0.0] - 2026-10-25

### Added
- **Apache Hive 4.0.1 High Availability (HA):**
  - Active-Active HiveServer2 with dynamic service discovery on `master:10000` and `worker1:10000`.
  - Dual Hive Metastore Services on `master:9083` and `worker1:9083`.
  - Apache ZooKeeper 3.8.0 coordination ensemble on `master:2181`.
  - Automated 6-stage crash simulation and failover validator (`scripts/test-ha-failover.sh`).
- **MariaDB Remote Network Binding:** Enabled `bind-address = 0.0.0.0` for cluster-wide metadata catalog access.
- **Java 17 LTS JEP 403 JVM Flags:** Cluster-wide reflection access flags across daemons, MRAppMaster, and Hive query planner.

## [1.0.0] - 2026-10-20

### Added
- Initial 3-node Debian 12 Vagrant cluster deployment for Apache Hadoop 3.3.6 (HDFS & YARN) and Apache Hive 4.0.1 with MariaDB metastore.
