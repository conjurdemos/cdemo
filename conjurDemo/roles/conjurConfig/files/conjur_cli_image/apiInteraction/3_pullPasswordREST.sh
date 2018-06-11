#!/bin/bash

source utils.sh

main(){
  printf '\n-----'
  printf '\nThis Script will pull a secret via REST.'
  secret_pull 
  printf '\n-----\n'
}

secret_pull(){
  printf "\nPlease select which identity file to use for password retrieval: \n"
  local identity=$(menu)
  printf "\nUsing identity stored in file /identity/"$identity"_identity"
  local conjurCert="/root/conjur-cyberark.pem"
  local api=$(cat /identity/"$identity"_identity | jq -r '.api_key')
  local hostname=$(cat /identity/"$identity"_identity | jq -r '.id' | awk -F: '{print $NF}')
  local secret_name="secrets/frontend/aws_access_key"
  local secret_url=$(urlify $secret_name) 
  printf "\nPulling secret: $secret_name"
  printf "\nUsing Conjur hostname: $hostname"
  printf "\nUsing API key: $api"
  local auth=$(curl -s --cacert $conjurCert  -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/authn/cyberark/host%2F$hostname/authenticate)
  local auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
  local secret_retrieve=$(curl --cacert $conjurCert -s -X GET -H "Authorization: Token token=\"$auth_token\"" https://conjur-master/secrets/cyberark/variable/$secret_name)
  printf "\n"
  pause 'Press [ENTER] key to continue...'
  printf "\nSecret is: $secret_retrieve" 
}

main
