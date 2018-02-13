#!/bin/bash -e
set -o pipefail

. ../../etc/_loadcfg.sh

docker-compose exec cli conjur authn login -u admin -p $CONJUR_MASTER_PWD
docker-compose exec -T cli conjur ldap-sync policy show > ldap-sync.yml
docker-compose exec -T cli conjur elevate policy load /src/scenarios/ldap/ldap-sync.yml
printf "\n\nNow browse the users and groups in the UI to see the synced updates.\n\n"
