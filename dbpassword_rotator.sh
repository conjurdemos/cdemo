#!/bin/bash
VAR_ID=webapp1/database_password

while [[ 1 == 1 ]]; do
	new_value=$(openssl rand -hex 12)
	msg=$(docker-compose exec -T cli conjur variable values add $VAR_ID $new_value) 
	if [[ "$msg" == "Value added" ]]; then
		echo $(date "+%H:%M:%S") "$VAR_ID is now: $new_value"
	else
		echo $msg
	fi
	sleep 5
done

while [[ 1 == 1 ]]; do
	new_pwd=$(openssl rand -hex 12)
	error_msg=$(conjur variable values add db/password $new_pwd 2>&1 >/dev/null)
	sleep 5
done
