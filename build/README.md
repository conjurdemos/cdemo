# Build directories

All image builds are triggered via docker-compose.yml (i.e. no build scripts):
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
