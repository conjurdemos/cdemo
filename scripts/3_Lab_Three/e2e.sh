#!/bin/bash -eu

function main() {
  start_conjur && start_jenkins
  echo "-----"
  load_conjur_policy
  load_conjur_variable_values
  echo "-----"
  generate_host_factory_token
  issue_jenkins_identity
  echo "-----"
  show_output
}

# 'Private' functions

function start_conjur() {
  docker-compose up -d conjur
  printf "\nWaiting for Conjur to be ready"
  conjur_not_healthy=1
  while [ $conjur_not_healthy -ne 0 ]; do
    if [[ "true" == "$(curl -sk https://localhost/health | jq '.ok')" ]]; then
      conjur_not_healthy=0
    else
      printf "..."
      sleep 10
    fi
  done
  printf "\n"
}

function start_jenkins() {
  docker-compose up -d --build jenkins
}

function load_conjur_policy() {
  echo "Loading Conjur policy"
  echo "-----"
  docker-compose exec conjur \
    conjur policy load --as-group security_admin policy.yml
}

function load_conjur_variable_values() {
  echo "Loading values for secrets"
  echo "-----"
  docker-compose exec conjur \
    conjur variable values add aws/users/jenkins/access_key_id n8p9asdh89p
  docker-compose exec conjur \
    conjur variable values add aws/users/jenkins/secret_access_key 46s31x2x4rsf
}

function generate_host_factory_token() {
  echo "Generating Host Factory token"
  echo "-----"
  docker-compose exec conjur \
    conjur hostfactory tokens create --duration-days 1 jenkins/masters | jq -r '.[0].token' | tee hftoken.txt
}

function issue_jenkins_identity() {
  # Copy the public SSL cert out of Conjur master
  docker cp "$(docker-compose ps -q conjur):/opt/conjur/etc/ssl/ca.pem" conjur.pem
  # Copy that cert into the Jenkins master
  docker cp conjur.pem "$(docker-compose ps -q jenkins):/etc/conjur.pem"

  docker-compose exec --user root jenkins /src/identify.sh
}

function show_output() {
  echo "Jenkins web URL: http://localhost:8080"
  echo "Jenkins 'admin' password: $(cat jenkins_home/secrets/initialAdminPassword)"
  echo "-----"
  echo "Conjur web UI: https://localhost/ui"
  echo "Conjur 'admin' password: secret"
  echo "Conjur Host Factory token: $(cat hftoken.txt)"
}

main
