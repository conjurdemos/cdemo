# Build directories

All image builds are triggered via docker-compose.yml (i.e. no build scripts):
  - conjurcli:
    - Dockerfile - builds a rich Conjur CLI client container
  - etcd:
    - Dockerfile - builds a container to run etcd cluster manager
  - haproxy:
    - Dockerfile - builds HAproxy health checking load balancer
    - conjur-health-check.sh - script HA proxy runs to route request to healthy master
    - start.sh - entrypoint for container
  - hsm:
    - work in progress - not ready to show yet.
  - ldap:
    - Dockerfile - builds a OpenLDAP server container
  - splunk
    - Dockerfile - builds a Splunk Enterprise container
  - vm:
    - Dockerfile - builds a "rack VM" image for SSH key management demo
    - configure-ssh.sh - script to startup services on rack VM after configuration
  - webapp:
    - Dockerfile - builds webapp image based on Alpine w/ bash and curl installed
    - webapp1.sh - script loaded into image as entry point when container is started. It is resilient to API key rotation.
