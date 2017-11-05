#!/bin/bash -e
set -o pipefail

CONJUR_ADMIN_PWD=Cyberark1

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
	docker rm $dangling_vols
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
  runInConjur /src/etc/_conjur-init.sh

  echo "-----"
  echo "Get certificate from Conjur"
  rm -f ./etc/conjur.pem
  docker cp -L $CONJUR_CONT_ID:/opt/conjur/etc/ssl/conjur.pem ./etc/conjur.pem

  echo "---- Update hosts file with $CONJUR_HOSTNAME"
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
  docker cp -L ./etc/conjur.conf $CLI_CONT_ID:/etc/conjur.conf
  docker cp -L ./etc/conjur.pem $CLI_CONT_ID:/etc/conjur.pem
  docker cp -L ./etc/conjur.conf $CLI_CONT_ID:/data/conjur.conf
  docker cp -L ./etc/conjur.pem $CLI_CONT_ID:/data/conjur.pem
  runIncli conjur authn login -u admin -p $CONJUR_ADMIN_PWD
  runIncli conjur bootstrap -q
}

runInConjur() {
  docker-compose exec -T conjur "$@"
}

runIncli() {
  docker-compose exec -T cli "$@"
}

wait_for_conjur() {
  docker-compose exec -T conjur bash -c 'while ! curl -sI localhost > /dev/null; do sleep 1; done'
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

