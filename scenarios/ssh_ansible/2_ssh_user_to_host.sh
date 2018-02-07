#!/bin/bash 

. ../../etc/_loadcfg.sh

if [[ $# -ne 2 ]] ; then
	printf "\n\tUsage: %s <user-name> <container-name>\n\n" $0
        exit 1
fi

USER=$1
CNAME=$2

announce_section "User $USER attempting to ssh from CLI container to container $CNAME:" $USER $CNAME 
docker exec $CNAME service nscd restart > /dev/null
docker-compose -f ../../docker-compose.yml exec cli ssh -o StrictHostKeyChecking=no -i /src/scenarios/ssh_ansible/id_$USER $USER@$CNAME
