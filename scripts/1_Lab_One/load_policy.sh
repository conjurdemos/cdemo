#!/bin/bash
if [[ "$CONJURRC" = "" ]] ; then
	printf "\n\nSet CONJURRC to point to your .conjurrc file.\n"
	printf "This is created by 'conjur init' in your home directory by default.\n\n"
	exit 1
fi
if [[ -z $1 ]] ; then
	printf "\n\tUsage: %s <policy-file-name>\n\n" $0
	exit 1
fi
POLICY_FILE=$1

conjur authn login
conjur policy load --as-group security_admin policy.yml
