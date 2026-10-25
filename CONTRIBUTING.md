# Contributing to Hadoop & Hive Multi-Node Cluster

Thank you for your interest in contributing to this project!

## 1. Development Principles
- **Infrastructure as Code:** All modifications to machine definitions, memory allocation, or network topology must be committed to [Vagrantfile](Vagrantfile).
- **Zero Secrets Policy:** Never commit private keys, real cloud credentials, or sensitive production passwords to version control. All private keys must remain isolated inside guest VMs.
- **Idempotency:** All shell provisioning scripts in `scripts/` must be idempotent and safely re-executable without data loss or duplicate service failures.
- **Java 17 LTS Compatibility:** Maintain the explicit JEP 403 `--add-opens` JVM flags for all Hadoop, YARN, and Hive execution layers.

---

## 2. Local Testing Workflow
Before submitting changes or opening a pull request:

1. **Validate Syntax:**
   ```bash
   # Validate Vagrantfile
   vagrant validate

   # Validate Shell Scripts
   bash -n scripts/*.sh

   # Validate XML Configuration Files
   xmllint --noout config/*.xml
   ```

2. **Test Cluster Provisioning:**
   ```bash
   make up
   make start
   make verify
   ```

3. **Test High Availability (HA):**
   ```bash
   make ha-setup
   make ha-test
   ```

---

## 3. Pull Request Guidelines
- Provide a clear, descriptive title following Conventional Commits (e.g., `feat:`, `fix:`, `docs:`, `refactor:`).
- Detail what was changed, the technical rationale, and include verification logs or outputs.
- Ensure all CI workflow checks pass cleanly.
