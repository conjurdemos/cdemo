#!/bin/bash -e
set -o pipefail

. ../../etc/_loadcfg.sh

if [[ "$1" == "" ]]; then
   printf "Provide name of user...\n\n"
   exit 1
fi

USER=$1

announce_section "Generating SSH keys for user %s and adding public key to Conjur..." $USER

docker-compose -f ../../docker-compose.yml exec cli conjur authn login -u admin -p $CONJUR_MASTER_PASSWORD
ssh-keygen -q -b 2048 -t rsa -C $USER-ssh-demo -f id_$USER -N ''
docker-compose -f ../../docker-compose.yml exec -T cli conjur pubkeys add $USER @/src/scenarios/ssh_ansible/id_$USER.pub
