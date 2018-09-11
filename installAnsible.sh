#!/bin/bash

set -eu

function separator() {
    echo "-----"
}

function install_ansible_yum() {
    echo "Updating yum"
    sudo yum update -y &> /dev/null
    echo "Upgrading system"
    sudo yum upgrade -y &> /dev/null
    echo "Installing EPEL repo"
    sudo yum install epel-release -y &> /dev/null
    echo "Updating Repolist"
    sudo yum repolist &> /dev/null
    sudo yum update -y &> /dev/null
    echo "Installing Ansible"
    sudo yum install ansible -y &> /dev/null
}

function install_ansible_apt() {
    echo "Installing dirmngr"
    sudo apt-get install dirmngr
    echo "Installing source repo"
    echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' >> /etc/apt/sources.list
    echo "Installing keyserver"
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    echo "Updating APT"
    sudo apt-get update -y
    echo "Installing Ansible"
    sudo apt-get install ansible -y
}

bin/check-network
separator
echo 'Installing dependencies'
if [[ $(cat /etc/*-release | grep -w ID_LIKE) == 'ID_LIKE="rhel fedora"' ]]; then
    install_ansible_yum
elif [[ $(cat /etc/*-release | grep -w ID) == 'ID=debian' ]]; then
    install_ansible_apt
else
    echo "This script cannot install Ansible automatically"
    echo "on your operating system. Please figure out how to"
    echo "do so, then submit a patch to add support."
    echo "Thank you!"
    echo "-maintainer"
    echo "https://github.com/conjurdemos/cdemo/blob/master/installAnsible.sh"
fi
separator
printf "\n"
