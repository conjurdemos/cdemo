#!/bin/bash -e
set -o pipefail
if [[ "$1" == "" ]]; then
   printf "Provide name of user...\n\n"
   exit 1
fi
USER=$1
printf "\nGenerating SSH keys for user %s and adding public key to Conjur...\n" $USER
docker-compose exec cli conjur authn login -u admin -p Cyberark1
ssh-keygen -q -b 2048 -t rsa -C $USER-ssh-demo -f id_$USER -N ''
docker-compose exec -T cli conjur pubkeys add $USER @/src/ssh/id_$USER.pub
