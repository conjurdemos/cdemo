#!/bin/bash -ex
if [[ -z $1 ]] ; then
	printf "\n\tUsage: %s <policy-file-name>\n\n" $0
	exit 1
fi
POLICY_FILE=$1
NULL_RESULT="--- []"
RESULT=$(docker-compose exec -T cli conjur policy load --as-group security_admin --dry-run /src/$POLICY_FILE)
if [ "$RESULT" = "$NULL_RESULT" ]; then
	printf "\nCurrent state IS COMPLIANT with policy in %s.\n\n" $POLICY_FILE
else
	printf "\nCurrent state is NOT COMPLIANT with policy in %s.\n" $POLICY_FILE
	printf "Deviations in policy file from current state are:\n"
	echo $RESULT
fi

