#!/bin/bash
SLEEP_TIME=2
if [[ "$1" != "" ]]; then
	SLEEP_TIME=$1
fi
while : ; do
	printf "\n\n-----\nCluster members:\n"
	printf "\nAccording to conjur1:\n"
	docker exec conjur1 etcdctl member list
	printf "\nAccording to conjur2:\n"
	docker exec conjur2 etcdctl member list
	printf "\nAccording to conjur3:\n"
	docker exec conjur3 etcdctl member list
	sleep $SLEEP_TIME
done
