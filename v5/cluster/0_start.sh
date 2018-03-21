#!/bin/bash -ex

function finish {
  echo 'Removing docker environment'
  echo '---'
  docker-compose down -v
}
trap finish EXIT

function main {
  docker-compose up -d conjur-master
  docker-compose logs -f conjur-master
}

main
