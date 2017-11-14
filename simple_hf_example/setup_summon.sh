#!/bin/bash
# write IP address of conjur master to host file, install jq and summon-conjur
sudo chmod a+w /etc/hosts
sudo echo $(netstat -rn | awk '/^0.0.0.0/ {print $2}') "conjur" >> /etc/hosts
sudo apt-get install jq
curl -LO https://github.com/conjurinc/summon-conjur/releases/download/v0.2.0/summon-conjur_v0.2.0_linux-amd64.tar.gz
tar xvf summon-conjur_v0.2.0_linux-amd64.tar.gz
sudo mv summon-conjur /usr/local/bin
