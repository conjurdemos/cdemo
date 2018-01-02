#!/bin/bash -e
set -o pipefail

CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_MASTER_URL=https://conjur_master/api
RACK_SERVICE_NAME=vm
RACK_POLICY_NAME=rack
RACK_POLICY_FILE=$RACK_POLICY_NAME.yml
ACCESS_POLICY_FILE=ssh-mgmt.yml
NUM_CONTS=""
RACK_CONT_NAMES=""

################  MAIN   ################
# $1 = number of rack machine containers to create
main() {
        if [[ $# -ne 1 ]] ; then
                printf "\n\tUsage: %s <num-containers> \n\n" $0
                exit 1
        fi
        NUM_CONTS=$1; shift
	setup_rack_vms
	setup_ansible
}

######################
setup_rack_vms() {
	refresh_vms
	construct_host_policy
	conjurize_vms

	printf "\n\nRack host identities now in Conjur:\n"
	echo $RACK_CONT_NAMES
}

######################
refresh_vms() {
	printf "\n-----\nBringing down old, then up all rack vm containers...\n"
	NUM_CONTS=$(( 2 > $NUM_CONTS ? 2 : $NUM_CONTS ))	# you have to have at least two VMs
	docker-compose rm -svf $RACK_SERVICE_NAME
	docker-compose up -d --scale $RACK_SERVICE_NAME=$NUM_CONTS $RACK_SERVICE_NAME
}

######################
construct_host_policy() {
	printf "\n-----\nConstructing & loading rack host policy...\n"
	echo "---" > $RACK_POLICY_FILE
	RACK_CONT_NAMES=$(docker ps --format "{{.Names}}" | grep $RACK_SERVICE_NAME)
	for cname in $RACK_CONT_NAMES; do
		echo "- !host" $cname >> $RACK_POLICY_FILE
	done
	docker-compose exec -T cli conjur authn login -u admin -p Cyberark1
	docker-compose exec -T cli conjur policy load --as-group=security_admin /src/ssh_ansible/$RACK_POLICY_FILE
	docker-compose exec -T cli conjur policy load --as-group=security_admin /src/ssh_ansible/$ACCESS_POLICY_FILE
}


######################
conjurize_vms() {
	printf "\n-----\nConfiguring hosts for SSH & identities ...\n"
	CLI_CONT_ID=$(docker-compose ps -q cli)
	for cname in $RACK_CONT_NAMES; do
			# note: conjur.conf and conjur-<orgacct>.pem are 
			# copied from conjur container to shared volume 
			# just after conjur service is brought up. 
		docker cp ../etc/conjur.conf $cname:/etc
		docker cp ../etc/conjur-dev.pem $cname:/etc

        	api_key=$(docker-compose exec -T cli conjur host rotate_api_key --host $cname)

			# run chef recipe to configure vm for ssh access
		docker exec \
       		        -e CONJURRC=/etc/conjur.conf \
                	-e CONJUR_ACCOUNT=$CONJUR_MASTER_ORGACCOUNT \
	                -e CONJUR_APPLIANCE_URL=$CONJUR_MASTER_URL \
       	        	-e CONJUR_AUTHN_LOGIN="host/$cname" \
       		        -e CONJUR_AUTHN_API_KEY=$api_key \
			$cname chef-solo -o conjur::configure

			# finish configuration, start sshd & logshipper
		docker exec $cname sudo /root/configure-ssh.sh
	done
}

######################
setup_ansible() {
	docker-compose up -d ansible
}


main "$@"

