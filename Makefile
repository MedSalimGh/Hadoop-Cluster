# ==============================================================================
# Apache Hadoop 3.3.6 & Apache Hive 4.0.1 Multi-Node Cluster Automation Makefile
# ==============================================================================

.PHONY: help up status ssh start stop ha-setup ha-test verify destroy clean

help:
	@echo "Available commands:"
	@echo "  make up         - Boot and provision all 3 cluster virtual machines"
	@echo "  make status     - View current Vagrant VM statuses"
	@echo "  make ssh        - SSH into the master node"
	@echo "  make start      - Start HDFS, YARN, and Hive services on the cluster"
	@echo "  make stop       - Gracefully stop all cluster services"
	@echo "  make ha-setup   - Deploy ZooKeeper and launch Hive High Availability (HA)"
	@echo "  make ha-test    - Execute automated 6-stage Hive HA failover validation"
	@echo "  make verify     - Run automated 5-stage cluster verification suite"
	@echo "  make destroy    - Tear down and destroy all virtual machines"
	@echo "  make clean      - Clean local Vagrant runtime state and temporary files"

up:
	vagrant up

status:
	vagrant status

ssh:
	vagrant ssh master

start:
	vagrant ssh master -c "bash /vagrant/scripts/start-cluster.sh"

stop:
	vagrant ssh master -c "bash /vagrant/scripts/stop-cluster.sh"

ha-setup:
	vagrant ssh master -c "bash /vagrant/scripts/setup-ha-hive.sh"

ha-test:
	vagrant ssh master -c "bash /vagrant/scripts/test-ha-failover.sh"

verify:
	vagrant ssh master -c "bash /vagrant/scripts/verify-cluster.sh"

destroy:
	vagrant destroy -f

clean:
	rm -rf .vagrant keys/*.pub
