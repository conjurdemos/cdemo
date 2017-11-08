FROM phusion/baseimage:0.9.16

# Add scripts to finish the SSH configuration
COPY configure-ssh.sh /root
COPY write_dummy_id_files.sh /root

# Install Chef to run the SSH configuration cookbooks
RUN /root/write_dummy_id_files.sh \
    && cd /tmp \
    && curl -L https://www.opscode.com/chef/install.sh | sudo -n bash \
    && sudo -n chef-solo --recipe-url https://github.com/conjur-cookbooks/conjur/releases/download/v0.4.3/conjur-v0.4.3.tar.gz -o conjur::install

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

