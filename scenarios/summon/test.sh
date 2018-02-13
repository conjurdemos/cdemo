#!/bin/bash
printf "\n\nDB_PWD: $DB_PWD\n"
printf "DB_PWD_FILE: $DB_PWD_FILE\n"
printf "Contents of $DB_PWD_FILE: %s\n" $(cat $DB_PWD_FILE)
printf "\nLITERAL: $LITERAL\n"
printf "LITERAL_FILE: $LITERAL_FILE\n" 
printf "Contents of $LITERAL_FILE: %s\n\n" $(cat $LITERAL_FILE)
