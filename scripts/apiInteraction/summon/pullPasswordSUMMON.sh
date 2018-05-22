#!/bin/bash

source ../utils.sh

main(){
  printf '\n-----'
  printf '\nThis script will pull a password using summon.\n'
  summon_secret
  printf '\n-----\n'
}

summon_secret(){
  local api=$(cat ~/.netrc | grep password | awk '{print $2}')
  local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
  local login=$(cat ~/.netrc | grep login | awk '{print $2}')
  
  printf "Using Conjur login name: $login\n"
  printf "Using api: $api\n"
  printf "Using account: $account"
  printf "\n"
  pause 'Press [ENTER] key to continue...'
  printf "\nGrabbing secret aws_access_key: $aws_secret"

}
main
