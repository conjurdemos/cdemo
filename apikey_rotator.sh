#!/bin/bash
set -eo pipefail

. ./etc/_loadcfg.sh

if [[ $# == 0 ]]; then
	echo "Usage: $0 <-r|-x>"
	echo "  -r      Rotate API key and provide to hosts"
	echo "  -x      Rotate API key for zero trust scenario"
	exit -1
fi

		# rotate api key for host
api_key=$(docker exec conjur_cli \
			conjur host rotate_api_key --host $APP_HOSTNAME)

		# if no arg provided
if [[ "$1" == "-r" ]]; then
		# write new key to nondescript file in shared volume
	echo $api_key | docker exec -i conjur_cli bash -c "tee > /data/foo"
	sleep 5
	docker-compose exec cli rm /data/foo
fi
