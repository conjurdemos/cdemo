#!/bin/bash 
set -eo pipefail

. ../../etc/_loadcfg.sh

CONJUR_APPLIANCE_URL=https://$CONJUR_FOLLOWER_INGRESS/api
CONJUR_CONF_FILE=../../etc/conjur_follower.conf
CONJUR_CERT_FILE=../../etc/conjur_follower.pem
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

	announce_section "Rack host identities now in Conjur:\n$RACK_CONT_NAMES"
	echo $RACK_CONT_NAMES
}

######################
refresh_vms() {
	announce_section "Bringing down old, then up all rack vm containers..."
	NUM_CONTS=$(( 2 > $NUM_CONTS ? 2 : $NUM_CONTS ))	# you have to have at least two VMs
	docker-compose rm -svf $RACK_SERVICE_NAME
	docker-compose -f ../../docker-compose.yml up -d --scale $RACK_SERVICE_NAME=$NUM_CONTS $RACK_SERVICE_NAME
}

######################
construct_host_policy() {
	announce_section "Constructing & loading rack host policy..."
	echo "---" > $RACK_POLICY_FILE
	RACK_CONT_NAMES=$(docker ps --format "{{.Names}}" -f "label=role=rack-vm")
	for cname in $RACK_CONT_NAMES; do
		echo "- !host" $cname >> $RACK_POLICY_FILE
	done
	docker-compose -f ../../docker-compose.yml exec -T cli conjur authn login -u admin -p $CONJUR_MASTER_PASSWORD
	docker-compose -f ../../docker-compose.yml exec -T cli conjur policy load --as-group=security_admin /src/scenarios/ssh_ansible/$RACK_POLICY_FILE
	docker-compose -f ../../docker-compose.yml exec -T cli conjur policy load --as-group=security_admin /src/scenarios/ssh_ansible/$ACCESS_POLICY_FILE
}


######################
conjurize_vms() {
	announce_section "Configuring hosts for SSH & identities ..."
	CLI_CONT_ID=$(docker-compose ps -q cli)
	for cname in $RACK_CONT_NAMES; do
			# note: conjur.conf and .pem files are 
			# copied from conjur follower container
			# just after conjur service is brought up. 
		docker cp $CONJUR_CONF_FILE $cname:/etc/conjur.conf
		docker cp $CONJUR_CERT_FILE $cname:/etc

        	api_key=$(docker-compose -f ../../docker-compose.yml exec -T cli conjur host rotate_api_key --host $cname)

			# run chef recipe to configure vm for ssh access
		docker exec \
       		        -e CONJURRC=/etc/conjur.conf \
                	-e CONJUR_ACCOUNT=$CONJUR_MASTER_ORGACCOUNT \
	                -e CONJUR_APPLIANCE_URL=$CONJUR_APPLIANCE_URL \
       	        	-e CONJUR_AUTHN_LOGIN="host/$cname" \
       		        -e CONJUR_AUTHN_API_KEY=$api_key \
			$cname chef-solo -o conjur::configure

			# finish configuration, start sshd & logshipper
		docker exec $cname sudo /root/configure-ssh.sh
	done
}

######################
setup_ansible() {
	docker-compose -f ../../docker-compose.yml up -d ansible
}


main "$@"

