#!/bin/bash 
set -eo pipefail

CONJUR_MASTER_CNAME=""
CONJUR_INGRESS_NAME=conjur
NUM_STATEFUL_NODES=3			# 1 master + n standbys
NUM_FOLLOWERS=1	
CLUSTER_NAME=dev
CLUSTER_MANAGER_CONT_NAME=cdemo_etcd_1
CLUSTER_POLICY_FILE=cluster.yml

main() {
					# find master node
	cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
                crole=$(docker exec $cname sh -c "evoke role")
		if [[ $crole == master ]]; then
			CONJUR_MASTER_CNAME=$cname
			CONJUR_MASTER_IP="$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)"
			break
		fi
	done

	setup_standbys
	setup_followers
	setup_etcd
}

#############################
setup_standbys() {
					# generate seed file 
	docker exec -it $CONJUR_MASTER_CNAME bash -c "evoke seed standby conjur-standby > /tmp/standby-seed.tar"
					# copy to local /tmp
	docker cp $CONJUR_MASTER_CNAME:/tmp/standby-seed.tar /tmp/

					# bring up new nodes 
					# "no-recreate" prevents recreation of existing nodes
	docker-compose up -d --no-recreate --scale "conjur_node=$NUM_STATEFUL_NODES" conjur_node

					# configure each uninitialized stateful node as a standby
	cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
                crole=$(docker exec $cname sh -c "evoke role")
                if [[ "$crole" == "blank" ]]; then
			setup_node standby $cname
                fi
        done
	rm /tmp/standby-seed.tar

	sleep 10			# give cluster state time to settle, then start synchronous replication
	docker exec $CONJUR_MASTER_CNAME bash -c "evoke replication sync"

					# bounce proxy to add new standbys to its configuration	
	pushd ../etc && ./update_haproxy.sh conjur && popd
}


#############################
setup_followers() {
					# generate seed file that references haproxy 
					# and copy to local /tmp
	docker exec -it $CONJUR_MASTER_CNAME bash -c "evoke seed follower $CONJUR_INGRESS_NAME > /tmp/follower-seed.tar"
	docker cp $CONJUR_MASTER_CNAME:/tmp/follower-seed.tar /tmp/

	docker-compose up -d --no-recreate --scale "follower=$NUM_FOLLOWERS" follower

					# configure each uninitialized node as a standby
	cont_list=$(docker ps -f "label=role=conjur_follower" --format {{.Names}})
        for cname in $cont_list; do
                crole=$(docker exec $cname sh -c "evoke role")
                if [[ "$crole" == blank ]]; then
			setup_node follower $cname
                fi
        done
	rm /tmp/follower-seed.tar
 }


#############################
setup_node() {
	local CONJUR_ROLE=$1; shift		# role is either "standby" or "follower"
	local CONTAINER_ID=$1; shift

	echo "Creating $CONJUR_ROLE"

	docker cp /tmp/$CONJUR_ROLE-seed.tar $CONTAINER_ID:/tmp/seed
	MASTER_IP_ARG=""
	if [[ $CONJUR_ROLE == "standby" ]]; then
		MASTER_IP_ARG="-i $CONJUR_MASTER_IP"
	fi
	docker exec $CONTAINER_ID bash -c "evoke unpack seed /tmp/seed && evoke configure $CONJUR_ROLE -j /src/etc/conjur.json $MASTER_IP_ARG"
}


#############################
setup_etcd() {
					# startup etcd cluster manager
	docker-compose up -d etcd
					# build cluster policy file
	construct_cluster_policy

					# load policy describing cluster
        docker-compose exec cli conjur authn login -u admin -p Cyberark1
	docker-compose exec cli conjur policy load --as-group=security_admin /src/cluster/$CLUSTER_POLICY_FILE

					# enroll each stateful node in cluster
	for cont_name in $cont_list; do
		cont_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cont_name)
		docker exec $cont_name evoke cluster enroll -a $cont_ip -n $cont_name $CLUSTER_NAME
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
	for cont_name in $cont_list; do
		cont_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cont_name)
		printf "      - !host %s\n" $cont_name >> $CLUSTER_POLICY_FILE
	done
					# add footer to policy file
	cat <<POLICY_FOOTER >> $CLUSTER_POLICY_FILE
    - !grant
      role: !layer
      member: *hosts
POLICY_FOOTER

}

main "$@"
