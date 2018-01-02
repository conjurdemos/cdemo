#!/bin/bash
set -eo pipefail

# authn creds exported as environment variables from caller
# CONJUR_APPLIANCE_URL
# CONJUR_CERT_FILE
# CONJUR_AUTHN_LOGIN
# CONJUR_AUTHN_API_KEY

# global variables
declare ADMIN_SESSION_TOKEN
declare HOST_API_KEY
declare HOST_SESSION_TOKEN
declare SECRET_VALUE
declare URLIFIED

declare DEBUG_BREAKPT=""
#declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

################  MAIN   ################
# $1 - name of variable to retrieve

main() {
	if [[ $# -ne 1 ]] ; then
		printf "\n\tUsage: %s <variable-name>\n\n" $0
		exit 1
	fi
	var_id=$1

	host_authn $CONJUR_AUTHN_LOGIN $CONJUR_AUTHN_API_KEY  # sets HOST_SESSION_TOKEN value

	fetch_secret $var_id				# sets SECRET_VALUE

	echo $SECRET_VALUE
}


################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
	 --data-binary $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/users/{$host_name}/authenticate)
	 HOST_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
}

################
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

################
# FETCH SECRET using session token
# $1 - name of secret to fetch
fetch_secret() {
	local var_id=$1; shift

	urlify $var_id
	local var_id_urlfmt=$URLIFIED

	# FETCH variable value
	SECRET_VALUE=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$HOST_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/variables/{$var_id_urlfmt}/value)
}

main $@
