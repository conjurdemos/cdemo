#!/bin/bash

source ./utils.sh

VAR1=$1

main(){
  if [[ "$VAR1" == "automate" ]];
  then
    hostfactory_jenkins
  else
    printf '\n-----'
    printf '\nCreating HF Token using local api and REST.\n'
    hostfactory_interactive
    printf '\n-----\n'
  fi
}

main