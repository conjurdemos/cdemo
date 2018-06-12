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
    * If no tar file is located then a check for conjur docker registry access happens. If regsitry access comes back as successful then the latest version is pulled directly from the registry.
3. Run installAnsible.sh.
4. Change directory to conjurDemo.
5. Edit inventory.yml to include any machines to be stood up as demo machines.
6. Run ansible-playbook -i inventory.yml site.yml to install conjur and it's tools.
    * Conjur alone can be configured by running ansible-playbook -i inventory.yml conjurSetup.yml

## Conjur CLI information

The cli has been configured to work with the Conjur container.  It has the scripts folder mapped to /scripts.

## Requirements

1. Centos 7 OS
2. Internet Connection
3. 4 vCPU
4. 8 GB Ram
5. 32 GB hdd space at minimum
6. Ansible v2.5

## Access WEB interfaces

The tools installed have a web interfaces that is made accessible to the host machine on the following network ports:

|    Tool    	| Port 	|
|:----------:	|------	|
|   Jenkins  	| 8080 	|
|   GitLab   	| 7070 	|
|     AWX    	| 80   	|
| Conjur     	| 443  	|
| Weavescope 	| 4040 	|

## Default Credentials
* Jenkins - No credentials needed right now
* Conjur - U: admin P: Cyberark1
* Conjur - U: mike P: Cyberark1
* Conjur - U: paul P: Cyberark1
* Conjur - U: cindy P: Cyberark1
* Conjur - U: john P: Cyberark1
* AWX - U: admin P: password
* GitLab - U: root P: Cyberark1

### Gitlab and Jenkins Jobs
Jenkins and Gitlab are connected via an internal docker network. Updating a job in Gitlab will be reflected in the subsequent Jenkins job at runtime.

1. JOB1_Summon - This job uses summon and the jenkins identity to pull a password with a simplified script
2. JOB2_Containers - This job spins up 5 webapp and 5 tomcat containers that are all pulling back a password. Jenkins generates a hostfactory token for each set of containers and then passes through an identity through container environment variables. Each container will then pull a password every 5 seconds.
3. JOB2_Rotation - This job rotates the secret being pulled by the containers.
4. JOB2_StopContainers - This job kills all of the tomcat and webapp containers.

### API Scripts
There are scripts that are copied into the CONJUR-CLI container that will interact with Conjur via rest calls to step through
1. Hostfactory creation
2. Identity creation using hostfactory token
3. Pull password using identity

The scripts are located in /scripts.  You can connect to the CONJUR-CLI container with:
* docker exec -it conjur-cli bash