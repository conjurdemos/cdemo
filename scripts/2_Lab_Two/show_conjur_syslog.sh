#!/bin/bash
num_lines=$1
if [[ -z $1 ]] ; then
	num_lines=50
fi
docker exec conjur-solo tail -$num_lines /var/log/syslog

