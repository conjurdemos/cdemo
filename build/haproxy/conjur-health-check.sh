#!/bin/bash
server_address=$3

# echo "server_address: " $server_address 

conjur_ok=$(curl -k -s https://$server_address/health | jq '.ok')
if [[ "$conjur_ok" == "true" ]]; then
  #	echo "Conjur is OK" 
	exit 0
fi
# echo "Conjur is NOT OK"
# echo "check status value:" $conjur_ok
exit -1
