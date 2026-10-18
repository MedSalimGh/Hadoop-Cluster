# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant"

  # ============================================================
  # Master Node (NameNode, ResourceManager, MySQL, Hive)
  # ============================================================
  config.vm.define "master", primary: true do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.provider "virtualbox" do |vb|
      vb.name = "hadoop-master"
      vb.memory = "2048"
      vb.cpus = 2
    end
    master.vm.provision "shell", path: "scripts/setup-common.sh"
  end

  # ============================================================
  # Worker Node 1 (DataNode 1 & NodeManager 1)
  # ============================================================
  config.vm.define "worker1" do |worker1|
    worker1.vm.hostname = "worker1"
    worker1.vm.network "private_network", ip: "192.168.56.11"
    worker1.vm.provider "virtualbox" do |vb|
      vb.name = "hadoop-worker1"
      vb.memory = "1280"
      vb.cpus = 1
    end
    worker1.vm.provision "shell", path: "scripts/setup-common.sh"
  end

  # ============================================================
  # Worker Node 2 (DataNode 2 & NodeManager 2)
  # ============================================================
  config.vm.define "worker2" do |worker2|
    worker2.vm.hostname = "worker2"
    worker2.vm.network "private_network", ip: "192.168.56.12"
    worker2.vm.provider "virtualbox" do |vb|
      vb.name = "hadoop-worker2"
      vb.memory = "1280"
      vb.cpus = 1
    end
    worker2.vm.provision "shell", path: "scripts/setup-common.sh"
  end
end
