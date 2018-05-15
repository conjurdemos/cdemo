#!/bin/bash
if [[ -z $1 ]] ; then
	printf "\n\tUsage: %s <container-name>\n\n" $0
	exit 1
fi
docker exec $1 tail -f cc.log
