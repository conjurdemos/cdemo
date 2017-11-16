#!/bin/bash -e

main() {
	install_docker
	install_docker_compose
	install_jq
	install_conjur_cli
	configure_env
	echo "Logout and log back in to run docker commands w/o sudo..."
}

install_docker() {
	echo "Installing Docker..."
	sudo yum install -y yum-utils \
	  device-mapper-persistent-data \
	  lvm2
	sudo yum-config-manager \
	    --add-repo \
	    https://download.docker.com/linux/centos/docker-ce.repo
	sudo yum install -y docker-ce
		# add user to docker group to run docker w/o sudo
	sudo usermod -aG docker $USER
	sudo systemctl start docker
}

install_docker_compose() {
		# install docker-compose
	sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	docker-compose --version
}

install_jq() {
	echo "Installing jq..."
	curl -LO https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64

	chmod a+x jq-linux64
	sudo mv jq-linux64 /usr/local/bin/jq
}

install_conjur_cli() {
	curl -o conjur.rpm -L https://github.com/cyberark/conjur-cli/releases/download/v5.4.0/conjur-5.4.0-1.el6.x86_64.rpm \
  && sudo rpm -i conjur.rpm \
  && rm conjur.rpm
}

configure_env() {
	echo "Configuring environment..."
	sudo chmod a+w /etc/bashrc
	sudo echo PATH=\$PATH:/usr/local/bin >> /etc/bashrc
	sudo chmod go-w /etc/bashrc
	. ~/.bashrc
}

main $@
