#!/bin/bash
set -eo pipefail
clear
printf "\nFirst let\'s look at the webapp1 application policy.\n"
printf "Note the roles for secrets_users and secrets_managers:\n\n"
read -n 1 -s -r -p "Press any key when ready..."
clear
more apps/webapp.yml

printf "\n\n-----\nLoading master policy, which:\n"
printf "\t- applies application policies across all environments\n"
printf "\t- applies the policies that bind users to application roles.\n\n"
printf "This requires security_admin credentials.\n\n"
./load_policy.sh master-policy.yml
