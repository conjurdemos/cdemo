#!/bin/bash

main() {
        printf "\n\nValue for %s is: %s\n\n" "DB_PWD" $DB_PWD

        TEMPLATE=tomcat.xml.erb
        printf -v SED_STRING "s=@database_password=%s=g" $DB_PWD
        OUTPUT=$(cat $TEMPLATE)
        OUTPUT1=$(sed $SED_STRING <<< "$OUTPUT")
        echo "$OUTPUT1" > temp.out

        printf "\n\nContents of processed template:\n"
        cat $"temp.out"
        printf "\n\n"
	rm temp.out
}

main $@
