#!/bin/bash

main (){
  if [[ -v $1 ]];
  then
    rotate
  else
    echo "----"
    echo "This will rotate secret $1"
    rotate $1
  fi
}

rotate (){
  if [[ -v $1 ]];
  then
    local api=$(cat ~/.netrc | grep password | awk '{print $2}')
    local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
    local login=$(cat ~/.netrc | grep login | awk '{print $2}')
    echo "-----"
    echo "Authenticating with login name: $login"
    echo "Using API key: $api"
    echo "Using Account: $account"
    local newPass=$(openssl rand -hex 8)
    local secret="secrets/frontend/aws_access_key"
    echo "Changing secret $secret"
    docker exec conjur-cli bash -c "conjur variable values add $secret $newPass"
  else
    local api=$(cat ~/.netrc | grep password | awk '{print $2}')
    local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
    local login=$(cat ~/.netrc | grep login | awk '{print $2}')
    echo "-----"
    echo "Authenticating with login name: $login"
    echo "Using API key: $api"
    echo "Using Account: $account"
    local newPass=$(openssl rand -hex 8)
    local secret="secrets/frontend/aws_access_key"
    echo "Changing secret $secret"
    docker exec conjur-cli bash -c "conjur variable values add $secret $newPass"
  fi
}

main $1