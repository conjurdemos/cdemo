#!/bin/bash -e
set -o pipefail

CONJUR_CONTAINER_TARFILE=""


CONJUR_MASTER_HOSTNAME=cdemo_conjur_1
CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_MASTER_PASSWORD=Cyberark1

main() {

  echo "Bringing down all running containers and restarting - proceed?"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
  done

  all_down				# bring down anything still running

  conjur_up
  cli_up
  docker-compose up -d scope		# weave scope

  docker-compose build ldap
  docker-compose build splunk
  docker-compose build vm
  docker-compose build webapp

					# initialize "scalability" demo
  docker-compose exec cli "/src/etc/_demo-init.sh"

  echo
  echo "Demo environment ready!"
  echo "The Conjur service is running as hostname: $CONJUR_HOSTNAME"
  echo
}

############################
all_down() {
  echo "-----"
  echo "Bringng down all running services & deleting dangling volumes"
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
  docker-compose up -d conjur

  CONJUR_CONT_ID=$(docker-compose ps -q conjur)
  CONJUR_HOSTNAME=$(docker inspect --format '{{ .Config.Hostname }}' $CONJUR_CONT_ID)

  echo "-----"
  echo "Initializing Conjur"
  docker-compose exec conjur evoke configure master -h $CONJUR_MASTER_HOSTNAME -p $CONJUR_MASTER_PASSWORD $CONJUR_MASTER_ORGACCOUNT

  echo "-----"
  echo "Get certificate from Conjur"
  rm -f ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem
					# cache cert for copying to other containers
  docker cp -L $CONJUR_CONT_ID:/opt/conjur/etc/ssl/conjur.pem ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem

  echo "---- Update hosts file with Conjur container hostname: $CONJUR_HOSTNAME"
  grep -v $CONJUR_HOSTNAME /etc/hosts > /tmp/foo
  echo -e 127.0.0.1 '\t' $CONJUR_HOSTNAME >> /tmp/foo
  sudo mv /tmp/foo /etc/hosts
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

