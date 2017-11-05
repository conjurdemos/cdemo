#!/bin/bash -e
set -o pipefail

CONJUR_ADMIN_PWD=Cyberark1

test_ldap_connect() {
    docker-compose exec -T ldap bash -c "ldapsearch -x -h localhost -b dc=example,dc=org -D cn=admin,dc=example,dc=org -w admin '(objectClass=user)'"
}

main() {
  docker-compose rm -svf ldap
  docker-compose up -d ldap
  docker-compose exec cli conjur authn login -u admin -p $CONJUR_ADMIN_PWD
  docker-compose exec cli conjur elevate policy load /src/ldap/ldap-sync-config.yml
  docker-compose exec cli conjur elevate variable values add conjur/ldap-sync/bind-password/default $CONJUR_ADMIN_PWD


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
  docker-compose exec -T ldap bash -c 'ldapadd -x -D cn=admin,dc=example,dc=org -w admin -f /ldap-bootstrap.ldif'
}

main "$@"
