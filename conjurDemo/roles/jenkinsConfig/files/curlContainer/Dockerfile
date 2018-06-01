FROM alpine

RUN apk add --update bash && rm -rf /var/cache/apk/* 
RUN apk add --update curl && rm -rf /var/cache/apk/*
COPY container_client.sh /root/container_client.sh
RUN chmod +x /root/container_client.sh
