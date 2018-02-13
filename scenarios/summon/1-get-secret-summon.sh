#!/bin/bash
CNAME=cdemo_vm_1
PROVIDER=/src/scenarios/summon/conjur_summon_provider.sh
SECRETS=/src/scenarios/summon/secrets.yml
APP=/src/scenarios/summon/test.sh
docker exec -it $CNAME bash -c \
	"summon -p $PROVIDER -f $SECRETS $APP"
