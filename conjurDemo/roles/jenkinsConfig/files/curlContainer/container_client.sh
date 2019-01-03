#!/bin/bash 


printf "\n\n\nExecuting within the container...\n\n"

# environment variables set by "docker run -e .."
# CONJUR_AUTHN_LOGIN - Conjur Login ID
# CONJUR_AUTHN_API_KEY - Conjur API Key
# CONJUR_APPLIANCE_URL - Conjur Appliance URL
# CONJUR_ACCOUNT - Conjur Account name
# CONJUR_SSL_CERTIFICATE - Conjur public certificate
# CONJUR_VARIABLE - Variable to pull from conjur
# SLEEP_TIME - The amount of time between password pulls

secret_name=$(echo $CONJUR_VARIABLE | sed 's=/=%2F=g')
declare LOGFILE=cc.log

# for logfile to see whats going on
touch $LOGFILE

while [ 1=1 ]; do
	# Login container w/ its API key, authenticate and get API key for session
	hostname=host%2F$CONJUR_AUTHN_LOGIN
	echo "Hostname is $hostname"
	echo "API key is $CONJUR_AUTHN_API_KEY"
	echo "The Conjur Account is $CONJUR_ACCOUNT"
	echo "Pulling secret $CONJUR_VARIABLE"
	response=$(curl -s -k \
	 --request POST \
	 --data-binary $CONJUR_AUTHN_API_KEY \
	 $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/$hostname/authenticate)
	CONT_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
	secret=$(curl -s -k \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$secret_name)
	echo "The secret is $secret"
  	echo "$(date) The secret is: $secret" >> $LOGFILE
	sleep $SLEEP_TIME 
done

exit

