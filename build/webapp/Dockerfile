FROM alpine

RUN apk add --update bash && rm -rf /var/cache/apk/* 
RUN apk add --update curl && rm -rf /var/cache/apk/*
RUN apk add --update jq && rm -rf /var/cache/apk/*
COPY webapp1.sh /root/webapp1.sh
RUN chmod +x /root/webapp1.sh
