#!/bin/bash 
set -eo pipefail

CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_APPLIANCE_URL=https://conjur_follower/api
CONJUR_CONF_FILE=../etc/conjur_follower.conf
CONJUR_CERT_FILE=../etc/conjur_follower.pem
ACCESS_POLICY_FILE=ssh-bastion.yml
BASTION_SERVICES="outside bastion protected"
BASTION_CONT_NAMES="bastion_server protected_vm"
SSH_USERS="carol alice ted"

################  MAIN   ################
main() {
	load_policy
	bring_up_vms
	conjurize_vms
	setup_user_creds
}

######################
load_policy() {
	printf "\n-----\nLoading bastion server access policy...\n"
	docker exec conjur_cli conjur authn login -u admin -p Cyberark1
	docker exec conjur_cli conjur policy load --as-group=security_admin /src/bastion/$ACCESS_POLICY_FILE
}

######################
bring_up_vms() {
	printf "\n-----\nBringing down old, then up all vm containers...\n"
	# the outside and bastion VMs are both on the external network (netwkx)
	docker-compose rm -svf $BASTION_SERVICES
	docker-compose up -d $BASTION_SERVICES
}

######################
conjurize_vms() {
	printf "\n-----\nConfiguring hosts for SSH & identities ...\n"
       
	api_key=$(docker exec conjur_cli conjur host rotate_api_key --host bastion/server)
	conjurize_container_as_host bastion_server bastion/server $api_key

	hf_token=$(docker exec conjur_cli conjur hostfactory tokens create --duration-minutes=1 protected | jq -r .[].token) 
        api_key=$(docker exec conjur_cli conjur hostfactory hosts create $hf_token protected/vm | jq -r .api_key)
	conjurize_container_as_host protected_vm protected/vm $api_key

}

######################
conjurize_container_as_host(){
	cname=$1; shift
	hname=$1; shift
	api_key=$1; shift
			# note: conjur.conf and conjur-<orgacct>.pem are 
			# copied from conjur container to shared volume 
			# just after conjur service is brought up. 
	docker cp $CONJUR_CONF_FILE $cname:/etc/conjur.conf
	docker cp $CONJUR_CERT_FILE $cname:/etc

			# run chef recipe to configure vm for ssh access
	docker exec \
       		        -e CONJURRC=/etc/conjur.conf \
                	-e CONJUR_ACCOUNT=$CONJUR_MASTER_ORGACCOUNT \
	                -e CONJUR_APPLIANCE_URL=$CONJUR_APPLIANCE_URL \
       	        	-e CONJUR_AUTHN_LOGIN="host/$hname" \
       		        -e CONJUR_AUTHN_API_KEY=$api_key \
			$cname chef-solo -o conjur::configure

			# finish configuration, start sshd & logshipper
	docker exec $cname sudo /root/configure-ssh.sh
}

######################
setup_user_creds() {
	for i in $SSH_USERS; do
		setup_user $i
	done
}

######################
# sets up users on vm that is "outside" the network
setup_user() {
	user=$1
	printf "\n\n-----\nGenerating SSH keys for user %s and adding public key to Conjur...\n" $user
	ssh-keygen -q -b 2048 -t rsa -C ${user}-ssh-demo -f id_$user -N ''
	docker-compose exec -T cli conjur pubkeys add $user @/src/bastion/id_$user.pub

  	docker exec outside_vm sudo useradd -m $user
	docker exec outside_vm sudo su $user -c 'mkdir ~/.ssh'
	docker exec outside_vm sudo cp /src/bastion/id_$user /home/$user/.ssh/id_rsa
	docker exec outside_vm sudo chown $user:$user /home/$user/.ssh/id_rsa
	docker exec outside_vm sudo chmod 0600 /home/$user/.ssh/id_rsa
	cat <<SSH_CONFIG | docker exec -i outside_vm sudo su $user -c 'tee ~/.ssh/config'
Host *
  StrictHostKeyChecking no

Host protected_vm
  ProxyCommand  ssh bastion_server netcat -w 120 %h %p
SSH_CONFIG
	rm id_${user}*
}

main "$@"

