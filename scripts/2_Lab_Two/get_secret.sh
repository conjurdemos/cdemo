#!/bin/bash

# get pointers to Conjur api and SSL certificate
source EDIT.ME
if [[ "$CONJUR_APPLIANCE_URL" = "" ]] ; then
        printf "\n\nEdit file EDIT.ME to set your appliance URL and certificate path.\n\n"
        exit 1
fi

# global variables
declare ADMIN_SESSION_TOKEN
declare HOST_API_KEY
declare HOST_SESSION_TOKEN
declare SECRET_VALUE
declare URLIFIED

declare DEBUG_BREAKPT=""
#declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

################
# REGISTER HOST to the associated layer using the host factory token
#    Note that if the host already exists, this command will create a new API key for it
# $1 - application name

hf_register_host() {
        local hf_token=$1; shift
        local host_name=$1; shift

        HOST_API_KEY=$( curl \
         -s \
         --cacert $CONJUR_CERT_FILE \
         --request POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$hf_token\"" \
         $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$host_name \
         | jq -r '.api_key')

}

################
# HOST AUTHN using its name and API key to get session token
# $1 - host name
# $2 - API key
host_authn() {
        local host_name=$1; shift
        local host_api_key=$1; shift

        urlify $host_name
        local host_name_urlfmt=host%2F$URLIFIED         # authn requires host/ prefix

        # Authenticate host w/ its name & API key to get session token
         response=$(curl -s \
         --cacert $CONJUR_CERT_FILE \
         --request POST \
         --data-binary $host_api_key \
         $CONJUR_APPLIANCE_URL/authn/users/{$host_name_urlfmt}/authenticate)
         HOST_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
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

        curl -s \
         --cacert $CONJUR_CERT_FILE \
        -H "Content-Type: application/json" \
        -H "Authorization: Token token=\"$HOST_SESSION_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/authz/{$host_name}/resources/variable
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

        hf_register_host $hf_token $host_name   # NOTE hostname not in URL format - sets HOST_API_KEY global value

        if [[ "$HOST_API_KEY" == "" ]]; then
                printf "\n\nAPI key not generated. Perhaps host factory token has expired. Please regenerate...\n\n"
                exit 1
        fi

        printf "\n\nAPI key for %s is: %s \n\n" $host_name $HOST_API_KEY
        read -n 1 -s -p "Press any key to continue"

        host_authn $host_name $HOST_API_KEY             # sets HOST_SESSION_TOKEN value

#       list_resources $host_name

        fetch_secret $var_id                            # sets SECRET_VALUE

        echo
        echo
        echo "Value for" $var_id "is:" $SECRET_VALUE
        echo
}

main "$@"
