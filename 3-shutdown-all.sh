#!/bin/bash -e

printf "\n\nBringing down all running containers.\n"
printf "\n\n\tThis will destroy your currently running environment - proceed?\n\n"
select yn in "Yes" "No"; do
  case $yn in
      Yes ) break;;
      No ) exit -1;;
  esac
done

docker-compose down -v

