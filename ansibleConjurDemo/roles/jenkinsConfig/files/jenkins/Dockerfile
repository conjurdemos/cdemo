FROM jenkins/jenkins:lts

USER root

VOLUME [ "/plugins"]

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY plugins.txt /plugins/

RUN apt-get update &&\
    apt-get install -qy git apt-utils curl dpkg jq libexpat1-dev libpython2.7-dev python2.7-dev vim sudo &&\
	apt-get install -f -qy &&\
	rm -rf /var/lib/apt/lists/* &&\
	curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh | bash &&\
	curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/master/install.sh | bash &&\
	apt-get install -f -y &&\
	curl -fsSL get.docker.com -o get-docker.sh &&\
	sh get-docker.sh &&\
	usermod -aG docker jenkins &&\
    curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose &&\
    chmod +x /usr/local/bin/docker-compose &&\
    xargs /usr/local/bin/install-plugins.sh < /plugins/plugins.txt || true &&\
	apt-get clean &&\
	rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

USER jenkins

EXPOSE 8080 50000