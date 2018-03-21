#!/bin/bash -ex

docker-compose up -d conjur-standby

docker exec cdemo_conjur-master bash -c "evoke seed standby > tmp/seeds/standby-seed.tar"

docker-compose exec conjur-standby \
  evoke unpack seed /tmp/seeds/standby-seed.tar

docker-compose exec conjur-standby \
  evoke configure standby
