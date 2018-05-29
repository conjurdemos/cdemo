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
3. Run installAnsible.sh.
4. Change directory to ConjurDemo.
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
* AWX - U: admin P: password

#### Things to do!

* Refactor jenkinsConfig role to assign an identity through environment variables when container is started.
* Create Jenkins Jobs
    1. Scalability Demo
        * Build docker container that writes secret to log file. Stores in local docker registry
        * Stands up x number of tomcat host containers
        * stands up x number of webapp host containers
        * shared volume between all like containers
    2. Spring integration.
        * Add in https://github.com/conjurinc/summon-spring-demo
    3.  Quincy's demo
        * https://github.com/quincycheng/cicd
* Refactor playbooks
    1. Create Defaults
    2. Create variables
    3. Changes roles to account for:
        * YUM distros
        * Debian distros
        * macOS distros
* Create global menu that will step through set up
* Create checks in apiInteraction scripts
    1. Identity script should check for existence of hostfactory token file first. If unavailable then it runs the hostfactory creation script
    2. Pull password script checksf or identity file first. If unavailable then it runs the identity script first.
    3. Move functions from each api script into the utils.sh and reduce what each script is doing. 
* Replace AWX with Ansible Tower