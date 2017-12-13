#!/bin/bash
# write IP address of conjur master to host file, install jq and summon-conjur
sudo chmod a+w /etc/hosts
sudo echo $(netstat -rn | awk '/^0.0.0.0/ {print $2}') "conjur" >> /etc/hosts
sudo apt-get install jq
curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh | bash
