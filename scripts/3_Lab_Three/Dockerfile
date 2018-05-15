FROM jenkins:2.60.3
MAINTAINER dustin.collins@cyberark.net

# Switch to root user to run system commands
USER root

# Grab updates and install jq, required for identify.sh
RUN apt-get update && apt-get install -y \
  jq \
&& rm -rf /var/lib/apt/lists/*

# Install summon-conjur provider, simple way to fetch secrets once machine identity is granted.
# https://github.com/conjurinc/summon-conjur
RUN curl -L -o summon-conjur.tgz \
    https://github.com/conjurinc/summon-conjur/releases/download/v0.2.0/summon-conjur_v0.2.0_linux-amd64.tar.gz \
&& tar -xf summon-conjur.tgz -C /usr/local/bin

# Switch back to Jenkins user, be a good Docker citizen
USER jenkins

COPY conjur.conf /etc/conjur.conf

# Entrypoint script fetches machine identity and then runs Jenkins using tini, same as source image.
COPY identify.sh /src/identify.sh

