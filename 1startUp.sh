#!/bin/bash

main(){
  printf '\n-----'
  printf '\nInstalling dependencies'
  install_dependencies
  printf '\n-----\n'
}

install_dependencies(){
  printf '\nUpdating yum\n'
  yum update -y &> /dev/null
  printf '\nUpgrading system\n'
  yum upgrade -y &> /dev/null
  printf '\nInstalling EPEL repo\n'
  yum install epel-release -y &> /dev/null
  printf '\nUpdating Repolist\n'
  yum repolist &> /dev/null
  yum update -y &> /dev/null
  printf '\nInstalling Ansible\n'
  yum install ansible -y &> /dev/null
}
main
