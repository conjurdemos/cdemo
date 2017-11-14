#!/bin/bash -ex
docker-compose exec -T ldap bash -c "ldapsearch -x -h localhost -b dc=example,dc=org -D cn=admin,dc=example,dc=org -w admin -L $1"
