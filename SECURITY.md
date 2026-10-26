# Security Policy & Architecture Guidelines

## 1. Project Purpose & Threat Model

This repository is designed as an **educational, development, and research Infrastructure-as-Code (IaC) laboratory** simulating a multi-node Apache Hadoop 3.3.6 and Apache Hive 4.0.1 cluster on private, isolated virtual networks (`192.168.56.0/24`).

Because this environment is engineered for development and benchmarking, several configurations are intentionally streamlined:

| Setting | Lab Default | Production Standard | Technical Rationale for Lab |
| :--- | :--- | :--- | :--- |
| **HDFS Permissions** | `dfs.permissions.enabled=false` | `true` (with Kerberos & POSIX ACLs) | Eliminates user identity collisions between host and containerized YARN subshells. |
| **Hadoop Proxyuser** | Restricted to cluster nodes & IPs (`master,worker1,worker2,192.168.56.10-12,localhost`) | Strict FQDN / IP whitelist | Hardened against unauthorized external host impersonation while allowing HiveServer2 delegation. |
| **Metastore Database** | Restricted to `hive@192.168.56.%` & local interfaces | Individual application user + TLS + Vault | Restricts database access strictly to the private cluster subnet rather than wildcard `%`. |
| **HDFS Warehouse Permissions** | `chmod 777 /user/hive/warehouse` | `chmod 770` with group `hadoop` | Allows MapReduce application containers spawned by varied test users to write scratch output files. |
| **Lab Account (`huser`)** | Default dev credentials (`huser`) with sudo | Enterprise LDAP/SSO, locked local password | Enables non-interactive provisioning across headless Vagrant nodes. Production environments lock password accounts (`passwd -l`). |


> [!WARNING]
> Do not expose these virtual machines to public, routable networks without implementing the production hardening steps detailed in Section 3.

---

## 2. SSH Key Management Architecture

To adhere to the principle of least privilege and zero-knowledge secret storage:

1. **Zero Private Keys in Git:** Private SSH keys are **never** committed to version control. The directory `keys/` is strictly excluded in `.gitignore`.
2. **Runtime Guest Isolation:** During provisioning (`scripts/setup-common.sh`), the `master` node generates a fresh `ed25519` keypair locally in `/home/huser/.ssh/id_ed25519`.
3. **Unidirectional Distribution:** The private key **never leaves the master guest filesystem**. Only the public key (`id_ed25519.pub`) is copied to the shared mount as `cluster_key.pub` for worker nodes to authorize in `/home/huser/.ssh/authorized_keys`.
4. **File Mode Enforcement:** Strict POSIX permissions are applied:
   - `chmod 700 /home/huser/.ssh`
   - `chmod 600 /home/huser/.ssh/id_ed25519`
   - `chmod 600 /home/huser/.ssh/authorized_keys`

---

## 3. Production Hardening Checklist

When transitioning from this educational lab to a public cloud or enterprise on-premise deployment, apply the following security controls:

- [ ] **Kerberos Authentication:** Enable Hadoop security mode (`hadoop.security.authentication = kerberos`) with SPNEGO authentication for WebUIs and RPC endpoints.
- [ ] **TLS / SSL Encryption:** Enable In-Transit Encryption (`hadoop.ssl.enabled = true`, HiveServer2 SSL with custom PKCS12 keystores).
- [ ] **HDFS At-Rest Encryption:** Configure HDFS Transparent Data Encryption (TDE) with Apache Ranger KMS or Hadoop KMS.
- [ ] **Granular Access Control:** Deploy Apache Ranger or Apache Sentry for column-level, row-level, and tag-based authorization policies on Hive tables.
- [ ] **Secrets Management:** Replace plain-text passwords in `hive-site.xml` with Hadoop Credential Providers (`jceks://file/...`).
- [ ] **Firewall & Security Groups:** Restrict MariaDB port `3306`, ZooKeeper port `2181`, and HDFS IPC port `9000` strictly to cluster internal interfaces.

---

## 4. Reporting Security Vulnerabilities

If you identify a security defect, credential exposure, or configuration vulnerability within this repository, please disclose it responsibly by opening a private security advisory on GitHub or contacting the repository maintainers directly.
