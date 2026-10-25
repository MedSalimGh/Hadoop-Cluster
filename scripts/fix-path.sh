#!/usr/bin/env bash
sudo rm -f /usr/local/bin/hive /usr/local/bin/beeline
sudo bash -c 'cat << "EOF" > /etc/profile.d/hive.sh
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HIVE_HOME/bin
EOF'
sudo chmod +x /etc/profile.d/hive.sh

sudo -u huser ssh -o StrictHostKeyChecking=no worker1 "sudo rm -f /usr/local/bin/hive /usr/local/bin/beeline; sudo bash -c 'cat << \"EOF\" > /etc/profile.d/hive.sh
export HIVE_HOME=/opt/hive
export PATH=\$PATH:\$HIVE_HOME/bin
EOF'; sudo chmod +x /etc/profile.d/hive.sh"
