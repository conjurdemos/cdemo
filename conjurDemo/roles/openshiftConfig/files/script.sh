#!/bin/bash
main (){
while [ 1=1 ]; do
	echo "Pulling secret $SECRET"
	response=$(cat /run/conjur/conjur-access-token)
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
}
main