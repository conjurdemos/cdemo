#!/bin/bash -e
set -o pipefail

CLUSTER_NAME=dev
CLUSTER_MANAGER_CONT_NAME=""
CLUSTER_POLICY_FILE=cluster.yml

main() {
	START_TIME=$(date)
	check_conjur_version
	setup_etcd
	kill_master
	wait_for_new_master
	wait_for_healthy_master
	./0-setup-standbys.sh
	END_TIME=$(date)
	printf "\nFailover complete. Cluster back in operational state.\n"
	printf "  Started: %s\n" "$START_TIME"
	printf "Completed: %s\n" "$END_TIME"
}

###########################
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

###########################
kill_master() {
	printf "\n-----\nKilling current master...\n"
        cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
		crole=$(docker exec $cname sh -c "evoke role")
		if [[ $crole == master ]]; then
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
			fi
		done
        done
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
setup_etcd() {
	printf "\n-----\nConfiguring etcd cluster manager and cluster policy...\n"
					# startup etcd cluster manager
	docker-compose up -d etcd
					# build cluster policy file
	construct_cluster_policy

					# load policy describing cluster
        docker-compose exec cli conjur authn login -u admin -p Cyberark1
	docker-compose exec cli conjur policy load --as-group=security_admin /src/cluster/$CLUSTER_POLICY_FILE

	printf "\n-----\nEnrolling Conjur nodes with cluster manager...\n"
					# enroll each stateful node in cluster
	for cname in $cont_list; do
		cont_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)
		docker exec $cname evoke cluster enroll -a $cont_ip -n $cname $CLUSTER_NAME
	done
}

#############################
construct_cluster_policy() {
					# create policy file header
	cat <<POLICY_HEADER > $CLUSTER_POLICY_FILE
---
- !policy
  id: conjur/cluster/$CLUSTER_NAME
  body:
    - !layer

    - &hosts
POLICY_HEADER
					# for each stateful node, add hosts entries to policy file
	cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
	for cname in $cont_list; do
		cont_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)
		printf "      - !host %s\n" $cname >> $CLUSTER_POLICY_FILE
	done
					# add footer to policy file
	cat <<POLICY_FOOTER >> $CLUSTER_POLICY_FILE
    - !grant
      role: !layer
      member: *hosts
POLICY_FOOTER

}

main "$@"
