#!/bin/bash

function pause(){
  read -p "$*"
}

function urlify(){
  local str=$1; shift
  str=$(echo $str | sed 's= =%20=g')
  str=$(echo $str | sed 's=/=%2F=g')
  str=$(echo $str | sed 's=:=%3A=g')
  URLIFIED=$str
}

function menu(){
  PS3='Please enter your choice: '
  options=("Jenkins" "Webapp" "Tomcat")
  select opt in "${options[@]}"
  do
    case $opt in
      "Jenkins")
        id=jenkins
        break
        ;;
      "Webapp")
        id=webapp
        break
        ;;
      "Tomcat")
        id=tomcat
        break
        ;;
    esac
  done
  echo $id       
}

identity_interactive(){
  printf "\nPlease select hostfactory token to use for identity generation:\n"
  local hftoken=$(menu)
  local id="$hftoken-$(openssl rand -hex 2)"
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

identity_jenkins(){
  local hftoken=jenkins
  local id="$hftoken-$(openssl rand -hex 2)"
  local token=$(cat /hostfactoryTokens/"$hftoken"_hostfactory | jq '.[0] | {token}' | awk '{print $2}' | tr -d '"\n\r')
  local newidentity=$(curl -k -X POST -s -H "Authorization: Token token=\"$token\"" --data-urlencode id=$id https://conjur-master/host_factories/hosts)
  local hostname=$(echo $newidentity | jq -r '.id' | awk -F: '{print $NF}')
  local api=$(echo $newidentity | jq -r '.api_key')
  cp /root/*.pem /identity/
  cp /root/.conjurrc /identity/.conjurrc
  echo "machine https://conjur-master/authn" > /identity/.netrc
  echo "  login host/$hostname" >> /identity/.netrc
  echo "  password $api" >> /identity/.netrc
}

hostfactory_interactive(){
  if [ ! -f ~/.netrc ];
    then
      echo "Can\'t find .netrc file in the home folder of user."
      echo "Please run conjur authn login"
      exit
  elif [ ! -f ~/.conjurrc ];
    then
      echo "Can\'t find .conjurrc file in the home folder of user."
      echo "Please run conjur init"
      exit    
  else
    local api=$(cat ~/.netrc | grep password | awk '{print $2}')
    local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
    local conjurCert="/root/conjur-cyberark.pem"
    local login=$(cat ~/.netrc | grep login | awk '{print $2}')
    printf "\nSelect hostfactory to create.\n"
    local hf=$(menu)	
    printf "Generating hostfactory for $hf.\n"
    printf "Using login = $login\n"
    printf "This is the API key = $api"
    local auth=$(curl -s --cacert $conjurCert -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/authn/$account/$login/authenticate)
    local auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
    local hostfactory=$(curl --cacert $conjurCert -s -X POST --data-urlencode "host_factory=$account:host_factory:$hf/nodes" --data-urlencode "expiration=2065-08-04T22:27:20+00:00" -H "Authorization: Token token=\"$auth_token\"" https://conjur-master/host_factory_tokens)
    printf "\n"
    pause 'Press [ENTER] key to continue...'
    printf "\nThis is the hostfactory token:\n"
    echo $hostfactory | jq .
    printf "\nSaving HF token for use in file /hostfactoryTokens/"$hf"_hostfactory"
    echo $hostfactory > /hostfactoryTokens/$hf"_hostfactory"
  fi
}

hostfactory_jenkins(){
  local api=$(cat ~/.netrc | grep password | awk '{print $2}')
  local account=$(cat ~/.conjurrc | grep account | awk '{print $2}')
  local conjurCert="/root/conjur-cyberark.pem"
  local login=$(cat ~/.netrc | grep login | awk '{print $2}')
  local hf=jenkins
  local auth=$(curl -s --cacert $conjurCert -H "Content-Type: text/plain" -X POST -d "$api" https://conjur-master/authn/$account/$login/authenticate)
  local auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
  local hostfactory=$(curl --cacert $conjurCert -s -X POST --data-urlencode "host_factory=$account:host_factory:$hf" --data-urlencode "expiration=2065-08-04T22:27:20+00:00" -H "Authorization: Token token=\"$auth_token\"" https://conjur-master/host_factory_tokens)
  echo $hostfactory > /hostfactoryTokens/$hf"_hostfactory"
}