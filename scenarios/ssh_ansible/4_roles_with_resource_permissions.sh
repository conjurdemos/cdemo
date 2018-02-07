#!/bin/bash
if [[ "$#" -ne 2 ]]; then
   printf "\nProvide name of resource and permission...\n\n"
   exit 1
fi
RESOURCE=$1
PERMISSION=$2
printf "\nAll roles having %s permission on %s:\n\n" $PERMISSION $RESOURCE
docker-compose -f ../../docker-compose.yml exec cli conjur resource permitted_roles $RESOURCE $PERMISSION
