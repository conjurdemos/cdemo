#!/bin/bash

source ./utils.sh
VAR1=$1
main(){
  if [ "$VAR1" == "automate" ];
    then
      identity_jenkins
  else
    printf '\n-----'
    printf '\nObtaining identity using hostfactory token.'
    identity_interactive
    printf '\n-----\n'
  fi
}

main
