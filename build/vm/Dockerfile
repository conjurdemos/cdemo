FROM ubuntu:14.04

RUN apt-get update -y; \
    apt-get install -y curl openssh-server; \
    apt-get autoclean

# Add scripts to finish the SSH configuration
COPY configure-ssh.sh /root

# Install Chef, download Conjur cookbook and run the Conjur installation recipe
RUN cd /tmp \
    && curl -L https://www.opscode.com/chef/install.sh | bash \
    && chef-solo --recipe-url https://github.com/conjur-cookbooks/conjur/releases/download/v0.4.3/conjur-v0.4.3.tar.gz -o conjur::install

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
