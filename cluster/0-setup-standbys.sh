#!/bin/bash 
set -eo pipefail

CONJUR_MASTER_CNAME=""
CONJUR_MASTER_IP=""
CONJUR_MASTER_INGRESS=conjur_master
NUM_STATEFUL_NODES=3			# 1 master + n standbys

main() {

	find_current_master
	start_new_standbys
	wait_for_healthy_master
	setup_standbys
	update_load_balancer
	../inspect-cluster.sh
}

#############################
find_current_master() {
					# find master node, get container name & IP address
	cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
                crole=$(docker exec $cname sh -c "evoke role")
		if [[ $crole == master ]]; then
			CONJUR_MASTER_CNAME=$cname
			CONJUR_MASTER_IP="$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)"
			break
		fi
	done
}

#############################
start_new_standbys() {
	printf "\n-----\nBringing up new standby node(s)...\n"
			# "no-recreate" prevents recreation of existing nodes
	docker-compose up -d --no-recreate --scale "conjur_node=$NUM_STATEFUL_NODES" conjur_node
}

#############################
setup_standbys() {
	printf "\n-----\nConfiguring standby nodes...\n"
					# generate seed file 
	docker exec -it $CONJUR_MASTER_CNAME bash -c "evoke seed standby conjur-standby > /tmp/standby-seed.tar"
					# copy to local /tmp
	docker cp $CONJUR_MASTER_CNAME:/tmp/standby-seed.tar /tmp/

					# configure each uninitialized stateful node as a standby
	cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
                crole=$(docker exec $cname sh -c "evoke role")
                if [[ "$crole" == "blank" ]]; then
			docker cp /tmp/standby-seed.tar $cname:/tmp/seed
			docker exec $cname bash -c "evoke unpack seed /tmp/seed && evoke configure standby -j /src/etc/conjur.json -i $CONJUR_MASTER_IP"
                fi
        done
	rm /tmp/standby-seed.tar

	wait_for_standbys
					# start synchronous replication
	docker exec $CONJUR_MASTER_CNAME bash -c "evoke replication sync"
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

main $@
