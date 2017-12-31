#!/bin/bash 
			# kill running haproxy daemon if any
haproxy_pid=$(ps aux | grep haproxy | grep -v grep | awk '{print $2}')
if [[ "$haproxy_pid" != "" ]]; then
	kill -9 $haproxy_pid
fi

# haproxy.cfg is created and updated by update_haproxy.sh script in $DEMO_ROOT/etc
haproxy -D -f /usr/local/etc/haproxy/haproxy.cfg 
