FROM ubuntu:14.04
RUN apt-get update -y; \
    apt-get install -y curl openssh-server; \
    apt-get autoclean
COPY write_id_files.sh /root
RUN /root/write_id_files.sh && curl -L https://www.opscode.com/chef/install.sh | sudo -n bash
RUN sudo -n chef-solo --recipe-url https://github.com/conjur-cookbooks/conjur/releases/download/v0.4.3/conjur-v0.4.3.tar.gz -o conjur
ENTRYPOINT service ssh restart && sleep infinity
