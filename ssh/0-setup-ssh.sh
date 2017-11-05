#!/bin/bash -e
set -o pipefail

RACK_SERVICE_NAME=vm
RACK_POLICY_NAME=rack
RACK_POLICY_FILE=$RACK_POLICY_NAME.yml

################  MAIN   ################
# $1 = number of rack machine containers to create
main() {
        if [[ $# -ne 1 ]] ; then
                printf "\n\tUsage: %s <num-containers> \n\n" $0
                exit 1
        fi

	printf "\n-----\nBringing down old, then up all rack vm containers...\n"
        local NUM_CONTS=$1; shift
	docker-compose rm -svf $RACK_SERVICE_NAME
	docker-compose up -d --scale $RACK_SERVICE_NAME=$NUM_CONTS $RACK_SERVICE_NAME

	printf "\n-----\nConstructing & loading rack host policy...\n"
	cat > $RACK_POLICY_FILE << EOF
---
EOF
	rack_cont_names=$(docker ps --format "{{.Names}}" | grep $RACK_SERVICE_NAME)
	for cname in $rack_cont_names; do
		echo "- !host" $cname >> $RACK_POLICY_FILE
	done
	docker-compose exec -T cli conjur authn login -u admin -p Cyberark1
	docker-compose exec -T cli conjur policy load --as-group=security_admin /src/ssh/$RACK_POLICY_FILE


	printf "\n-----\nCreating host identity files and copying to shared volume in CLI container...\n"
	CLI_CONT_ID=$(docker-compose ps -q cli)
	for cname in $rack_cont_names; do
		api_key=$(docker-compose exec -T cli conjur host rotate_api_key --host $cname)
		cat ../etc/template.identity | sed s={{NAME}}=$cname= | sed s/{{PWD}}/$api_key/ > $cname.identity
		docker cp $cname.identity $CLI_CONT_ID:/data
		rm $cname.identity
	done

	printf "\n-----\nIn each container, copying identity files from shared volume, then deleting...\n"
	for cname in $rack_cont_names; do
						# note conjur.conf and conjur.pem are 
						# copied to shared volume after conjur 
						# service is brought up and never deleted
		docker exec $cname sudo cp /data/conjur.conf /etc/conjur.conf
		docker exec $cname sudo cp /data/conjur.pem /etc/conjur-dev.pem
						# identity files contain API key - need to protect
		docker exec $cname sudo cp /data/$cname.identity /etc/conjur.identity
		docker exec $cname sudo chmod 600 /etc/conjur.identity
		docker exec $cname rm /data/$cname.identity
	done

	printf "\nCompleted bringing up %n rack host identities.\n"
	printf "\nRack host identities now in Conjur:\n"
	echo $rack_cont_names
}

main "$@"
