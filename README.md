# CDemo - A Tour of Conjur Using Containers

This is self-contained implementation of a basic Conjur implementation to demonstrate all key capabilities and to serve as a foundation for POCs and implementations.

## Getting Started

- Review the dependencies section below and ensure all dependencies are properly installed.
- Copy `config.template.cfg` to `config.cfg`. This is your local config file.
  - Edit config.cfg and update the variables to match your environment. Notably CONJUR_CONTAINER_TARFILE and CONJUR_MASTER_PASSWORD should be updated.
- Run the startup script `./0-startup-conjur.sh`
  - The first time this is run it will require internet access. After the intial run this does not require internet access.
- Review and run through the demo scenarios below, or in the linked subdirectories.

- Getting Help
  - Open issues in github. The maintainers of cdemo will be notified of new issues and will do their best to resolve them.
  - Join the conjurHQ slack #about-cdemo channel and ask questions.

## Dependencies & System Requirements

| Dependency | Min Version | Check Command |
| ---------- | ----------- | ------------- |
| Docker | 17.12.0-ce | docker --version |
| Docker Compose | 1.16.1 | docker-compose --version |
| JQ | 1.5 | jq --version |
| Conjur Docker Image | 4.9.10 | Version in tarfile name (ex: conjur-appliance-4.9.11.0.tar) |

| Sys | Requirement |
| --- | ----------- |
| RAM | 8 GB |
| HDD | 30 GB |

- CentOS Linux users can run `_install-dependencies.sh` to install dependencies
- Request download image via https://www.cyberark.com/get-conjur-enterprise/
- Internet access required for initial builds, can run standalone after that

# Scenarios

Most of the demos have a README in their respective directory with information on how to run the demo and what to highlight. See the links below to use these demos.

| Scenario | Description |
| -------- | ----------- |
| Scalability | Spin up several minimal containers which fetch secrets continuously. |
| [Bastion](./bastion) | Bastion server (AKA jump server) with SSH access controlled by Conjur policy |
| [Cluster](./cluster) | Adds standbys to cluster and shows failover |
| [LDAP](./ldap) | Shows LDAp synchronization with an OpenLDAP server |
| [Policy](./policy) | Shows how to apply application policies with different user permissions across multiple environments |
| [Splunk](./splunk) | Brings up Splunk to monitor audit messages and NGINX logs |
| [SSH Ansible](./ssh_ansible) | Shows how to use policies to control SSH and sudo on hosts, incl. Ansible modules/playbooks |
| [Host Factory](./host_factory) | A basic Host Factory demo with secrets retrieval using REST API and Summon |

## Demo root directory (.../cdemo):

- 0-startup-conjur.sh - takes no arguments - initializes demo environment:
  - Uses image tagged conjur-appliance:latest
  - triggers builds of ALL demo images - this can take 30 minutes or more - prepare accordingly!
  - startups up Conjur Master, Conjur client CLI, load balancer, Conjur Follower and Weave Scope containers
    - Loads users-policy.yml and sets all user passwords to “foo”
    - loads demo policies and sets secret values to the secret name prefixed with “ThisIsThe"
  - 1-setup-containers.sh - takes two arguments (see demo scenario below) - starts up webapp application containers that fetch secrets from Conjur. 
  - 2-shutdown-containers.sh - takes no arguments - shuts down all webapp application containers.
  - docker-compose.yml - file that drives all container builds and configurations.
  - .env - file of environment variables for client application containers, referenced from docker-compose.yml, dynamically created by 1-setup-containers.sh
  - load_policy.sh - loads a supplied policy file
  - audit_policy.sh - compares a supplied policy file against current Conjur state, reports any deviations.
  - watch_container_log.sh - takes no arguments - runs tail on container #1 script logfile to monitor fetch activity
  - dbpassword_rotator.sh - sets the database password to a random hex value every 5 seconds
  - apikey_rotator.sh - rotates API key. With no arg, provides new key to apps. Any arg denies apps new API key.
  - inspect-cluster.sh - echos current state of cluster.

Basic demo scenario ("Scalability Demo"):
  Spin up a bunch of minimal containers, each of which fetches a secret every few seconds in a continuous loop. Change the secret, deny access, rotate the API key and watch effects.

  - run 0-startup-conjur.sh. 
    - REQUIRES INTERNET ACCESS FOR FIRST RUN ONLY.
    - When complete demo environment is ready.
  - run 1-setup_containers.sh w/ 2 args:
    - number of containers to create
    - number seconds for each container client to sleep betwixt secrets fetches
  - run watch_container_log.sh on one of the containers (containers named cont-1 to cont-n)
    - OR run weave scope (https://www.weave.works/oss/scope/), click into a container and 'tail -f cc.log'
  - change secret in UI - watch it change in watched log
  - audit_policy to show how we can see if current state is compliant with policy doc, change "permit" to "deny" for tomcat_hosts permissions, re-run audit_policy to show how to detect non-compliance
  - change "permit" to "deny" in policy file, reload policy and show how none of the containers can fetch secrets
  - 2-shutdown-containers.sh - brings down all webapp containers.
  - 3-shutdwon-all.sh - brings down ALL containers, volumes, networks, etc. - confirms first :)

./etc directory:
  - _conjur_init.sh - Conjur initialization script run from CLI container.
  - _demo_init.sh - demo initialization script run from CLI container.
  - conjur*.conf, conjur*.pem - configuration files for conjurization
  - conjur.json - referenced when configuring conjur-appliance containers to limit Postgres memory usage
