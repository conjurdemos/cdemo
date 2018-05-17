# Cyberark Conjur Enterprise demonstration environment
This will set up a new demo environment that will show off the features of a Conjur Enterprise in conjunction with common devops tools.  The tools are all docker containers that are all mapped to the same docker network to all for DNS resolution of the docker container name.

## Conjur Appliance
The demo uses the lastest version of Conjur v5

## DevOps tools
* Docker
* Ansible
* Jenkins
* GitLab
* Conjur CLI 

## How to use

1. Clone the repo
2. Obtain the latest Conjur tar file and place it within the cDemo directory
3. Run 1startUp.sh
4. Run ansible-playbook standUpEnvironment.yaml

## Requirements

1. Centos 7 OS
2. Internet Connection
3. 2 vCPU
4. 8 GB Ram
5. 32 GB hdd space at minimum
