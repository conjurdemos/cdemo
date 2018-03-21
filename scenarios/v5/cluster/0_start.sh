#!/bin/bash
set -e pipefail

CDEMO_ROOT=../../..
CONJUR_IMAGE=registry.tld/conjur-appliance:5.0-stable

function main {
  initialize
  conjur_master_up
}

function initialize {
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
  pushd $CDEMO_ROOT
  docker-compose down --remove-orphans
  dangling_vols=$(docker volume ls -qf dangling=true)
  if [[ "$dangling_vols" != "" ]]; then
        docker volume rm $dangling_vols
  fi
  popd
}

function conjur_master_up {
  echo "-----"
  if [[ "$(docker images $CONJUR_IMAGE | grep conjur-appliance)" == "" ]]; then
 	LOAD_MSG=$(curl 'https://s3.amazonaws.com/appliance-v5-dev.conjur.org/conjur-appliance%3A5.0.0-alpha.1.tar.gz?AWSAccessKeyId=AKIAIFJWM5FD6QYF5QDA&Expires=1521732748&Signature=%2BMIx2%2Fv8QfaxRFP4l8dXBRJtYUU%3D' | gunzip | docker load)
        IMAGE_ID=$(echo $LOAD_MSG | awk '/./{line=$0} END{print line}' | cut -d " " -f 3 )             # parse image name as 3rd field in "Loaded image: xx" message
        docker tag $IMAGE_ID $CONJUR_IMAGE
  fi

  image_tag=$(docker images $CONJUR_IMAGE --format "{{.Tag}}")
  printf "Bringing up Conjur using image tagged as version %s...\n" $image_tag

  docker-compose up -d conjur-master
  docker-compose logs -f conjur-master
}

function finish {
  echo 'Removing docker environment'
  echo '---'
  docker-compose down -v
}
trap finish EXIT

main
