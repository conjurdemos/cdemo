#!/bin/bash
if [[ -z $1 ]] ; then
	printf "\n\tUsage: %s <policy-file-name>\n\n" $0
	exit 1
fi
POLICY_FILE=$1
docker-compose exec cli conjur authn login
docker-compose exec -T cli bash -c "cd /src/scenarios/policy && conjur policy load --as-group security_admin $POLICY_FILE"
