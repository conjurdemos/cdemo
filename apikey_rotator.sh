#!/bin/bash
set -eo pipefail

APP_HOSTNAME=webapp1/tomcat_host

		# rotate api key for host
api_key=$(docker exec conjur_cli \
			conjur host rotate_api_key --host $APP_HOSTNAME)

		# if no arg provided
if [[ "$1" == "" ]]; then
		# write new key to nondescript file in shared volume
	echo $api_key | docker exec -i conjur_cli bash -c "tee > /data/foo"
	sleep 5
	docker-compose exec cli rm /data/foo
fi
