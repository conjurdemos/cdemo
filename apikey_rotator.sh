#!/bin/bash -e
set -o pipefail

APP_HOSTNAME=webapp1/tomcat_host

                        # rotate API key
                        # write new key to nondescript file in shared volume
api_key=$(docker-compose exec -T cli conjur host rotate_api_key --host $APP_HOSTNAME)
echo $api_key > local_foo
docker cp local_foo $(docker-compose ps -q cli):/data/foo
rm local_foo
