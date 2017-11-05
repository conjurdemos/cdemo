#!/bin/bash 

printf "\n\n\nExecuting within the container...\n\n"

# environment variables set in .env file
# APP_HOSTNAME - host identity for all instances of this app
# VAR_ID - environment variable name to fetch
# SLEEP_TIME - environment variable name to fetch

CONJUR_HOST=conjur
declare ENDPOINT=https://$CONJUR_HOST/api
declare LOGFILE=cc.log
declare INPUT_FILE=/data/foo

# for logfile to see whats going on
touch $LOGFILE

OLD_APP_API_KEY=""
while [ 1=1 ]; do

		# get API key from file in shared volume
    while : ; do
	read APP_API_KEY < $INPUT_FILE
	if [[ "$APP_API_KEY" != "$OLD_APP_API_KEY" ]]; then
	   break
	else
	   sleep 2
	fi
    done
    echo "New API key is:" $APP_API_KEY >> $LOGFILE

    while [ 1=1 ]; do
	# Login container w/ its API key, authenticate and get API key for session
	cont_login=host%2F$APP_HOSTNAME
	response=$(curl -s -k \
	 --request POST \
	 --data-binary $APP_API_KEY \
	 $ENDPOINT/authn/users/{$cont_login}/authenticate)
	CONT_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

	if [[ "$CONT_SESSION_TOKEN" == "" ]]; then
	    echo "API key is invalid..." >> $LOGFILE
	    OLD_APP_API_KEY=$APP_API_KEY
	    break
	fi

	# FETCH variable value
	DB_PASSWORD=$(curl -s -k \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
         $ENDPOINT/variables/{$VAR_ID}/value)

  	echo $(date) "The DB Password is: " $DB_PASSWORD >> $LOGFILE
	sleep $SLEEP_TIME 
    done
done

exit

