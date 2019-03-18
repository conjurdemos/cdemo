#!/bin/bash

main (){  
  echo " Stopping $1 containers"
  docker container rm -f $(docker container ls -f name=$1* -aq)
}

main $1