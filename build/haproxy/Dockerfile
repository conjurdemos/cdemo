FROM haproxy:1.7

RUN apt-get update
RUN apt-get install -y \
    curl \
    jq \
    vim 

COPY haproxy.cfg /usr/local/etc/haproxy/
COPY conjur-health-check.sh /root/
COPY start.sh /

