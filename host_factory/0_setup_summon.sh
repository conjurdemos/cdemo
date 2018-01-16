#!/bin/bash
if [[ "$(which summon)" == "" ]]; then
	printf "\nInstalling Summon...\n"
	curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh | sudo bash
else
	printf "\nSummon already installed.\n"
fi
