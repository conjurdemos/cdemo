#!/bin/bash -e
set -o pipefail

CONJUR_CONTAINER_TARFILE=~/conjur-install-images/conjur-appliance-4.10.0.0.tar

CONJUR_INGRESS_NAME=conjur
CONJUR_MASTER_HOSTNAME=haproxy
CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_MASTER_PASSWORD=Cyberark1

main() {

  printf "\n\nBringing down all running containers and restarting.\n"
  printf "\n\n\tThis will destroy your currently running environment - proceed?\n\n"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
  done

  all_down				# bring down anything still running

  conjur_up
  haproxy_up
  cli_up

  docker-compose up -d scope		# bring up webscope
  docker-compose build webapp		# force build of demo app
					# initialize "scalability" demo
  docker-compose exec cli "/src/etc/_demo-init.sh"

					# force builds of images for demo modules
  docker-compose build ldap
  docker-compose build splunk
  docker-compose build vm
  docker-compose build etcd

  echo
  echo "Demo environment ready!"
  echo "The Conjur service is running as hostname: $CONJUR_INGRESS_NAME"
  echo
}

############################
all_down() {
  echo "-----"
  printf "\n-----\nBringng down all running services & deleting dangling volumes\n"
  docker-compose down --remove-orphans
  dangling_vols=$(docker volume ls -qf dangling=true)
  if [[ "$dangling_vols" != "" ]]; then
	docker volume rm $dangling_vols
  fi
}

############################
conjur_up() {
  echo "-----"
  if [[ "$CONJUR_CONTAINER_TARFILE" == "" ]]; then
	printf "\n\nEdit this script to set CONJUR_CONTAINER_TARFILE to the location of the Conjur appliance tarfile to load.\n\n"
	exit -1
  fi

  if [[ "$(docker images --format {{.Repository}} | grep conjur-appliance)" == "" ]]; then
	echo "Loading image from tarfile..."
	LOAD_MSG=$(docker load -q -i $CONJUR_CONTAINER_TARFILE)
	IMAGE_ID=$(cut -d " " -f 3 <<< "$LOAD_MSG")		# parse image name as 3rd field in "Loaded image: xx" message
        sudo docker tag $IMAGE_ID conjur-appliance:latest
  fi

  echo "Bringing up Conjur"
  docker-compose up -d conjur_node
  CONJUR_MASTER_CONT_ID=cdemo_conjur_node_1


  echo "-----"
  echo "Initializing Conjur Master"
  docker exec $CONJUR_MASTER_CONT_ID \
		evoke configure master     \
		-j /src/etc/conjur.json	   \
		-h $CONJUR_MASTER_HOSTNAME \
		-p $CONJUR_MASTER_PASSWORD \
		$CONJUR_MASTER_ORGACCOUNT

  echo "-----"
  echo "Get certificate from Conjur"
  rm -f ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem
					# cache cert for copying to other containers
  docker cp -L $CONJUR_MASTER_CONT_ID:/opt/conjur/etc/ssl/conjur.pem ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem

}

############################
haproxy_up() {
					# bring up hproxy, rename as ingress, update & start 
  docker-compose up -d haproxy
  docker container rename cdemo_haproxy_1 $CONJUR_INGRESS_NAME
  pushd ./etc && ./update_haproxy.sh $CONJUR_INGRESS_NAME && popd

  hosts_entry=$(grep $CONJUR_INGRESS_NAME /etc/hosts)
  if [[ "$host_entry" == "" ]]; then
	echo "---- Update hosts file with Conjur container hostname: $CONJUR_INGRESS_NAME"
	grep -v $CONJUR_INGRESS_NAME /etc/hosts > /tmp/foo
	echo -e 127.0.0.1 '\t' $CONJUR_INGRESS_NAME >> /tmp/foo
	sudo mv /tmp/foo /etc/hosts
  fi
}

############################
cli_up() {
  echo "-----"
  echo "Bring up CLI client"
  docker-compose up -d cli
 
  CLI_CONT_ID=$(docker-compose ps -q cli)

  echo "-----"
  echo "Copy Conjur config and certificate to CLI"
  docker cp -L ./etc/conjur.conf $CLI_CONT_ID:/etc
  docker cp -L ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem $CLI_CONT_ID:/etc
  docker-compose exec cli conjur authn login -u admin -p $CONJUR_MASTER_PASSWORD
  docker-compose exec cli conjur bootstrap -q
}


main "$@"
