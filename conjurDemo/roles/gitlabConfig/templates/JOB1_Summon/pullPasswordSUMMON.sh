#!/bin/bash

main(){
 summon_jenkins
}

summon_jenkins(){
  local api=$(cat /root/.netrc | grep password | awk '{print $2}')
  local account=$(cat /root/.conjurrc | grep account | awk '{print $2}')
  local login=$(cat /root/.netrc | grep login | awk '{print $2}')
  
  printf "Using Conjur login name: $login\n"
  printf "Using api: $api\n"
  printf "Using account: $account"
  printf "\nGrabbing secret aws_access_key: $aws_secret"  
}
main $1
