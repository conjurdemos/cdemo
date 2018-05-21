#!/bin/bash

main(){
  printf '\n-----'
  printf '\nCreating HF Token using local api and REST.\n'
  hftoken
  printf '\n-----\n'
}

hftoken(){
  local api=$(cat ~/.netrc | grep password | awk '{print $2}')
  local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
  local login=$(cat ~/.netrc | grep login | awk '{print $2}')
  local hf=jenkins
  printf "This is the API key = $api\n"
  local auth=$(curl -s -k -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/authn/$account/$login/authenticate)
  printf "\nThis is the auth token:\n"
  local auth_token=$(echo -n $auth | base64 | tr -d '\r\n') 
  echo $auth_token
  local hostfactory=$(curl -k -s -X POST --data-urlencode "host_factory=$account:host_factory:$hf" --data-urlencode "expiration=2065-08-04T22:27:20+00:00" -H "Authorization: Token token=\"$auth_token\"" https://conjur-master/api/host_factory_tokens)
  printf "\nThis is the hostfactory token:\n"
  echo $hostfactory | jq .
  printf "\nSaving HF token for use in file /hostfactoryTokens/"$hf"_hostfactory"
  echo $hostfactory > /hostfactoryTokens/$hf"_hostfactory" 
}

main
