#!/bin/bash -x
set -eo pipefail
if [[ $# -ne 2 ]] ; then
	printf "\n\tUsage: %s <user-name> <container-name>\n\n" $0
        exit 1
fi
USER=$1
CNAME=$2
printf "\nFrom container %s, retrieving public SSH key for user %s from Conjur service:\n\n" $CNAME $USER
docker exec -it $CNAME /opt/conjur/bin/conjur_authorized_keys $USER
