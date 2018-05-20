#!/bin/bash

main(){
  printf '\n-----'
  printf '\nCreating HF Token using conjur cli'
  hftoken
}

hftoken(){
  printf '\nCreation hostfactory token for Tomcat hosts.'
  local tomcat_token=$(conjur hostfactory tokens create --duration-days=9999 tomcat)
  printf '\nHostfactory token created for tomcat hosts:\n'
  echo $tomcat_token | jq .
  printf 'Saving output into tomcat_hostfactory file.\n'
  echo $tomcat_token > /hostfactoryTokens/tomcat_hostfactory

  printf '\nCreation of hostfactory token for Webapp hosts.'
  local webapp_token=$(conjur hostfactory tokens create --duration-days=9999 webapp)
  printf '\nHostfactory token created for Webapp hosts:\n'
  echo $webapp_token | jq .
  printf 'Saving output into webapp_hostfactory file.\n'
  echo $webapp_token > /hostfactoryTokens/webapp_hostfactory
}

main
