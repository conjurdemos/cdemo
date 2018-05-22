#!bin/bash

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
