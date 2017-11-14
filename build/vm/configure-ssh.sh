#!/bin/bash

set -e
service nscd restart
service nslcd restart
service ssh restart
service rsyslog restart

chgrp conjur /usr/sbin/logshipper
chown logshipper /usr/sbin/logshipper
/usr/sbin/logshipper -n /var/run/logshipper >> /var/log/logshipper.log 2>&1 &
