#!/bin/bash

printf "\n\nLoad balancer config:\n----------------\n"
docker-compose exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg

printf "\n\nRunning containers:\n----------------\n"
docker ps --format "{{.Names}}\t\t{{.Status}}"

printf "\n\nStateful node info:\n----------------\n"
cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
for cname in $cont_list; do
	crole=$(docker exec $cname sh -c "evoke role")
	cip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cname)
	printf "%s, %s, %s\n" $cname $crole $cip
done
printf "\n\n"
