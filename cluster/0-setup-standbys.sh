#!/bin/bash 
set -eo pipefail

CLUSTER_NAME=dev
CLUSTER_POLICY_FILE=cluster.yml

CONJUR_MASTER_CNAME=conjur1
CONJUR_MASTER_IP="$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' conjur1)"
CONJUR_MASTER_INGRESS=conjur_master
NUM_STATEFUL_NODES=3			# 1 master + 2 standbys
CONT_LIST=""	# list of stateful nodes
		# conjur version components for checking if auto-failover is supported
CONJUR_VERSION=""
CONJUR_MAJOR=""
CONJUR_MINOR=""
CONJUR_POINT=""

main() {
	start_new_standbys
	wait_for_healthy_master
	setup_standbys
	wait_for_standbys
					# start synchronous replication
	docker exec $CONJUR_MASTER_CNAME bash -c "evoke replication sync"
	wait_for_healthy_master
	setup_cluster_mgr
	update_load_balancer
	../inspect-cluster.sh
}

#############################
start_new_standbys() {
	printf "\n-----\nBringing up new standby node(s)...\n"
	docker-compose up -d conjur2
	docker-compose up -d conjur3
}

#############################
setup_standbys() {
	printf "\n-----\nConfiguring standby nodes...\n"
					# generate seed file 
	docker exec -it $CONJUR_MASTER_CNAME bash -c "evoke seed standby conjur-node > /tmp/standby-seed.tar"
					# copy to local /tmp
	docker cp $CONJUR_MASTER_CNAME:/tmp/standby-seed.tar /tmp/

	docker cp /tmp/standby-seed.tar conjur2:/tmp/seed
	docker exec conjur2 bash -c "evoke unpack seed /tmp/seed && evoke configure standby -j /src/etc/conjur.json -i $CONJUR_MASTER_IP"
	docker cp /tmp/standby-seed.tar conjur3:/tmp/seed
	docker exec conjur3 bash -c "evoke unpack seed /tmp/seed && evoke configure standby -j /src/etc/conjur.json -i $CONJUR_MASTER_IP"
	rm /tmp/standby-seed.tar
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
	set -e
}


#############################
wait_for_standbys() {
	printf "\n-----\nWaiting for all standbys to report streaming replication...\n"
	set +e
	let num_standbys=$NUM_STATEFUL_NODES-1
	while : ; do
		printf "..."
		sleep 2
		standby_state=$(curl -sk https://conjur_master/health | jq -r '.database.archive_replication_status.pg_stat_replication | .[].state')
		all_good=true
		standby_count=0
		for i in $standby_state; do
			if [[ $i != streaming ]]; then
				all_good=false
				break
			fi
			let standby_count=$standby_count+1
		done
		if [[ ($all_good == true) && ($standby_count == $num_standbys) ]]; then
			break
		fi
	done
	printf "\n"
	set -e
}

#############################
update_load_balancer() {
	printf "\n-----\nUpdating load balancer configuration...\n"
	pushd ../etc \
		&& ./update_haproxy.sh $CONJUR_MASTER_INGRESS \
		&& popd
}

#############################
setup_cluster_mgr() {
	failover_supported=false
	check_conjur_version
	if [ failover_supported ]; then
		setup_cluster_state
	fi
}

###########################
check_conjur_version() {
        printf "\n-----\nChecking if Conjur version supports failover...\n"
        CONJUR_VERSION=$(docker-compose exec cli conjur version | awk -F " " '/Conjur appliance version:/ { print $4 }')
        CONJUR_MAJOR=$(echo $CONJUR_VERSION | awk -F "." '{ print $1 }')
        CONJUR_MINOR=$(echo $CONJUR_VERSION | awk -F "." '{ print $2 }')
        CONJUR_POINT=$(echo $CONJUR_VERSION | awk -F "." '{ print $3 }')

        if [[ ($CONJUR_MINOR -lt 10) && ($CONJUR_POINT -lt 10) ]]; then
                printf "\nConjur version %i.%i.%i is running.\n" $CONJUR_MAJOR $CONJUR_MINOR $CONJUR_POINT
                printf "This script only supports failover in Conjur versions 4.9.10 and above.\n\n"
	else
		failover_supported=true
        fi
}

#############################
setup_cluster_state() {
	printf "\n-----\nConfiguring etcd cluster manager and cluster policy...\n"
	if [[ $CONJUR_POINT == 10 ]]; then
		docker-compose up -d etcd	# external etcd in 4.9.10
	fi
			
	CONT_LIST=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
	construct_cluster_policy	# build cluster policy file

					# load policy describing cluster
        docker-compose exec cli conjur authn login -u admin -p Cyberark1
	docker-compose exec cli conjur policy load --as-group=security_admin /src/cluster/$CLUSTER_POLICY_FILE

	for cname in $CONT_LIST; do
		if [[ $CONJUR_POINT == 10 ]]; then
			cont_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)
			docker exec $cname evoke cluster enroll -a $cont_ip -n $cname $CLUSTER_NAME
		else
			docker exec $cname evoke cluster enroll -n $cname $CLUSTER_NAME
		fi
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
	for cname in $CONT_LIST; do
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

main $@
