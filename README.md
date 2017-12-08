# cdemo - a tour of Conjur using containers

This is self-contained implementation of a basic Conjur implementation to demonstrate all key capabilities and to serve as a foundation for POCs and implementations.

Dependencies:
  - TO INSTALL DOCKER, DOCKER-COMPOSE, JQ, ETC - run _install-dependencies.sh
  - locally available conjur docker image tarfile - v4.9.10 or greater required for auto-failover
    - request download image via https://www.cyberark.com/get-conjur-enterprise/
  - internet access required for initial builds, can run standalone after that

Demo root directory (.../cdemo):
  - 0-startup-conjur.sh - takes no arguments - initializes demo environment:
    - EDIT SCRIPT WITH PATH TO CONJUR TARFILE BEFORE RUNNING.
    - triggers builds of ALL demo images - this can take 30 minutes or more - prepare accordingly!
    - startups up Conjur, Conjur client CLI and Weave Scope containers
    - Loads users-policy.yml and sets all user passwords to “foo”
    - loads demo policies and sets secret values to the secret name prefixed with “ThisIsThe"
  - 1-setup-containers.sh - takes two arguments (see demo scenario below) - starts up client application containers that fetch secrets from Conjur. 
  - 2-shutdown-containers.sh - takes no arguments - shuts down all client application containers.
  - docker-compose.yml - file that drives all container builds and configurations.
  - .env - file of environment variables for client application containers, referenced from docker-compose.yml, dynamically created by 1-setup-containers.sh
  - load_policy.sh - loads a supplied policy file
  - master-control.sh - inspect, pause/unpause, or kill Conjur master.
  - audit_policy.sh - compares a supplied policy file against current Conjur state, reports any deviations.
  - watch_container_log.sh - takes no arguments - runs tail on container #1 script logfile to monitor fetch activity
  - dbpassword_rotator.sh - sets the database password to a random hex value every 5 seconds
  - apikey_rotator.sh - rotates the API key once.
  - inspect-cluster.sh

Basic demo scenario:
  Spin up a bunch of minimal containers, each of which fetches a secret every few seconds in a continuous loop. Change the secret, deny access, rotate the API key and watch effects.

  - run 0-startup-conjur.sh. REQUIRES INTERNET ACCESS FOR FIRST RUN ONLY. When complete demo environment is ready.
  - run 1-setup_containers.sh w/ 2 args:
    - number of containers to create
    - number seconds for each container client to sleep betwixt secrets fetches
  - run watch_container_log.sh on one of the containers (containers named cont-1 to cont-n)
    - OR run weave scope (https://www.weave.works/oss/scope/), click into a container and 'tail -f cc.log'
  - change secret in UI - watch it change in watched log
  - audit_policy to show how we can see if current state is compliant with policy doc, change "permit" to "deny" for tomcat_hosts permissions, re-run audit_policy to show how to detect non-compliance
  - change "permit" to "deny" in policy file, reload policy and show how none of the containers can fetch secrets
  - 2-shutdown-containers.sh - brings down all webapp containers.
  - docker-compose down - brings down all containers incl. conjur, cli & scope.

./ldap - LDAP demo directory:
  - 0-setup-ldap.sh - brings up OpenLDAP server container and loads ldap-boostrap.ldif to populate it
  - 1-ldap-sync.sh - imports ldap-sync.yml created by the Conjur web UI LDAP interface 

./splunk - Splunk demo directory:
  - 0-setup-splunk.sh - brings up the Splunk Enterprise container - watch the log till you see its listening then ctrl-C

./ssh - SSH demo directory:
  - 0-setup-ssh.sh - takes 1 argument for # of "rack VMs" to bring up, configures each w/ Chef cookbook
  - 1_create_key_for_user.sh - takes 1 argument (user name) - creates SSH key for given user and stored pub key in Conjur
  - 2_test_fetch_userkey_from_host.sh - takes 2 arguments (user, container name) - tests if container can fetch user's pub key
  - 3_ssh_user_to_host.sh - takes 2 arguments (user, container) - attempts to ssh as user to container/host
  - 4_roles_with_resource_permissions.sh - takes 2 arguments (host:container, privilege) - shows all roles holding privilege on resource
  - 5_review_activity_on_resource.sh - takes 1 argument (host:container) - displays audit records for resource
  - rack.yml - policy file created and loaded by 0-setup-ssh.sh
  - load_policy.sh - utility for loading ssh-mgmt.yml during demo to effect access changes
  - ssh-mgmt.yml - defines access policies for Dev and Prod VM access

./simple_hf_example - very basic Host Factory demo:
  - 1_set_hf_token.sh - one argument: output file, creats HF token, hostname and variable to retrieve
  - 2_get_secret_restapi.sh - one argument: outfile from above, redeems HF token, retrieves variable w/ REST API
  - 2_get_secret_summon.sh - one argument: outfile from above, redeems HF token, retrieves variable w/ Summon
  - 3_cleanup.sh - deletes old HF tokens
  - EDIT.ME - connection info for Conjur
  - policy.yml - webapp policy to create variable for retrieval
  - setup_summon.sh - installs summon
  - tomcat.xml.erb - example template for secrets injection via Summon

./cluster - adds standbys and a follower to cluster:
  - 0-setup-cluster.sh - brings cluster to default state of 1-master/2-standbys/1-follower
  - 1-cluster-failover.sh - removes current master to trigger auto-failover, adds replacement standy

./etc directory:
  - _conjur_init.sh - Conjur initialization script run from CLI container.
  - _demo_init.sh - demo initialization script run from CLI container.
  - conjur.conf, conjur-xxx.pem - configuration files for conjurization
  - install-dependencies.sh - installs docker and docker-compose

Build directories - all image builds are triggered via docker-compose.yml (i.e. no build scripts):
  - build/conjurcli:
    - Dockerfile - builds a rich Conjur CLI client container
  - build/etcd:
    - Dockerfile - builds a container to run etcd cluster
  - build/ldap:
    - Dockerfile - builds a OpenLDAP server container
  - build/splunk
    - Dockerfile - builds a Splunk Enterprise container
  - build/vm:
    - Dockerfile - builds a "rack VM" image for SSH key management demo
    - configure-ssh.sh - script to startup services on rack VM after configuration
  - build/webapp:
    - Dockerfile - builds webapp image based on Alpine w/ bash and curl installed
    - webapp1.sh - script loaded into image as entry point when container is started. It is resilient to API key rotation.

