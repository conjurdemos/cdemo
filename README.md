# Cyberark Conjur Enterprise demonstration environment

This will set up a new demo environment that will show off the features of a Conjur Enterprise in conjunction with common devops tools.  The tools are all docker containers that are all mapped to the same docker network to all for DNS resolution of the docker container name.

## Conjur Appliance

The demo uses the lastest version of Conjur v5

## DevOps tools

* Docker
* Ansible
* Jenkins
* Gogs
* AWX
* Conjur CLI 
* Conjur Enterprise v5 or Conjur OSS
* Weavescope
* Splunk (Requires Conjur Enterprise v5)

## How to use

1. Clone the repo.
2. Obtain the latest Conjur tar file and place it within the cDemo directory named 'conjur.tar'.
    * If no tar file is located then a check for conjur docker registry access happens. If regsitry access comes back as successful then the latest version is pulled directly from the registry.
    * Conjur OSS will automatically be pulled if there is no tar file or Conjur docker registry access.
3. Run installAnsible.sh.
   * Verify that ansible 2.5.x has been installed by running "ansible --version". 
4. Change directory to conjurDemo.
5. Edit inventory.yml to include any machines to be stood up as demo machines.
6. Edit site.yml to change which tools are installed. Set each tool variable to 'YES' for it to be installed automatically. Set to 'NO' for it to be skipped.
7. Run sudo ansible-playbook -i inventory.yml site.yml to install conjur and it's tools.
    * Conjur alone can be configured by running sudo ansible-playbook -i inventory.yml conjurSetup.yml
    * Ansible with PAS jobs can be deployed by setting the variable "ansible_pas: 'YES'" in site.yml

## Using cdemo with Conjur Enterprise

By default, cdemo will build with Conjur Open Source which is available to
everyone as LGPL software. However, if you have access to Conjur Enterprise,
cdemo can use that instead.

In order to enable Conjur Enterprise, you need an archive containing the Conjur
Enterprise appliance image in the root directory of cdemo (same as this readme.)

If you have access to a Docker registry containing Conjur Enterprise you can
create the acrhive yourself like so:

```sh-session
$ docker image save registry.local/conjur-appliance:5.0-stable | gzip -c >conjur.tgz
```

If you don't have access, you can download the archive file from your CyberArk
support vault or contact CyberArk sales to get access. After downloading the
arcvhive file, move it to this folder.

Note: in order to be recognized as a Conjur Enterprise archive file, it must
have one of these names:
* `conjur.tar`
* `conjur.tar.gz`
* `conjur.tgz`

*Any other archive file(s) will be ignored.*

### Use case: I have Conjur Enterprise in a local registry & don't want to mess with creating archive files

In this case, you can enable Conjur Enterprise with these steps:
1. edit `cdemo/conjurDemo/roles/conjurConfig/defaults/main.yml`
2. change `conjur_version` to `EE`
3. change `conjur_EE_image_name` to the fully qualified name of the Conjur
   Enterprise appliance image in your local registry.

Now cdemo will use Conjur Enterprise without requiring an archive file.

## Conjur CLI information

The Conjur CLI will be pre-configured to work with the Conjur container. Inside
the CLI container, the scripts folder is mounted to `/scripts`.

## Requirements

1. Centos 7 OS
2. Internet Connection
3. 4 vCPU
4. 4 GB Ram
5. 32 GB hdd space at minimum
6. Ansible v2.5

## Access WEB interfaces

The tools installed have a web interfaces that is made accessible to the host machine on the following network ports:

|    Tool    	| Port 	|
|:----------:	|------	|
|   Jenkins  	| 8080 	|
|   Gogs       	| 10080	|
|     AWX    	| 6060  |
| Conjur     	| 443  	|
| Weavescope 	| 4040 	|

_If using v5 Enterprise Edition:_

|    Tool    	| Port 	|
|:----------:	|------	|
|   Splunk  	| 8000 	|

## Default Credentials
* Jenkins - No credentials needed right now
* Conjur - U: admin P: Cyberark1
* Conjur - U: mike P: Cyberark1
* Conjur - U: paul P: Cyberark1
* Conjur - U: cindy P: Cyberark1
* Conjur - U: john P: Cyberark1
* Conjur - U: eva P: Cyberark1
* AWX - U: eva P: Cyberark1
* Gogs - U: eva P: Cyberark1
* Splunk - U: eva P: Cyberark1

### Gogs and Jenkins Jobs
Jenkins and Gogs are connected via an internal docker network. Updating a job in Gitlab will be reflected in the subsequent Jenkins job at runtime.

1. JOB1_Summon - This job uses summon and the jenkins identity to pull a password with a simplified script
2. JOB2_Containers - This job spins up 5 webapp and 5 tomcat containers that are all pulling back a password. Jenkins generates a hostfactory token for each set of containers and then passes through an identity through container environment variables. Each container will then pull a password every 5 seconds.
3. JOB2_Rotation - This job rotates the secret being pulled by the containers.
4. JOB2_StopContainers - This job kills all of the tomcat and webapp containers.

### AWX , Gogs, and Jenkins Jobs
AWX and Gogs are connected via an internal docker network. All projects in AWX have source code in Gogs.

1. LAB3_AnsibleBuildContainers (Jenkins) - Creates target for Ansible job.
2. LAB3_AnsibleConjurIdentity - Pushes a conjur identity to a remote machine that is set up with the job above.
3. LAB3_AnsibleConjurLookup - Returns a value from conjur is the ansible node has a conjur identity.
4. LAB3_AnsibleStopContainers (Jenkins) - Removes target and clears awx known_hosts.

### API Scripts
There are scripts that are copied into the CONJUR-CLI container that will interact with Conjur via rest calls to step through
1. Hostfactory creation
2. Identity creation using hostfactory token
3. Pull password using identity

The scripts are located in /scripts.  You can connect to the CONJUR-CLI container with:
* docker exec -it conjur-cli bash
