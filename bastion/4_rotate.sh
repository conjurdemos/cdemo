#!/bin/bash -ex

# You can run this as many times as you want.

docker exec -it conjur_cli conjur variable expire --now root-key-rotators/bastion/private-key

sleep 5

docker exec -it conjur_cli conjur audit resource -s variable:root-key-rotators/bastion/private-key | grep rotator | grep reported
