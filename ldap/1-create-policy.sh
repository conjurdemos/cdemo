#!/bin/bash
set -eo pipefail
printf "\n\n-----\nCreate ldap policy file...\n\n"
printf "Use the Conjur UI to:\n"
printf "\t- connect to the LDAP server (upper right gear icon in UI)\n"
printf "\t- connect to the LDAP server (search password is 'admin')\n"
printf "\t- review & edit filter settings for users and groups\n"
printf "\t- click 'Test Configuration' to preview users & groups to sync\n"
printf "\t- click 'Save & Schedule' when ready to run sync script\n\n"
read -n 1 -s -r -p "Press any key to continue..."
if [[ "$(uname -s)" == "Linux" ]]; then
	xdg-open https://conjur_master/ui/settings/ldap-sync/
else
	open https://conjur_master/ui/settings/ldap-sync/
fi
echo
