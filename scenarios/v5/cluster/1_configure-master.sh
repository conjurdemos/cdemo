#!/bin/bash -ex

docker-compose exec conjur-master \
  evoke configure master -h conjur-master -p secret demo
