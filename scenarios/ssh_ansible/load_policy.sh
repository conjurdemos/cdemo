#!/bin/bash

. ../../etc/_loadcfg.sh

if [[ -z $1 ]] ; then
	printf "\n\tUsage: %s <policy-file-name>\n\n" $0
	exit 1
fi

POLICY_FILE=$1

docker-compose -f ../../docker-compose.yml exec cli conjur authn login -u admin -p $CONJUR_MASTER_PASSWORD
docker-compose -f ../../docker-compose.yml exec -T cli conjur policy load --as-group security_admin /src/scenarios/ssh_ansible/$POLICY_FILE
