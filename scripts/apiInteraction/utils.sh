#!/bin/bash

function pause(){
  read -p "$*"
}

function urlify(){
  local str=$1; shift
  str=$(echo $str | sed 's= =%20=g')
  str=$(echo $str | sed 's=/=%2F=g')
  str=$(echo $str | sed 's=:=%3A=g')
  URLIFIED=$str
}

function menu(){
  PS3='Please enter your choice: '
  options=("Jenkins" "Webapp" "Tomcat")
  select opt in "${options[@]}"
  do
    case $opt in
      "Jenkins")
        id=jenkins
        break
        ;;
      "Webapp")
        id=webapp
        break
        ;;
      "Tomcat")
        id=tomcat
        break
        ;;
    esac
  done
  echo $id       
}
