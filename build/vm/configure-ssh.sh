#!/bin/bash

set -e
rm /etc/service/sshd/down
/etc/my_init.d/00_regen_ssh_host_keys.sh 
service ssh start
/etc/service/logshipper/run &
