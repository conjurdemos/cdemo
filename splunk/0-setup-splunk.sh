#!/bin/bash -e
set -o pipefail
docker-compose up -d splunk
printf "\nWatching Splunk log. Ctrl-C when you see the following:\n"
printf "splunk_1  | Listening for data on TCP port 1514.\n"
read -p "Press enter to continue..."
docker-compose logs -f splunk
