#!/bin/bash
set -eo pipefail

# The point of this demo is that secrets can be securely fetched with a very lightweight client
# configuration (the summon executable, a certificate, the Conjur URL, a hostname and an API key).
# And then those secrets can be injected into a configuration file.

# This script flow is:
# - read host factory token, host name & variable name from a file (input parameter).
# - redeem host factory token for API key for the host
# - use that identity to fetch secret with summon
# - replace token in a Tomcat.xml.erb file with the fetched secret value
# - write the processed text to a file called temp.out. 

# get pointers to Conjur api and SSL certificate
export CONJUR_APPLIANCE_URL=https://conjur_master/api
export CONJUR_CERT_FILE=../../etc/conjur-dev.pem

# other env vars needed by summon/summon-conjur
export CONJUR_MAJOR_VERSION=4
export CONJUR_ACCOUNT=dev
export CONJUR_AUTHN_LOGIN=""
export CONJUR_AUTHN_API_KEY=""

# global variables
declare SECRET_VALUE
declare URLIFIED

################  MAIN   ################
# $1 - name of input file containing three lines for HF token, host name and name of variable to read

main() {
	if [[ $# -ne 1 ]] ; then
		printf "\n\tUsage: %s <filename>\n\n" $0
		exit 1
	fi
	local input_file=$1

	local hf_token host_name var_id

	local i=1
	while read line
	do
	    case $i in
		1) hf_token=$line
		   ;;
		2) host_name=$line
		   ;;
		3) var_id=$line
	    esac
	    (( i++ ))	
	done < "$input_file"

	printf "\n\nIn %s, using:\n\tHF token: %s\n\tto get API key for app: %s\n\tto fetch value of variable: %s\n" $0 $hf_token $host_name $var_id
	read -n 1 -s -p "Press any key to continue"

		# enrolls host in layer & sets CONJUR_AUTHN_API_KEY 
	redeem_hf_token $hf_token $host_name 		
	printf "\n\nAPI key for %s is: %s \n\n" $host_name $CONJUR_AUTHN_API_KEY
	read -n 1 -s -p "Press any key to continue"

	urlify $host_name
	CONJUR_AUTHN_LOGIN=host%2F$URLIFIED

				# call summon using host identity
	summon -p ./conjur_summon_provider.sh --yaml "DB_PWD: !var $var_id" ./process_template.sh
#summon -p ./conjur_summon_provider.sh -f ./secrets.yaml ./process_template.sh
}

################
# REDEEM_HF_TOKEN - enroll host to the associated layer using the host factory token 
#    Note that if the host already exists, this command will create a new API key for it 
# $1 - application name

redeem_hf_token() {
	local hf_token=$1; shift
	local host_name=$1; shift

					# note that host_name is NOT in URL format 
	local response_json=$(curl \
	 -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$hf_token\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$host_name)
	CONJUR_AUTHN_API_KEY=$(echo $response_json | jq -r '.api_key')

	if [[ "$CONJUR_AUTHN_API_KEY" == "" ]]; then
		printf "\n\nHost factory token has expired. Please regenerate...\n\n"
		exit 1
	fi
}

################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

		# authn requires host/hostname in URL format
		# replace any /-: in hostname and prepend w/ host%2F

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
	 --data-binary $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/users/{$CONJUR_AUTHN_LOGIN}/authenticate)
	 CONJUR_AUTHN_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
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

###############
# DEBUG OUT - prints values of environment variables used by Conjur API
#
debug_out() {
	printf "\n\nEnv vars used by summon-conjur:\n"
	printf "\tCONJUR_MAJOR_VERSION: %s\n" $CONJUR_MAJOR_VERSION
	printf "\tCONJUR_ACCOUNT: %s\n" $CONJUR_ACCOUNT
	printf "\tCONJUR_APPLIANCE_URL: %s\n" $CONJUR_APPLIANCE_URL
	printf "\tCONJUR_CERT_FILE: %s\n" $CONJUR_CERT_FILE
	printf "\tCONJUR_AUTHN_LOGIN: %s\n" $CONJUR_AUTHN_LOGIN
	printf "\tCONJUR_AUTHN_API_KEY: %s\n" $CONJUR_AUTHN_API_KEY
	printf "\tCONJUR_AUTHN_TOKEN: %s\n" $CONJUR_AUTHN_TOKEN
}

main $@
