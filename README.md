# cdemo - an tour of Conjur using containers

Goal: A self-contained implementation of a simple Conjur application for demonstration in docker-compose and serve as a reference model for best practices.

NOTE: This demo uses a single identity for all instances of the application. This is best practice as it is scalable to potentially thousands of instances, whereas use of the Host Factory token does not.

Scenario: Spin up a bunch of minimal containers, each of which fetches a secret every few seconds in a continuous loop. Change the secret, deny access, rotate the API key and watch effects.

Dependencies:
  - docker & docker-compose - install-dependencies.sh installs these
  - internet access for initial run, can run air gapped after

Demo files:
  - 0-startup-conjur.sh - takes no arguments - initialize demo environment:
    - startups up Conjur, Conjur client CLI and Weave Scope containers
    - Loads users-policy.yml and sets all user passwords to “foo”
    - loads demo policies and sets secret values to the secret name prefixed with “ThisIsThe"
  - 1-setup-containers.sh - takes two arguments (see demo scenario below) - starts up client application containers that fetch secrets from Conjur. 
  - 2-shutdown-containers.sh - takes no arguments - shuts down all client application containers.
  - _conjur_init.sh - Conjur initialization script run from CLI container.
  - _demo_init.sh - demo initialization script run from CLI container.
  - docker-compose.yml - file that drives all container builds and configurations.
  - .env - file of environment variables for client application containers, referenced from docker-compose.yml, dynamically created by 1-setup-containers.sh
  - load_policy.sh - loads a supplied policy file
  - audit_policy.sh - compares a supplied policy file against current Conjur state, reports any deviations.
  - watch_container_log.sh - takes no arguments - runs tail on container #1 script logfile to monitor fetch activity
  - dbpassword_rotator.sh - sets the database password to a random hex value every 5 seconds
  - apikey_rotator.sh - rotates the API key once.

  Build directories - all builds are triggered from docker-compose.yml (i.e. no build scripts):
  - build/webapp:
    - Dockerfile - defines Alpine images w/ bash and curl
    - webapp1.sh - script loaded into image as entry point when container is started. It is resilient to API key rotation.
  - build/conjurcli:
    - Dockerfile - build parameters for rich Conjur CLI client container

Demo scenario:
  - run 0-startup-conjur.sh. REQUIRES INTERNET ACCESS FOR FIRST RUN ONLY. When complete demo environment is ready.
  - run 1-setup_containers.sh w/ 2 args - REQUIRES INTERNET ACCESS FOR FIRST RUN ONLY:
    - number of containers to create
    - number seconds for each container client to sleep betwixt secrets fetches
]  - run watch_container_log.sh on one of the containers (containers named cont-1 to cont-n)
    - OR run weave scope (https://www.weave.works/oss/scope/), click into a container and 'tail -f cc.log'
  - change secret in UI - watch it change in watched log
  - audit_policy to show how we can see if current state is compliant with policy doc, change "permit" to "deny" for tomcat_hosts permissions, re-run audit_policy to show how to detect non-compliance
  - change "permit" to "deny" in policy file, reload policy and show how none of the containers can fetch secrets
  - 2-shutdown-containers.sh - brings down all webapp containers.
  - docker-compose down - brings down all containers incl. conjur, cli & scope.
