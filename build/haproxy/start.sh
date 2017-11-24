#!/bin/bash -ex

# haproxy.cfg is created and updated by update_haproxy.sh script in cdemo/etc
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg 
