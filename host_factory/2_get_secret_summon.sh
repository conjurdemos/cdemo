#!/bin/bash 

# this script reads a host factory token, a host name and a variable name from a file
# It uses the host factory token to create an API key for the host, then uses that identity 
# to fetch the value of the variable with summon-conjur
#
# It then replaces a token in a Tomcat.xml.erb file with the fetched secret value and writes
# the processed text to a file called temp.out. This demonstrates a DIY form of template processing.
#
# The point of this demo is that secrets can be securely fetched with a very lightweight client
# configuration (the summon-conjur executable, a certificate, the Conjur URL, a hostname and an API key).
# And then those secrets can be injected into a configuration file.

# get pointers to Conjur api and SSL certificate
source ./EDIT.ME
if [[ "$CONJUR_APPLIANCE_URL" = "" ]] ; then
	printf "\n\nEdit file EDIT.ME to set your appliance URL and certificate path.\n\n"
	exit 1
fi

# global variables
declare ADMIN_SESSION_TOKEN

# global variables
declare CONJUR_AUTHN_API_KEY
declare CONJUR_AUTHN_TOKEN
declare SECRET_VALUE
declare URLIFIED

################
# REGISTER HOST to the associated layer using the host factory token 
#    Note that if the host already exists, this command will create a new API key for it 
# $1 - application name

hf_register_host() {
	local hf_token=$1; shift
	local host_name=$1; shift

	local response_json=$(curl \
	 -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$hf_token\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$host_name)
	CONJUR_AUTHN_API_KEY=$(echo $response_json | jq -r '.api_key')
}

################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

	urlify $host_name
	local host_name_urlfmt=host%2F$URLIFIED		# authn requires host/ prefix

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
	 --data-binary $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/users/{$host_name_urlfmt}/authenticate)
	 CONJUR_AUTHN_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
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

# LIST RESOURCES accessible to application
# in: host_name
list_resources() {
	local host_name=$1; shift
	local host_name_urlfmt

	curl -s \
	 --cacert $CONJUR_CERT_FILE \
        -H "Content-Type: application/json" \
        -H "Authorization: Token token=\"$CONJUR_AUTHN_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/authz/{$host_name}/resources/variable
}

###############
# DEBUG OUT - prints values of environment variables used by summon-conjur
#
debug_out() {
	printf "\n\nCONJUR_APPLIANCE_URL: %s\n" $CONJUR_APPLIANCE_URL
	printf "CONJUR_CERT_FILE: %s\n" $CONJUR_CERT_FILE
	printf "CONJUR_AUTHN_LOGIN: %s\n" $CONJUR_AUTHN_LOGIN
	printf "CONJUR_AUTHN_API_KEY: %s\n" $CONJUR_AUTHN_API_KEY
	printf "CONJUR_AUTHN_TOKEN: %s\n" $CONJUR_AUTHN_TOKEN
}

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
		1)
			hf_token=$line
			;;
		2)
			host_name=$line
			;;
		3)
			var_id=$line
		esac
		(( i++ ))	
	done < "$input_file"

	printf "\n\nIn worker process, using:\n\tHF token: %s\n\tto get API key for app: %s\n\tto fetch value of variable: %s\n" $hf_token $host_name $var_id
	read -n 1 -s -p "Press any key to continue"

	export CONJUR_AUTHN_LOGIN=$host_name

	hf_register_host $hf_token $host_name 		# NOTE NOT URL FORMAT - sets CONJUR_AUTHN_API_KEY value

	if [[ "$CONJUR_AUTHN_API_KEY" == "" ]]; then
		printf "\n\nHost factory token has expired. Please regenerate...\n\n"
		exit 1
	fi

	printf "\n\nAPI key for %s is: %s \n\n" $host_name $CONJUR_AUTHN_API_KEY
	read -n 1 -s -p "Press any key to continue"

	host_authn $host_name $CONJUR_AUTHN_API_KEY  		# sets CONJUR_AUTHN_TOKEN value

#	list_resources $host_name

	unset CONJUR_AUTHN_TOKEN				# work around a summon-conjur bug
	debug_out
	SECRET_VALUE=$(summon-conjur $var_id)			# call summon-conjur using host identity
	urlify "$SECRET_VALUE"
	SECRET_VALUE=$URLIFIED

	echo
	echo
	echo "Value for" $var_id "is:" $SECRET_VALUE
	echo
	read -n 1 -s -p "Press any key to continue"

	TEMPLATE=tomcat.xml.erb
	printf -v SED_STRING "s=@database_password=%s=g" $SECRET_VALUE
	OUTPUT=$(cat $TEMPLATE)
	OUTPUT1=$(sed $SED_STRING <<< "$OUTPUT")
	echo "$OUTPUT1" > temp.out

	echo
	echo
	echo "Contents of processed template:"
	cat $"temp.out"
	echo
}
 
main "$@"
exit
