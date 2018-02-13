#!/bin/bash -e
set -o pipefail

. ../../etc/_loadcfg.sh

test_ldap_connect() {
    docker-compose exec -T ldap bash -c "ldapsearch -x -h localhost -b dc=example,dc=org -D cn=admin,dc=example,dc=org -w admin '(objectClass=user)'"
}

main() {
  docker-compose rm -svf ldap
  docker-compose up -d ldap
  docker-compose exec cli conjur authn login -u admin -p $CONJUR_MASTER_PASSWORD
  docker-compose exec cli conjur elevate policy load /src/scenarios/ldap/ldap-sync-config.yml
  docker-compose exec cli conjur elevate variable values add conjur/ldap-sync/bind-password/default $CONJUR_MASTER_PASSWORD


  for i in {1..60}; do
    if ! test_ldap_connect; then
        echo "Waiting for OpenLDAP to start"
     else
        break
    fi
    sleep 1
  done

                # hopefully prevent intermittent failures
  sleep 2
                        # load demo groups & users from mounted file
  docker-compose exec -T ldap bash -c 'ldapadd -x -D cn=admin,dc=example,dc=org -w admin -f /src/scenarios/ldap/ldap-bootstrap.ldif'
}

main "$@"
