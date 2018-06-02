#!/bin/bash

main (){
  echo "starting docker containers"
  local conjur_authn_api_key=$(cat $1.identity | jq -r '.api_key')
  local conjur_authn_login=$(cat $1.identity | jq -r '.id' | awk -F: '{print $NF}' | sed 's=/=%2F=g')
  local conjur_account='cyberark'
  local conjur_appliance_url='https://conjur-master'
  local conjur_variable=$2
  local sleep_time=5
  echo "API key = $conjur_authn_api_key"
  echo "Login = $conjur_authn_login"
  echo "conjur Account=$conjur_account"
  echo "conjur appliance url = $conjur_appliance_url"
  echo "conjur variable name= $conjur_variable"
  echo "sleep time= $sleep_time"
  
  count=1
  while [ $count -le $3 ]
  do
    docker container run -d --name "$1-$(openssl rand -hex 4)" --network conjur --entrypoint /root/container_client.sh -e CONJUR_AUTHN_LOGIN=$conjur_authn_login -e CONJUR_AUTHN_API_KEY=$conjur_authn_api_key -e CONJUR_APPLIANCE_URL=$conjur_appliance_url -e CONJUR_ACCOUNT=$conjur_account -e CONJUR_VARIABLE=$conjur_variable -e SLEEP_TIME=$sleep_time curl_image
    (( count++ ))
  done
}

main $1 $2 $3