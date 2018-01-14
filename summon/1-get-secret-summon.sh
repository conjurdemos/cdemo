#!/bin/bash
CNAME=cdemo_vm_1
PROVIDER=/src/summon/conjur_summon_provider.sh
SECRETS=/src/summon/secrets.yml
APP=/src/summon/test.sh
docker exec -it $CNAME bash -c \
	"summon -p $PROVIDER -f $SECRETS $APP"
