#!/bin/bash -e
docker-compose rm -svf webapp
docker-compose rm -svf ldap
docker-compose rm -svf vm
docker-compose rm -svf splunk
docker volume rm $(docker volume ls -qf dangling=true)

