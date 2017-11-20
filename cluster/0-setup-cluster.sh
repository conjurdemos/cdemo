#!/bin/bash  -x
set -eo pipefail

CONJUR_MASTER_CNAME=cdemo_conjur_1

main() {
	docker-compose rm -svf standby follower
	docker-compose up -d standby follower
	setup_node standby
	setup_node follower
	docker-compose exec conjur bash -c "evoke replication sync"
 }

setup_node() {
	local CONJUR_ROLE=$1; shift		# role is either "standby" or "follower"

	echo "Creating $CONJUR_ROLE"

	docker exec -it $CONJUR_MASTER_CNAME bash -c "evoke seed $CONJUR_ROLE conjur-$CONJUR_ROLE > /tmp/$CONJUR_ROLE-seed.tar"
	docker cp $CONJUR_MASTER_CNAME:/tmp/$CONJUR_ROLE-seed.tar /tmp/
	CONTAINER_ID=cdemo_${CONJUR_ROLE}_1
	docker cp /tmp/$CONJUR_ROLE-seed.tar $CONTAINER_ID:/tmp/seed
	rm /tmp/$CONJUR_ROLE-seed.tar
	MASTER_IP_ARG=""
	if [[ $CONJUR_ROLE == "standby" ]]; then
		MASTER_IP_ARG="-i $(docker inspect cdemo_conjur_1 | jq -r .[].NetworkSettings.Networks.cdemo_default.IPAddress)"
	fi
	docker-compose exec $CONJUR_ROLE bash -c "evoke unpack seed /tmp/seed && evoke configure $CONJUR_ROLE $MASTER_IP_ARG"
}

main "$@"
