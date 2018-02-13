#!/bin/bash -ex
set -o pipefail

cd /src
touch .env

# create demo users, all passwords are foo
conjur policy load --as-group=security_admin ./etc/users-policy.yml | tee .up-out.json
ted_pwd=$(cat .up-out.json | jq -r '."dev:user:ted"')
bob_pwd=$(cat .up-out.json | jq -r '."dev:user:bob"')
alice_pwd=$(cat .up-out.json | jq -r '."dev:user:alice"')
carol_pwd=$(cat .up-out.json | jq -r '."dev:user:carol"')
rm .up-out.json

conjur authn login -u ted -p $ted_pwd
echo "Teds password is foo"
conjur user update_password << END
foo
foo
END

conjur authn login -u bob -p $bob_pwd
echo "Bobs password is foo"
conjur user update_password << END
foo
foo
END

conjur authn login -u alice -p $alice_pwd
echo "Alice password is foo"
conjur user update_password << END
foo
foo
END

conjur authn login -u carol -p $carol_pwd
echo "Carols password is foo"
conjur user update_password << END
foo
foo
END

conjur authn login -u bob -p foo
conjur policy load --as-group=security_admin ./etc/webapp1-policy.yml
conjur variable values add webapp1/database_password ThisIsTheDatabasePassword
conjur authn logout
