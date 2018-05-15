#!/bin/bash -e

echo "Fetching AWS secrets"


echo " "

echo "AWS_ACCESS_KEY_ID="$(summon-conjur aws/users/jenkins/access_key_id)

echo "AWS_SECRET_ACCESS_KEY="$(summon-conjur aws/users/jenkins/secret_access_key)
