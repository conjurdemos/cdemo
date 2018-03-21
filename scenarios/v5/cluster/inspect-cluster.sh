#!/bin/bash

printf "\n\nRunning containers:\n----------------\n"
docker ps --format "{{.Names}}\t\t{{.Status}}"

printf "\n\nStateful node info:\n----------------\n"
cont_list=$(docker ps --format {{.Names}})
for cname in $cont_list; do
	crole=$(docker exec $cname sh -c "evoke role")
	cip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)
	printf "%s, %s, %s\n" $cname $crole $cip
done

printf "\n\nMaster health status:\n----------------\n"
curl -k https://localhost/health
printf "\n\n"

