#!/bin/bash -e
set -o pipefail

main() {
	check_conjur_version
	kill_master
	wait_for_new_master
	./0-setup-cluster.sh
}

check_conjur_version() {
	printf "\n-----\nChecking if Conjur version supports failover...\n"
	conjur_version=$(docker-compose exec cli conjur version | awk -F " " '/Conjur appliance version:/ { print $4 }')
	conjur_major=$(echo $conjur_version | awk -F "." '{ print $1 }')
	conjur_minor=$(echo $conjur_version | awk -F "." '{ print $2 }')
	conjur_point=$(echo $conjur_version | awk -F "." '{ print $3 }')

	if [[ ($conjur_major -ne 4) || (($conjur_minor -lt 10) && ($conjur_point -lt 10)) ]]; then
		printf "\nConjur version %i.%i.%i is running.\n" $conjur_major $conjur_minor $conjur_point
		printf "Failover is only supported in Conjur version 4.9.10 or greater.\n\n" 
		exit -1
	fi
}

kill_master() {
	printf "\n-----\nStopping and removing current master...\n"
        cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
		crole=$(docker exec $cname sh -c "evoke role")
		if [[ $crole == master ]]; then
			docker stop $cname && docker rm $cname
		fi	
        done
}

wait_for_new_master() {
	printf "\n-----\nWaiting for standby to be promoted to master...\n"
        cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
	MASTER_FOUND=false
	while [[ $MASTER_FOUND == false ]]; do
	        for cname in $cont_list; do
			crole=$(docker exec $cname sh -c "evoke role")
			if [[ $crole == master ]]; then
				MASTER_FOUND=true
			fi
		done
        done
}

main "$@"
