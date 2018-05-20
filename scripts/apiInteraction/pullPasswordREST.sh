#!/bin/bash

main(){
  printf '\n-----'
  printf '\nThis Script will pull a secret via REST using an identity stored in "/identity".'
  secret_pull 
}

secret_pull(){
  local identity=jenkins
  local conjurCert="/root/conjur-cyberark.pem"
  local api=$(cat /identity/"$identity"_identity | jq -r '.api_key')
  local hostname=$(cat /identity/"$identity"_identity | jq -r '.id' | awk -F: '{print $NF}')
  local secret_name="shared_secret_auth/aws_access_key"
  local secret_url=$(urlify $secret_name) 
  printf '\nPulling secret: aws_access_key'
  printf "\nUsing hostname: $hostname"
  printf "\nUsing API key: $api"
  local auth=$(curl -s --cacert $conjurCert  -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/authn/cyberark/host%2F$hostname/authenticate)
  local auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
  printf '\nAuthentication token is:\n'
  echo $auth_token  
  local secret_retrieve=$(curl --cacert $conjurCert -s -X GET -H "Authorization: Token token=\"$auth_token\"" https://conjur-master/secrets/cyberark/variable/$secret_name)
  printf "\nSecret is: $secret_retrieve\n" 
}

urlify(){
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        URLIFIED=$str
}

main
