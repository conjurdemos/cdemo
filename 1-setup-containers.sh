#!/bin/bash -e
set -o pipefail

APP_HOSTNAME="webapp1/tomcat_host"
VAR_ID="webapp1/database_password"

################  MAIN   ################
# $1 = number of containers to create
# $2 = Sleep time in seconds between each secrets fetch
main() {
        if [[ $# -ne 2 ]] ; then
                printf "\n\tUsage: %s <num-containers> <sleep-time-between-fetches>\n\n" $0
                exit 1
        fi

        local NUM_CONTS=$1; shift
        local SLEEP_TIME=$1; shift
	
	rm -f .env
				# login in cli container as devops admin
	docker-compose exec -T cli conjur authn login -u bob -p foo

			# rotate API key
			# write new key to nondescript file in shared volume
	api_key=$(docker-compose exec -T cli conjur host rotate_api_key --host $APP_HOSTNAME)
	echo $api_key > local_foo
	docker cp local_foo $(docker-compose ps -q cli):/data/foo
	rm local_foo

			# replace '/' and ':' w/ hex equivalents
	urlify $APP_HOSTNAME
	APP_HOSTNAME=$URLIFIED
	urlify $VAR_ID
	VAR_ID=$URLIFIED

			# create .env file to set docker-compose env vars
	echo "APP_HOSTNAME=$APP_HOSTNAME" > .env
	echo "VAR_ID=$VAR_ID" >> .env
	echo "SLEEP_TIME=$SLEEP_TIME" >> .env
	docker-compose up -d --scale webapp=$NUM_CONTS webapp

			# delete file w/ api-key
	docker-compose exec -T cli rm /data/foo
}


# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        URLIFIED=$str
}

main "$@"
