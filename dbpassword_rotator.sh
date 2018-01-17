#!/bin/bash

. ./_loadcfg.sh

while [[ 1 == 1 ]]; do
	new_value=$(openssl rand -hex 12)
	msg=$(docker exec conjur_cli conjur variable values add $VAR_ID $new_value) 
	if [[ "$msg" == "Value added" ]]; then
		echo $(date "+%H:%M:%S") "$VAR_ID is now: $new_value"
	else
		echo $msg
	fi
	sleep 5
done
