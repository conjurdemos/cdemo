FROM haproxy:1.7

RUN apt-get clean
RUN apt-get update
RUN apt-get install -y \
    curl \
    vim 

COPY haproxy.cfg.master-only /usr/local/etc/haproxy/haproxy.cfg
COPY start.sh /
