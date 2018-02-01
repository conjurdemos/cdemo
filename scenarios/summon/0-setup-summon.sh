#!/bin/bash 
set -eo pipefail

CONJUR_MASTER_ORGACCOUNT=dev
CONJUR_APPLIANCE_URL=https://conjur_follower/api
CONJUR_CERT_FILE=../../etc/conjur_follower.pem
CONJUR_CERT_FILE_ON_HOST=/etc/conjur_follower.pem
HOST_IMAGE=rack-vm:1.0
CNAME=cdemo_vm_1
HOSTNAME=webapp1/tomcat_host

				# start container - summon is already installed
docker-compose up -d vm 
				# copy over conjur.conf
cat <<CONF_EOF | docker exec -i $CNAME sudo tee /etc/conjur.conf
---
appliance_url: $CONJUR_APPLIANCE_URL
account: $CONJUR_MASTER_ORGACCOUNT
cert_file: "$CONJUR_CERT_FILE_ON_HOST"
plugins: []
CONF_EOF
				# copy over cert file
docker cp $CONJUR_CERT_FILE $CNAME:$CONJUR_CERT_FILE_ON_HOST

				# generate api key
docker exec conjur_cli conjur authn login -u bob -p foo
api_key=$(docker exec conjur_cli conjur host rotate_api_key --host $HOSTNAME)

				# copy over identity file
cat <<IDENTITY_EOF | docker exec -i $CNAME sudo tee /etc/conjur.identity
machine $CONJUR_APPLIANCE_URL
    login host/$HOSTNAME
    password $api_key
IDENTITY_EOF

