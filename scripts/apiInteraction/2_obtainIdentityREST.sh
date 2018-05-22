#!/bin/bash

source utils.sh

main(){
  printf '\n-----'
  printf '\nObtaining identity using hostfactory token.'
  hostfactory
  printf '\n-----\n'
}

hostfactory(){
  local hftoken="jenkins"
  local id="jenkins-$(openssl rand -hex 2)"
  local token=$(cat /hostfactoryTokens/"$hftoken"_hostfactory | jq '.[0] | {token}' | awk '{print $2}' | tr -d '"\n\r')
  local newidentity=$(curl -k -X POST -s -H "Authorization: Token token=\"$token\"" --data-urlencode id=$id https://conjur-master/host_factories/hosts)

  printf "\nHostfactory token: $token"
  printf "\nNew host name in Conjur: $id"
  printf "\n"
  pause 'Press [ENTER] key to continue...'
  printf '\nNew Identity:\n'
  echo $newidentity | jq .
  printf "\nOutputing file to /identity/"$hftoken"_identity"
  echo $newidentity > /identity/"$hftoken"_identity
}

main
