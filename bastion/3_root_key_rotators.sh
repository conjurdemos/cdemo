#!/bin/bash -ex
set -eo pipefail
docker-compose exec cli conjur policy load --as-group security_admin /src/bastion/policy/root_key_rotators.yml
docker-compose exec cli conjur variable values add root-key-rotators/bastion/host bastion_server
docker-compose exec cli conjur variable values add root-key-rotators/bastion/login alice
docker exec -i outside_vm cat /home/alice/.ssh/id_rsa | docker exec -i conjur_cli conjur variable values add root-key-rotators/bastion/private-key
