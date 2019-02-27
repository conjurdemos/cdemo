#!/bin/bash

main(){
  printf '\n-----'
  printf '\nStopping and removing any running containers.'
  stop_containers
  printf '\nRemoving any images on the system.'
  remove_images
  printf '\nRemoving any conjur network on the system.'
  remove_network
  printf '\nRemoving any conjur volume on the system.'
  remove_volume
  # printf '\nRemoving pip and docker'
  # remove_docker
  printf '\nRemoving Weavescope'
  remove_weavescope
  printf '\nRemoving Ansible Tower'
  remove_ansible
  printf '\nRemoving hosts file changes\n'
  remove_hosts
  clean_yum
  remove_openshift
}

stop_containers(){
  oc cluster down
  docker container rm -f splunk
  docker container rm -f jenkins
  docker container rm -f gogs
  docker container rm -f weavescope
  docker container rm -f conjur-master
  docker container rm -f conjur-cli
}

remove_images(){
  docker image prune -a --force
}

remove_network(){
  docker network rm conjur &> /dev/null
}

remove_volume(){
  docker volume rm audit &> /dev/null
  docker volume rm hostfactorytokens &> /dev/null
  docker volume rm identity &> /dev/null
  docker volume rm tls &> /dev/null
  docker volume prune -f &> /dev/null
}

remove_docker(){
  pip uninstall docker -y &> /dev/null
  pip uninstall docker-py -y &> /dev/null
  pip uninstall docker-pycreds -y &> /dev/null
  pip uninstall pip -y &> /dev/null
  if [[ $(cat /etc/*-release | grep -w ID_LIKE) == 'ID_LIKE="rhel fedora"' ]]; then
    yum remove docker* -y &> /dev/null
    yum remove docker-ce -y &> /dev/null
    rm -f /etc/yum.repos.d/docker-ce.repo &> /dev/null
    rm -f /etc/docker/daemon*
  elif [[ $(cat /etc/*-release | grep -w ID) == 'ID=debian' ]]; then
    apt-get remove docker* -y &> /dev/null
    apt-get remove docker-ce -y &> /dev/null
  else
    printf "\nCouldn't figure out OS"
    exit
  fi
} 

clean_yum(){
  yum clean all
  yum-complete-transaction
}

remove_weavescope(){
  rm -f /usr/local/bin/scope &> /dev/null
}

remove_ansible(){
  yum remove anisble-tower\*
  yum -y remove rabbitmq-server
  rm -rf /etc/tower /var/lib/{pgsql,awx,rabbitmq}
  yum remove -y ansible-tower-*
  yum remove -y postgresql*
  yum remove -y nginx*
  rm -rf /etc/nginx
  rm -rf /opt/ansible*
}

remove_hosts(){
  sed -i '/cdemo/d' /etc/hosts
  sed -i '/conjur/d' /etc/hosts
  sed -i '/okd/d' /etc/hosts
}

remove_openshift(){
  yum -y remove centos-release-openshift-origin*
  yum -y remove origin-*
  rm -Rf /opt/openshift
}
main