#!/bin/bash 


printf "\n\n\nExecuting within the container...\n\n"

# environment variables set by "docker run -e .."
# CONT_NAME - environment variable
# CONT_API_KEY - environment variable
# VAR_ID - environment variable name to fetch
# SLEEP_TIME - environment variable name to fetch


declare ENDPOINT=https://172.17.0.1/api 
# The endpoint for the host on the Mac is an alias for the lo0 network adapter
# see: https://docs.docker.com/docker-for-mac/networking/#per-container-ip-addressing-is-not-possible

declare CONT_SESSION_TOKEN
declare LOGFILE=cc.log

# for logfile to see whats going on
touch $LOGFILE

while [ 1=1 ]; do
	# Login container w/ its API key, authenticate and get API key for session
	cont_login=host%2F$CONT_NAME
	response=$(curl -s -k \
	 --request POST \
	 --data-binary $CONT_API_KEY \
	 $ENDPOINT/authn/users/{$cont_login}/authenticate)
	CONT_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

#echo "CONT_SESSION_TOKEN: " $CONT_SESSION_TOKEN >> $LOGFILE

	# FETCH variable value
	DB_PASSWORD=$(curl -s -k \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
         $ENDPOINT/variables/{$VAR_ID}/value)

  	echo $(date) "The DB Password is: " $DB_PASSWORD >> $LOGFILE
	sleep $SLEEP_TIME 
done

exit

# RESOURCE LIST 
RSRC_LIST=authz/{$CONT_NAME}/resources/variable
curl -k \
        -H "Content-Type: application/json" \
        -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
        $ENDPOINT/$RSRC_LIST

