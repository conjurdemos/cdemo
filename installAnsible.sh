#!/bin/bash 

main(){
  printf '\n-----'
  printf '\nInstalling dependencies'
  id_string=$(cat /etc/*-release | grep -w ID_LIKE)
  case $id_string in
  'ID_LIKE="fedora"')
    # this case is for RHEL7
    sudo subscription-manager repos --enable rhel-7-server-extras-rpms
    install_ansible_yum
    ;;
  'ID_LIKE="rhel fedora"')
    # this case is for CentOS
    install_ansible_yum
    ;;
  'ID=debian')
    install_ansible_apt
    ;;
  *)
    printf "\nCouldn't figure out OS"
  esac
  printf '\n-----\n'
}

install_ansible_yum(){
  printf '\nUpdating yum\n'
  sudo yum update -y 
  printf '\nUpgrading system\n'
  sudo yum upgrade -y 
  printf '\nInstalling EPEL repo\n'
  sudo yum install epel-release -y 
  printf '\nUpdating Repolist\n'
  sudo yum repolist 
  sudo yum update -y 
  printf '\nInstalling Ansible\n'
  sudo yum install ansible -y 
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
