#!/bin/bash
set -eo pipefail

		# EDIT TO POINT TO YOUR LOCAL CONJUR IMAGE TARFILE
CONJUR_CONTAINER_TARFILE=

CONJUR_MASTER_INGRESS=conjur_master
CONJUR_FOLLOWER_INGRESS=conjur_follower
CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_MASTER_PASSWORD=Cyberark1
CONJUR_MASTER_CONT_NAME=conjur1
CLI_CONT_NAME=conjur_cli

main() {
  check_dir_name
  all_down				# bring down anything still running

  conjur_master_up
  haproxy_up
  update_etc_hosts
  cli_up
  conjur_follower_up

  docker-compose up -d scope		# bring up webscope
  docker-compose build webapp		# force build of demo app
					# initialize "scalability" demo
  docker-compose exec cli "/src/etc/_demo-init.sh"

				# force image builds for demo modules
  docker-compose build ldap
  docker-compose build vm
  docker-compose build splunk

  echo
  echo "Demo environment ready!"
  echo "The Conjur master endpoint is at hostname: $CONJUR_MASTER_INGRESS"
  echo
}

############################
check_dir_name() {
	curr_dir_name=$(pwd | awk -F/ '{print $NF}')
	if [ "$curr_dir_name" != "cdemo" ]; then
		printf "\nRenaming directory from %s to cdemo.\n" $curr_dir_name
		cd ..; mv $curr_dir_name cdemo; cd cdemo
	fi
}

############################
all_down() {
  printf "\n\nBringing down all running containers.\n"
  printf "\n\n\tThis will destroy your currently running environment - proceed?\n\n"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit -1;;
    esac
  done

  echo "-----"
  printf "\n-----\nBringng down all running services & deleting dangling volumes\n"
  docker-compose down --remove-orphans
  dangling_vols=$(docker volume ls -qf dangling=true)
  if [[ "$dangling_vols" != "" ]]; then
	docker volume rm $dangling_vols
  fi
}

############################
conjur_master_up() {
  echo "-----"
  if [[ "$(docker images conjur-appliance:latest | grep conjur-appliance)" == "" ]]; then
  	if [[ "$CONJUR_CONTAINER_TARFILE" == "" ]]; then
		printf "\n\nEdit this script to set CONJUR_CONTAINER_TARFILE to the location of the Conjur appliance tarfile to load.\n\n"
		exit -1
	fi

	echo "Loading image from tarfile. This takes about a minute..."
	LOAD_MSG=$(docker load -i $CONJUR_CONTAINER_TARFILE)
	IMAGE_ID=$(cut -d " " -f 3 <<< "$LOAD_MSG")		# parse image name as 3rd field in "Loaded image: xx" message
        docker tag $IMAGE_ID conjur-appliance:latest
  fi

  image_tag=$(docker images | grep $(docker images conjur-appliance:latest --format "{{.ID}}") | awk '!/latest/ {print $2}')
  printf "Bringing up Conjur using image tagged as version %s...\n" $image_tag
  docker-compose up -d $CONJUR_MASTER_CONT_NAME

  echo "-----"
  echo "Initializing Conjur Master"
  docker exec $CONJUR_MASTER_CONT_NAME \
		evoke configure master     \
		-j /src/etc/conjur.json	   \
		-h $CONJUR_MASTER_INGRESS \
		-p $CONJUR_MASTER_PASSWORD \
		$CONJUR_MASTER_ORGACCOUNT

  echo "-----"
  echo "Get certificate from Conjur"
  rm -f ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem
					# cache cert for copying to other containers
  docker cp -L $CONJUR_MASTER_CONT_NAME:/opt/conjur/etc/ssl/conjur.pem ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem

}

############################
haproxy_up() {
  docker-compose up -d haproxy
}

############################
cli_up() {
  printf "\n-----\nBring up CLI client...\n"
  docker-compose up -d cli
 

  echo "-----"
  echo "Copy Conjur config and certificate to CLI"
  docker cp -L ./etc/conjur_master.conf $CLI_CONT_NAME:/etc/conjur.conf
  docker cp -L ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem $CLI_CONT_NAME:/etc
  docker-compose exec cli conjur authn login -u admin -p $CONJUR_MASTER_PASSWORD
}

#############################
conjur_follower_up() {
	printf "\n-----\nConfiguring follower node...\n"

	docker-compose up -d follower
					# generate seed file & pipe to follower
	docker exec conjur1 evoke seed follower $CONJUR_FOLLOWER_INGRESS \
		| docker exec -i $CONJUR_FOLLOWER_INGRESS evoke unpack seed -
	docker exec $CONJUR_FOLLOWER_INGRESS evoke configure follower -j /src/etc/conjur.json
	rm -f ./etc/conjur_follower.pem
	docker cp $CONJUR_FOLLOWER_INGRESS:/opt/conjur/etc/ssl/conjur_follower.pem ./etc
}

############################
update_etc_hosts() {
  set +e
  hosts_entry=$(grep $CONJUR_MASTER_INGRESS /etc/hosts)
  set -e
  if [[ "$hosts_entry" == "" ]]; then
	echo "---- Updating hosts file with Conjur Master and Follower ingress name & port..."
	grep -v $CONJUR_MASTER_INGRESS /etc/hosts > /tmp/foo
	printf "127.0.0.1\t%s\n" $CONJUR_MASTER_INGRESS >> /tmp/foo
	sudo mv /tmp/foo /etc/hosts
  fi
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

############################

main $@

