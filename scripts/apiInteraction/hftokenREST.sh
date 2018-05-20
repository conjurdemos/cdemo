#!/bin/bash

main(){
  printf '\n-----'
  printf '\nCreating HF Token using local api and REST.'
  hftoken
}

hftoken(){
  local api=$(cat ~/.netrc | grep password | awk '$1=="password"{print $2}')
  printf "This is the API key = $api\n"
  local auth_token=$(curl -s -k -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/api/authn/users/jenkins-master/authenticate)
}


main
