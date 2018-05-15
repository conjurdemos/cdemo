#!/bin/bash 
#
# This script assumes a policy is already loaded to create layer, host factory and secrets.
# Setups up N (arg $1) containers with API keys using a hostfactory token that expires after S ($2) number of seconds.
# It runs the entry point script in each container to fetch secrets every F (arg $3) seconds

# get pointers to Conjur api and SSL certificate
source EDIT.ME
if [[ "$CONJUR_APPLIANCE_URL" = "" ]] ; then
	printf "\n\nEdit file EDIT.ME to set your appliance URL and certificate path.\n\n"
	exit 1
fi

# date and time math are not portable - set DATE_SPEC to the correct platform
MAC_DATE='date -v+"$dur_time_secs"S +%Y-%m-%dT%H%%3A%M%%3A%S%z'
LINUX_DATE='date --iso-8601=seconds --date="$dur_time_secs seconds"'
DATE_SPEC=$LINUX_DATE

#####
# values to send to worker_process
declare HOST_FACTORY_NAME=webapp1/tomcat_factory
declare VAR_ID=webapp1/database_password 
######

# global variables
declare ADMIN_SESSION_TOKEN
declare HF_TOKEN
declare CONT_API_KEY
declare URLIFIED

#declare DEBUG_BREAKPT=""
declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

# user_auth - authenticates user/pwd and sets global ADMIN_SESSION_TOKEN
# - no args
# 
user_authn() {
	printf "\nEnter admin user name: "
	read admin_name
	printf "Enter the admin password (it will not be echoed): "
	read -s admin_pwd

	# Login user, authenticate and get API key for session
	local access_token=$(curl \
				 -s \
				--cacert $CONJUR_CERT_FILE \
				--user $admin_name:$admin_pwd \
				$CONJUR_APPLIANCE_URL/authn/users/login)

	local response=$(curl -s \
			--cacert $CONJUR_CERT_FILE  \
			--data $access_token \
			$CONJUR_APPLIANCE_URL/authn/users/$admin_name/authenticate)
	ADMIN_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

}

# LIST ALL host factories
#
hf_list_all() {
	curl \
	$CURL_DEBUG \
	--cacert $CONJUR_CERT_FILE \
     	--request GET \
     	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
	$CONJUR_APPLIANCE_URL/authz/account/resources/host_factory
}

################
# Show host factory metadata
# $1 - hf_id
hf_show() {
	local hf_id=$1; shift
	curl \
	 $CURL_DEBUG \
	 --cacert $CONJUR_CERT_FILE \
     	 --request GET \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/{$hf_id}
}

################
# HOST FACTORY CREATE a new HF token with a defined expiration date
# $1 - host factory id
# $2 - dur time - hf token lifespan in seconds
hf_create() {
	local hf_id=$1; shift
	local dur_time_secs=$1; shift

	local token_exp_time=$(eval $DATE_SPEC)

	printf "\n\nToken exp time= %s\n" $token_exp_time

	HF_TOKEN=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
      	 --request POST \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/{$hf_id}/tokens?expiration=$token_exp_time \
	 | jq -r '.[] | .token')
}

################
# ADD HOST to the associated layer using the host factory token (NOT the Admin session token as in previous commands)
#    Note that if the host already exists, this command will create a new API key for it, requiring the host be updated as well
# $1 - container name
hf_add_host() {
	local cont_name=$1; shift
	CONT_API_KEY=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$HF_TOKEN\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$cont_name \
	 | jq -r '.api_key')
}

################
# DELETE (revoke) the host factory token
hf_revoke() {
	curl \
	 -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request DELETE \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$AUTHN_TOKEN\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/tokens/$CONJUR_HOST_FACTORY_TOKEN
}

################
# START CONTAINER start a container, w/ the API key as an environment variable and copy over the cert for SSL
# $1 - container name
# API key is a global variable because bash functions dont return values
# $2 - variable id for container to fetch
# $3 - sleep time (secs) between fetches
start_container() {
	local cont_name=$1; shift
	local var_id=$1; shift
	local sleep_time=$1; shift

	local cont_entry_pt=/root/container_client.sh

	docker run -dit --name $cont_name \
	 --entrypoint $cont_entry_pt \
	 -e CONT_API_KEY=$CONT_API_KEY \
	 -e CONT_NAME=$cont_name \
	 -e VAR_ID=$var_id \
	 -e SLEEP_TIME=$sleep_time \
	cdemo/curl > /dev/null
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

################  MAIN   ################
# $1 = number of containers to create
# $2 = HF token lifetime in seconds
# $3 = Sleep time in seconds between each secrets fetch
main() {
	if [[ $# -ne 3 ]] ; then
		printf "\n\tUsage: %s <num-containers> <hf-token-duration-in-seconds> <sleep-time-between-fetches>\n\n" $0
		exit 1
	fi

	local num_containers=$1; shift
	local hf_dur_time=$1; shift
	local sleep_time=$1; shift

	local hf_id=$HOST_FACTORY_NAME
	local hf_id_urlfmt
	local var_id=$VAR_ID
	local var_id_urlfmt

	urlify $hf_id			# sets URLIFIED
	hf_id_urlfmt=$URLIFIED

	urlify $var_id			# sets URLIFIED
	var_id_urlfmt=$URLIFIED

	user_authn			# sets ADMIN_SESSION_TOKEN 
#	hf_list_all
#	hf_show $hf_id_urlfmt

	hf_create $hf_id_urlfmt $hf_dur_time		# sets HF_TOKEN

	printf "\nHost factory token: %s\n\n" $HF_TOKEN

	for (( c=1; c<=$num_containers; c++ ))
	do
		local cont_name="cont-$c"
		hf_add_host $cont_name			# sets CONT_API_KEY
		printf "Starting container %s with API key %s.\n" $cont_name $CONT_API_KEY
		start_container $cont_name $var_id_urlfmt $sleep_time
	done
}
 
main "$@"
exit

#######################################################3
# extra stuff

# Login container w/ its API key, authenticate and get API key for session
CONT_LOGIN=host%2F$CONT_NAME
AUTHN=authn/users/{$CONT_LOGIN}/authenticate
RESPONSE=$(curl --cacert $CONJUR_CERT_FILE  \
	 $CURL_DEBUG \
	--request POST \
	--data-binary $CONT_API_KEY \
	$CONJUR_APPLIANCE_URL/$AUTHN)
CONT_SESSION_TOKEN=$(echo -n $RESPONSE | base64 | tr -d '\r\n')

# RESOURCE LIST 
RSRC_LIST=authz/{$CONT_NAME}/resources/variable
curl --cacert $CONJUR_CERT_FILE \
	 $CURL_DEBUG \
        -H "Content-Type: application/json" \
        -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/$RSRC_LIST

# FETCH variable value
VAR_ID=jody%2Fv1%2Fdb-password
GET_VALUE=variables/{$VAR_ID}/value
DB_PASSWORD=$(curl  -k \
	 $CURL_DEBUG \
        --request GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/$GET_VALUE)

echo "The DB Password is: " $DB_PASSWORD

