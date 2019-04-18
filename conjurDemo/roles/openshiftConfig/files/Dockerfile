FROM debian:stable-slim

COPY secrets.yml /scripts/

COPY script.sh /scripts/

RUN apt-get update -y &&\
    apt-get install -y curl &&\
	curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh | bash &&\
	curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/master/install.sh | bash &&\
	apt-get clean &&\
	rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

RUN chmod +x /scripts/script.sh