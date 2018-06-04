#!/bin/bash

main (){  
  echo " Stopping $1 containers"
  docker container rm -f $(docker container ls -f name=$1* -q)
}

main $1