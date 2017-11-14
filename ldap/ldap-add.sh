#!/bin/bash -ex
docker-compose exec -T ldap bash -c "ldapadd -x -D cn=admin,dc=example,dc=org -w admin -f /src/ldap/$1"
