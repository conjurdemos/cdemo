#!/bin/bash

# get pointers to Conjur api and SSL certificate
export CONJUR_APPLIANCE_URL=https://conjur_master/api
export CONJUR_CERT_FILE=../../etc/conjur-dev.pem

### HARD CODED VALUES ###
declare HOST_FACTORY_NAME=webapp1/tomcat_factory
######

# global variables
declare ADMIN_SESSION_TOKEN
declare URLIFIED

declare DEBUG_BREAKPT=""
#declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

##################
# USER AUTHN - get admin session token based on user name and password
# - no arguments
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

################
# LIST ALL HF TOKENS - list all tokens for a host factory
# in: host factory id
# out: TOKENS array (global)
hf_tokens_get() {
        local hf_id=$1; shift

        HF_TOKENS=$( curl \
        -s \
        --cacert $CONJUR_CERT_FILE \
        --header "Content-Type: application/json" \
        --header "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/host_factories/{$hf_id} \
        | jq -r ' .tokens ' )
}


################ 
# HOST FACTORY TOKEN REVOKE (delete) the host factory token
hf_token_revoke() {
        local hf_token=$1; shift
        curl \
         -s \
         --cacert $CONJUR_CERT_FILE \
         --request DELETE \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factories/tokens/$hf_token
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
# 

main() {
	user_authn

        urlify $HOST_FACTORY_NAME
        HOST_FACTORY_NAME=$URLIFIED

	hf_tokens_get $HOST_FACTORY_NAME  # sets HF_TOKENS
        printf "\nHost factory %s:\n" $HOST_FACTORY_NAME
	echo $HF_TOKENS | jq -r '.[]'
	TOKENS=$(echo $HF_TOKENS | jq -r ' .[] | .token')

	for tkn in $TOKENS; do
		printf "Revoking token: %s\n" $tkn
		hf_token_revoke $tkn
	done

}
 
main "$@"
