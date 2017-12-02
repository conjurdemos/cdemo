#!/bin/bash
set -eo pipefail

CONJUR_CONTAINER_TARFILE=~/conjur-install-images/conjur-appliance-4.10.0.0.tar

CONJUR_MASTER_INGRESS=conjur_master
CONJUR_FOLLOWER_INGRESS=conjur_follower
CONJUR_MASTER_HOSTNAME=conjur_master
CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_MASTER_PASSWORD=Cyberark1

main() {

  all_down				# bring down anything still running

  conjur_master_up
  haproxy_up
  cli_up
  conjur_follower_up
  update_etc_hosts

  docker-compose up -d scope		# bring up webscope
  docker-compose build webapp		# force build of demo app
					# initialize "scalability" demo
  docker-compose exec cli "/src/etc/_demo-init.sh"

					# force builds of images for demo modules
  docker-compose build etcd
  docker-compose build ldap
  docker-compose build vm
  docker-compose build splunk

  echo
  echo "Demo environment ready!"
  echo "The Conjur service is running as hostname: $CONJUR_MASTER_INGRESS"
  echo
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
  CONJUR_MASTER_CONT_ID=$(docker ps -f "label=role=conjur_node" --format {{.Names}})	


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
  haproxy_cname=$(docker ps -f "label=role=conjur_proxy" --format {{.Names}})	
  docker container rename $haproxy_cname $CONJUR_MASTER_INGRESS
  pushd ./etc && ./update_haproxy.sh $CONJUR_MASTER_INGRESS && popd
}

############################
cli_up() {
  printf "\n-----\nBring up CLI client...\n"
  docker-compose up -d cli
 
  CLI_CONT_ID=$(docker-compose ps -q cli)

  echo "-----"
  echo "Copy Conjur config and certificate to CLI"
  docker cp -L ./etc/conjur.conf $CLI_CONT_ID:/etc
  docker cp -L ./etc/conjur-$CONJUR_MASTER_ORGACCOUNT.pem $CLI_CONT_ID:/etc
  docker-compose exec cli conjur authn login -u admin -p $CONJUR_MASTER_PASSWORD
  docker-compose exec cli conjur bootstrap -q
}

#############################
conjur_follower_up() {
	printf "\n-----\nConfiguring follower node...\n"

					# get container name of conjur master
	conjur_master_cname=$(docker ps -f "label=role=conjur_node" --format {{.Names}})	
					# generate seed file that references haproxy 
	docker exec -it $conjur_master_cname bash -c "evoke seed follower $CONJUR_MASTER_INGRESS > /tmp/follower-seed.tar"
					# and copy to local /tmp
	docker cp $conjur_master_cname:/tmp/follower-seed.tar /tmp/
	docker-compose up -d follower
					# only one follower
	conjur_follower_cname=$(docker ps -f "label=role=conjur_follower" --format {{.Names}})	
	docker rename $conjur_follower_cname $CONJUR_FOLLOWER_INGRESS

	docker cp /tmp/follower-seed.tar $CONJUR_FOLLOWER_INGRESS:/tmp/seed
	docker exec $CONJUR_FOLLOWER_INGRESS bash -c "evoke unpack seed /tmp/seed && evoke configure follower -j /src/etc/conjur.json" 
	rm /tmp/follower-seed.tar
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

############################
main "$@"
