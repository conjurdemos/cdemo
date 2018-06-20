#!/bin/bash

main(){
  printf '\n-----'
  printf '\nInstalling dependencies'
  if [[ $(cat /etc/*-release | grep -w ID_LIKE) == 'ID_LIKE="rhel fedora"' ]]; then
    install_ansible_yum
  elif [[ $(cat /etc/*-release | grep -w ID) == 'ID=debian' ]]; then
    install_ansible_apt
  else
    printf "\nCouldn't figure out OS"
  fi
  printf '\n-----\n'
}

install_ansible_yum(){
  printf '\nUpdating yum\n'
  sudo yum update -y &> /dev/null
  printf '\nUpgrading system\n'
  sudo yum upgrade -y &> /dev/null
  printf '\nInstalling EPEL repo\n'
  sudo yum install epel-release -y &> /dev/null
  printf '\nUpdating Repolist\n'
  sudo yum repolist &> /dev/null
  sudo yum update -y &> /dev/null
  printf '\nInstalling Ansible\n'
  sudo yum install ansible -y &> /dev/null
}

install_ansible_apt(){
  printf "\nInstalling dirmngr"
  sudo apt-get install dirmngr
  printf "\nInstalling source repo"
  echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' >> /etc/apt/sources.list
  printf "\nInstalling keyserver"
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
  printf "\nUpdating APT"
  sudo apt-get update -y
  printf "\nInstalling Ansible"
  sudo apt-get install ansible -y
}
main
