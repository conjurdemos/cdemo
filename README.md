# Cyberark Conjur Enterprise demonstration environment

This will set up a new demo environment that will show off the features of a Conjur Enterprise in conjunction with common devops tools.  The tools are all docker containers that are all mapped to the same docker network to all for DNS resolution of the docker container name.

## Conjur Appliance

The demo uses the lastest version of Conjur v5

## DevOps tools

* Docker
* Ansible
* Jenkins
* GitLab
* AWX
* Conjur CLI 
* Conjur Enterprise v5
* Weavescope

## How to use

1. Clone the repo.
2. Obtain the latest Conjur tar file and place it within the cDemo directory named 'conjur.tar'.
3. Run 1startUp.sh.
4. Change directory to ansibleConjurDemo.
5. Edit inventory.yml to include any machines to be stood up as demo machines.
6. Run ansible-playbook -i inventory.yml site.yml

## Requirements

1. Centos 7 OS
2. Internet Connection
3. 4 vCPU
4. 8 GB Ram
5. 32 GB hdd space at minimum

## Access WEB interfaces

The tools installed have a web interfaces that is made accessible to the host machine on the following network ports:

|    Tool    	| Port 	|
|:----------:	|------	|
|   Jenkins  	| 8080 	|
|   GitLab   	| 7070 	|
|     AWX    	| 80   	|
| Conjur     	| 443  	|
| Weavescope 	| 4040 	|

## Pipeline jobs in Jenkins

Jenkins is configured to skip the start up wizard. There is a shared volume between the conjur-cli container and the jenkins container that contains a hostfactory token that does not expire for 9999 days. 

Jobs:
1. Install Identity into Jenkins environment using hostfactory token
2. Use summon to pull back a secret
