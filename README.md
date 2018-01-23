# cdemo - a tour of Conjur using containers

This is self-contained implementation of a basic Conjur implementation to demonstrate all key capabilities and to serve as a foundation for POCs and implementations.

Dependencies:
  - TO INSTALL DOCKER, DOCKER-COMPOSE, JQ, ETC - run `_install-dependencies.sh`
  - locally available conjur docker image tarfile - v4.9.10 or greater required for auto-failover
    - request download image via https://www.cyberark.com/get-conjur-enterprise/
  - internet access required for initial builds, can run standalone after that

Demo root directory (.../cdemo):
  - 0-startup-conjur.sh - takes no arguments - initializes demo environment:
    - uses image tagged conjur-appliance:latest
    - EDIT SCRIPT WITH PATH TO CONJUR TARFILE BEFORE RUNNING, if you have no conjur-appliance loaded.
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

Demo directories (each demo has its own README):
 - ./bastion - bastion server (AKA jump server) with SSH access controlled by Conjur policy
 - ./cluster - adds standbys to cluster and shows failover
 - ./ldap - shows LDAP synchronization w/ an OpenLDAP server
 - ./policy - shows how to apply application policies w/ different user permissions across multiple environments
 - ./splunk - brings up Splunk to monitor audit messages and NGINX logs
 - ./ssh_ansible - shows how to use policies to control SSH and sudo on hosts, incl. Ansible module/playbooks
 - ./host_factory - a basic Host Factory demo with secrets retrieval using REST API and Summon

./etc directory:
  - _conjur_init.sh - Conjur initialization script run from CLI container.
  - _demo_init.sh - demo initialization script run from CLI container.
  - conjur*.conf, conjur*.pem - configuration files for conjurization
  - conjur.json - referenced when configuring conjur-appliance containers to limit Postgres memory usage
