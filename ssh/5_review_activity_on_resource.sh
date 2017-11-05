#!/bin/bash
if [[ "$1" == "" ]]; then
   printf "Provide name of resource...\n\n"
   exit 1
fi
RESOURCE=$1
printf  "\nReviewing activity on %s:\n" $RESOURCE
set -x
docker-compose exec cli conjur audit resource --short $RESOURCE 
