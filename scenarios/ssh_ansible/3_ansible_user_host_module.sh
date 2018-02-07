#!/bin/bash
set -eo pipefail
if [[ $# -ne 3 ]] ; then
        printf "\n\tUsage: %s <user-name> <container-name> <module-name>\n\n" $0
        exit 1
fi
USER=$1
CNAME=$2
MNAME=$3
docker-compose -f ../../docker-compose.yml exec ansible ansible -m $MNAME $CNAME --private-key=/src/scenarios/ssh_ansible/id_$USER -u $USER
