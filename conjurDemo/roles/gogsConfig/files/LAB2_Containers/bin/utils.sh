#!/bin/bash

create_hftoken(){
  echo "grabbing api key"
  local api=$(cat ~/.netrc | grep password | awk '{print $2}')
  echo "api key is $api"
  echo "Grabbing account name"
  local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
  echo "Account name is $account"
  echo "grabbing certification"
  local conjurCert="/root/conjur-cyberark.pem"
  echo "certifcate is $conjurCert"
  echo "grabbing login name"
  local host_login=$(cat ~/.netrc | grep login | awk '{print $2}')
  echo "login name from file is $host_login"
  local login=$(echo $host_login | sed 's=/=%2F=g')
  echo "Login name is $login"
  echo "setting name of passed in variable $1"
  local hf=$1
  echo "getting auth token"
  local auth=$(curl -s --cacert $conjurCert -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/authn/$account/$login/authenticate)
  echo "preformatted auth token is"
  echo "====="
  echo "$auth"
  echo "====="
  local auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
  echo "====="
  echo "formatted auth token is:"
  echo "====="
  echo "$auth_token"
  echo "====="
  echo "getting hostfactory token"
  local hostfactory=$(curl --cacert $conjurCert -s -X POST --data-urlencode "host_factory=$account:host_factory:$hf/nodes" --data-urlencode "expiration=2065-08-04T22:27:20+00:00" -H "Authorization: Token token=\"$auth_token\"" https://conjur-master/host_factory_tokens)
  echo "hostfactory is $(echo $hostfactory | jq .)"
  create_identity $hostfactory $hf
}

create_identity(){
  echo "starting create identity with passed through variable:"
  echo "$(echo $1 | jq .)"
  local hftoken=$1
  echo "creating ID"
  local id="$2-$(openssl rand -hex 2)"
  echo "created id as $id"
  echo "generating token"
  local token=$(echo $hftoken | jq '.[0] | {token}' | awk '{print $2}' | tr -d '"\n\r')
  echo "token is $token"
  echo "generating new identity"
  local newidentity=$(curl -k -X POST -s -H "Authorization: Token token=\"$token\"" --data-urlencode id=$id https://conjur-master/host_factories/hosts)
  echo "new identity is $(echo $newidentity | jq . )"
  local hostname=$(echo $newidentity | jq -r '.id' | awk -F: '{print $NF}')
  local api=$(echo $newidentity | jq -r '.api_key')
  echo $( echo $newidentity | jq .) > "./$2.identity"
  echo "Revoking token $token"
  echo "grabbing api key"
  local api=$(cat ~/.netrc | grep password | awk '{print $2}')
  echo "api key is $api"
  echo "Grabbing account name"
  local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
  echo "Account name is $account"
  echo "grabbing certification"
  local conjurCert="/root/conjur-cyberark.pem"
  echo "certifcate is $conjurCert"
  echo "grabbing login name"
  local host_login=$(cat ~/.netrc | grep login | awk '{print $2}')
  echo "login name from file is $host_login"
  local login=$(echo $host_login | sed 's=/=%2F=g')
  echo "Login name is $login"
  echo "getting auth token"
  local auth=$(curl -s --cacert $conjurCert -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/authn/$account/$login/authenticate)
  echo "preformatted auth token is"
  echo "====="
  echo "$auth"
  echo "====="
  local auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
  echo "====="
  echo "formatted auth token is:"
  echo "====="
  echo "$auth_token"
  echo "====="
  local revocation=$(curl -s -i --cacert $conjurCert --request DELETE -H "Authorization: Token token=\"$auth_token\"" https://conjur-master/host_factory_tokens/$token)
  echo "Status of revocation"
  echo "====="
  echo "$revocation"
  echo "====="
  echo "Revoked token $token"
}

