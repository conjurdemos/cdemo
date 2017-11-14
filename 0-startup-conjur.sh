#!/bin/bash -e
set -o pipefail

CONJUR_MASTER_HOSTNAME=cyberark.local
CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_MASTER_PASSWORD=Cyberark1

main() {
  all_down				# bring down anything still running

  conjur_up
  cli_up
  docker-compose up -d scope		# weave scope

  docker-compose build ldap		# trigger image pull
  docker-compose build splunk		# trigger image pull

					# initialize "scalability" demo
  docker-compose exec cli "/src/etc/_demo-init.sh"

  clear
  echo
  echo "Demo environment ready!"
  echo "The Conjur service is running as hostname: $CONJUR_HOSTNAME"
  echo
}

all_down() {
  echo "-----"
  echo "Bringng down all running services & deleting dangling volumes"
  docker-compose down --remove-orphans
  dangling_vols=$(docker volume ls -qf dangling=true)
  if [[ "$dangling_vols" != "" ]]; then
	docker volume rm $dangling_vols
  fi
}

conjur_up() {
  echo "-----"
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

updatehostsfile() {
  local containername="$1"
  local tmpfile=/tmp/${1}.tmp

  conthostname=$(docker inspect --format '{{ .Config.Hostname }}' $containername)
  echo "---- Update hosts file for $conthostname"
  grep -v $conthostname /etc/hosts > $tmpfile
  echo -e 127.0.0.1 '\t' $conthostname >> $tmpfile
  sudo mv $tmpfile /etc/hosts
}

main "$@"

