#!/bin/bash

main(){
  printf '\n-----'
  printf '\nObtaining identity using hostfactory token.'
  hostfactory
}

hostfactory(){
  local token=$(cat /jenkins_api/hostfactory | jq '.[0] | {token}' | awk '{print $2}')

  local newIdentity=$(curl  -k -s -S --write-out '%{http_code}' -X POST --data-urlencode id=jenkins-$(openssl rand -hex 4) --header "Authorization: Token token=\"$token\"" https://conjur/host_factories/hosts)

  printf '\n-----'
  printf '\nHostfactory token:\n'
  printf $token
  printf '\nNew Identity:\n'
  printf $newIdentity
  printf '\n-----'
}

main
