#!/bin/bash

source ./utils.sh

main (){
  echo "Starting sub Process create_hftoken"
  create_hftoken $1
}

main $1