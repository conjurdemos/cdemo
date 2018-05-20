#!/bin/bash
main(){
  printf '\n-----\n'
  printf '\nThis script will pull a password using summon.\n'
  summon_secret
}

summon_secret(){
  printf "\nGrabbing secret aws_access_key: $aws_secret\n"
}
main
