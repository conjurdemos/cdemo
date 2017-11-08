#!/bin/bash -ex
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
	echo "---" > $RACK_POLICY_FILE
	rack_cont_names=$(docker ps --format "{{.Names}}" | grep $RACK_SERVICE_NAME)
	for cname in $rack_cont_names; do
		echo "- !host" $cname >> $RACK_POLICY_FILE
	done
	docker-compose exec -T cli conjur authn login -u admin -p Cyberark1
	docker-compose exec -T cli conjur policy load --as-group=security_admin /src/ssh/$RACK_POLICY_FILE


	printf "\n-----\nCreating host identity files and copying into containers...\n"
	CLI_CONT_ID=$(docker-compose ps -q cli)
	for cname in $rack_cont_names; do
			# note: conjur.conf and conjur-<orgacct>.pem are 
			# copied from conjur container to shared volume 
			# just after conjur service is brought up. 
		docker cp ../etc/conjur.conf $cname:/etc
		docker cp ../etc/conjur-dev.pem $cname:/etc

			# put hostname (container name) and api-key in id file
		api_key=$(docker-compose exec -T cli conjur host rotate_api_key --host $cname)
		cat ../etc/template.identity | sed s={{NAME}}=host/$cname= | sed s/{{PWD}}/$api_key/ > $cname.identity

			# copy host identity file to container
		docker cp $cname.identity $cname:/etc/conjur.identity
		rm $cname.identity

#		docker cp ../build/vm/conjur_authorized_keys $cname:/opt/conjur/bin
		docker cp ../build/vm/logshipper.conf $cname:/etc/init
		docker exec \
			-e CONJUR_AUTHN_LOGIN="host/$cname" \
			-e CONJUR_AUTHN_API_KEY=$api_key \
			$cname chef-solo -o conjur::configure

			# finish configuration, start sshd & logshipper
		docker cp ../build/vm/configure-ssh.sh $cname:/root
		docker exec $cname sudo /root/configure-ssh.sh
	done

	printf "\nCompleted bringing up %n rack host identities.\n"
	printf "\nRack host identities now in Conjur:\n"
	echo $rack_cont_names
}

main "$@"

