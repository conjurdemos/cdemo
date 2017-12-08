#!/bin/bash
set -eo pipefail
printf "\n\n-----\nApplying application policies to environments...\n\n"
./load_policy.sh policy.yml
printf "\n\n-----\nBinding admin groups to app secrets_manager roles in environments...\n\n"
./load_policy.sh webapp_grants.yml
