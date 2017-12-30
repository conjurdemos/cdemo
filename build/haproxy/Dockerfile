FROM haproxy:1.7

RUN apt-get clean
RUN apt-get update
RUN apt-get install -y \
    curl \
    vim 

COPY haproxy.cfg /usr/local/etc/haproxy/
COPY start.sh /
