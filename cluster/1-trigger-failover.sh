#!/bin/bash 
set -eo pipefail

CLUSTER_NAME=dev
CONJUR_MASTER_CNAME=""			# name of newly promoted master
CONJUR_MASTER_IP=""			# IP of newly promoted master
CONTAINER_TO_RECYCLE=""			# old master container to repurpose as standby
CONJUR_VERSION=""
CONJUR_MAJOR=""
CONJUR_MINOR=""
CONJUR_POINT=""

main() {
	START_TIME=$(date)
	check_CONJUR_VERSION
	kill_master
	wait_for_new_master
	wait_for_healthy_master
	recycle_old_master
	END_TIME=$(date)
	printf "\nFailover complete. Cluster back in operational state.\n"
	printf "  Started: %s\n" "$START_TIME"
	printf "Completed: %s\n" "$END_TIME"
}

###########################
check_CONJUR_VERSION() {
	printf "\n-----\nChecking if Conjur version supports failover...\n"
	CONJUR_VERSION=$(docker-compose exec cli conjur version | awk -F " " '/Conjur appliance version:/ { print $4 }')
	CONJUR_MAJOR=$(echo $CONJUR_VERSION | awk -F "." '{ print $1 }')
	CONJUR_MINOR=$(echo $CONJUR_VERSION | awk -F "." '{ print $2 }')
	CONJUR_POINT=$(echo $CONJUR_VERSION | awk -F "." '{ print $3 }')

	if [[ ($CONJUR_MINOR -lt 10) && ($CONJUR_POINT -lt 12) ]]; then
		printf "\nConjur version %i.%i.%i is running.\n" $CONJUR_MAJOR $CONJUR_MINOR $CONJUR_POINT
		printf "This script supports failover in Conjur version 4.9.12 and above.\n\n" 
		exit -1
	fi
}

###########################
kill_master() {
	printf "\n-----\nKilling current master...\n"
        cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
		crole=$(docker exec $cname sh -c "evoke role")
		if [[ $crole == master ]]; then
			CONTAINER_TO_RECYCLE=$cname
			printf "Stopping: "
			docker stop $cname 
			printf "Removing: "
			docker rm $cname
		fi	
        done
}

###########################
wait_for_new_master() {
	printf "\n-----\nWaiting for standby to be promoted to master...\n"
        cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
	MASTER_FOUND=false
	while [[ $MASTER_FOUND == false ]]; do
	        for cname in $cont_list; do
			crole=$(docker exec $cname sh -c "evoke role")
			if [[ $crole == master ]]; then
				MASTER_FOUND=true
				CONJUR_MASTER_CNAME=$cname
				CONJUR_MASTER_IP="$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)"
			fi
		done
        done
	printf "New master is: %s/%s\n" $CONJUR_MASTER_CNAME $CONJUR_MASTER_IP
}

#############################
wait_for_healthy_master() {
        printf "\n-----\nWaiting for master to report healthy...\n"
        set +e
        while : ; do
		printf "..."
                sleep 2
                healthy=$(curl -sk https://conjur_master/health | jq -r '.ok')
                if [[ $healthy == true ]]; then
                        break
                fi
        done
	printf "\n"
        set -e
}

#############################
recycle_old_master() {
        printf "\n-----\nConfiguring standby node...\n"
	docker-compose up -d $CONTAINER_TO_RECYCLE
                                        # generate seed file & pipe to standby
        docker exec $CONJUR_MASTER_CNAME evoke seed standby conjur-standby \
        	| docker exec -i $CONTAINER_TO_RECYCLE evoke unpack seed -
	docker exec $CONTAINER_TO_RECYCLE evoke configure standby -j /src/etc/conjur.json -i $CONJUR_MASTER_IP

	wait_for_healthy_master

        printf "\n-----\nRe-enrolling standby node in cluster...\n"
        if [[ $CONJUR_POINT == 10 ]]; then
           cont_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_TO_RECYCLE)
           docker exec $CONTAINER_TO_RECYCLE evoke cluster enroll -a $cont_ip -n $CONTAINER_TO_RECYCLE $CLUSTER_NAME
        else
           docker exec $CONTAINER_TO_RECYCLE evoke cluster enroll -n $CONTAINER_TO_RECYCLE $CLUSTER_NAME
        fi
}

main $@
