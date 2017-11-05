#!/bin/bash -x

# Variables should already been defined in docker-compose file

if [ ! -e /opt/conjur/etc/ssl/conjur.pem ]; then
  evoke configure master -h $CONJUR_MASTER_HOSTNAME -p $CONJUR_MASTER_PASSWORD $CONJUR_MASTER_ORGACCOUNT
fi
