#!/bin/bash -ex

docker-compose up -d conjur-follower

docker exec cdemo_conjur-master bash -c "evoke seed follower conjur-follower > tmp/seeds/follower-seed.tar"

docker-compose exec conjur-follower \
  evoke unpack seed /tmp/seeds/follower-seed.tar

docker-compose exec conjur-follower \
  evoke configure follower
