#!/bin/bash

main() {
        printf "\n\nValue for %s is: %s\n\n" "DB_PWD" $DB_PWD
        read -n 1 -s -p "Press any key to continue"
}

main $@
