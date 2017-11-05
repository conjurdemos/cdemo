#!/bin/bash
VAR_ID=webapp1/database_password

while [[ 1 == 1 ]]; do
	new_value=$(openssl rand -hex 12)
	docker-compose exec -T cli conjur variable values add $VAR_ID $new_value &> /dev/null
	echo $(date "+%H:%M:%S") "$VAR_ID is now: $new_value"
	sleep 5
done
