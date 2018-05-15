# scalability-demo

Goal: An impressive visual display of Conjur's scalability that can run on a laptop and run even more impressively in AWS or other cloud environ. Make implementation relatively simple.

Scenario: Spin up a bunch of minimal containers, each of which fetches a secret every 5 seconds in a continuous loop. Change the secret, deny access and watch effects.

Prerequisites:
  - docker - probably already running Conjur
  - Conjur CLI installed and configured w/ 'conjur init'
    - download CLI installation package here: https://github.com/conjurinc/cli-ruby/releases
  - jq - needs to be installed, used to parse REST API output and extract info

Demo files:
  - EDIT.ME - resource file, sets Conjur appliance URL and SSL certificate file environment variables
  - init_mac_env.sh - run before doing demo. aliases lo0 network adapter so container<->host networking works
  - policy.yml - declares security policy for a layer, host factory and secrets that members of layer can access
  - load_policy.sh - loads a supplied policy file
  - audit_policy.sh - compares a supplied policy file against current state, reports any deviations.
  - setup_containers.sh - obtains host factory token and generates containers in layer
  - shutdown_containers.sh - stops and removes all containers started with setup_..
  - watch_container_log.sh - runs tail on container script logfile to monitor fetch activity
  - show_conjur_syslog.sh - displays last 50 lines in the master's syslog for debugging/monitoring

  Build directory:
  - Dockerfile - defines Alpine images w/ bash and curl
  - build_run.sh - runs docker run to build image
  - container_client.sh - script loaded into image as entry point when container is started.
  - run.sh - runs container instance for debugging
  
  simple_example directory:
  - see description below

Demo scenario:
  - edit EDIT.ME to point to your Conjur master and conjur-ACCT.pem certificate file
  - load policy as-is. Scripts are tied to this policy, but parameterized so you can change it easily if you change the policy
  - audit_policy to show how we can see if current state is compliant with policy doc, change "permit" to "deny" for tomcat_hosts permissions, re-run audit_policy to show how to detect non-compliance
  - run setup_containers.sh w/ 3 args:
    - number of containers to create
    - number of seconds to HF token expiry
    - number seconds for each container client to sleep betwixt secrets fetches
  - containers take about 1 sec each to spin up, so if you make the # of containers == # HF token seconds, you should see the the last 20% of containers do not get API keys due to HF token expiration 
  - run watch_container_log.sh on one of the containers (containers named cont-1 to cont-n)
    - OR install weave scope (https://www.weave.works/oss/scope/), click into a container and 'tail -f cc.log'
  - change secret in UI - watch it change in watched log
  - change "permit" to "deny" in policy file, reload policy and watch errors scroll

Potential enhancements:
  - enhance visualization UI to show colors indicating secrets fetch success/failure, eliminate need to watch log
  - docker-compose instead of bash/docker run
  - get certs to work in Alpine (doesn't like that there are two certs in our .pem)
  - eliminate hard-coded input values - config file or parameters
  - support multiple layers and/or more complex entitlements
  - support multiple hosts in AWS or other multi-VM config
  - Conjur cluster w/ load balancer
  
 Simple example directory:
  - setup_summon.sh - installs summon-conjur for linux
  - EDIT.ME - resource file that sets environment variables for Conjur appliance URL and SSL certificate
  - 1_set_hf_token.sh - creates a host factory token, writes it + tomcat1 and webapp1/database_password to file
  - 2_get_secret_restapi.sh - reads input file created by above, creates API key, fetches and displays secret
  - 2_get_secret_summon.sh - reads input file created by 1_.. above, creates API key, fetches secret and processes template
  - tomcat.xml.erb - template for Summon example above
  admin_process.sh, worker_process.sh, zz.out - simple scripts to demo host factory pattern
    - run admin_process.sh in one shell window, worker_process.sh in another
    - admin_process generates HF token using CLI, writes it, hostname and variable name to zz.out
    - worker_process reads zz.out, uses HF token to create host identity for hostname via REST API and fetches value of variable
