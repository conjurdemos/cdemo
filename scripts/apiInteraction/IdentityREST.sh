#!/bin/bash

main(){
  printf '\n-----'
  printf '\nObtaining identity using hostfactory token.\n'
  hostfactory
}

hostfactory(){
  local hftoken="jenkins"
  local token=$(cat /hostfactoryTokens/"$hftoken"_hostfactory | jq '.[0] | {token}' | awk '{print $2}' | tr -d '"\n\r')
  local id="jenkins-$(openssl rand -hex 2)"
  local newidentity=$(curl -k -X POST -s -H "Authorization: Token token=\"$token\"" --data-urlencode id=jenkins-$(openssl rand -hex 2) https://conjur-master/host_factories/hosts)

  printf '\n-----'
  printf '\nHostfactory token:\n'
  printf $token
  printf '\nHost name:\n'
  printf $id
  printf '\nNew Identity:\n'
  echo $newidentity | jq .
  printf "\nOutputing file to /idenfity/"$hftoken"_identity"
  echo $newidentity > /identity/"$hftoken"_identity
  printf '\n-----\n'
}

main
