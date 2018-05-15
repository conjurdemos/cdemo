#!/bin/bash
if [[ -z $1 ]] ; then
	printf "\n\tUsage: %s <num-containers>\n\n" $0
	exit 1
fi
num_containers=$1
for (( c=1; c<=$num_containers; c++ ))
do
	cont_name="cont-$c"
	docker stop $cont_name && docker rm $cont_name &
	printf "Queued shutdown for container %s\n" $cont_name
done
