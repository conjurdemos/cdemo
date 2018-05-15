#!/bin/bash -e

function main() {
  echo "-----"
  fetch_machine_identity
}

function fetch_machine_identity() {
  echo 'Fetching machine identity from Conjur'

  local hostid='jenkins/masters/master01'
  local token=$(cat /src/hftoken.txt | tr -d "\n")

  local status=$(curl -X POST -s -w '%{http_code}' \
    --cacert /etc/conjur.pem \
    -o /src/host.json \
    -H "Authorization: Token token=\"$token\"" \
    https://conjur/api/host_factories/hosts?id=$hostid
  )

  if [ $status -eq 201 ]; then
    cat > /etc/conjur.identity <<EOF
    machine https://conjur/api/authn
    login host/$hostid
    password $(jq -r '.api_key' /src/host.json)
EOF
    echo '...complete'
  else
    echo "Error! HTTP response: $status"
    exit 1
  fi

  echo "-----"
}

main
