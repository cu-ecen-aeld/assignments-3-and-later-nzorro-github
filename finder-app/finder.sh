#!/bin/bash

###
# finds an argument tofind within the filepath directories and subdirectories
find()
{
    filepath=$1
    tofind=$2
    number_of_files=0
    number_of_matches=0
    [ -z "$filepath" ] && echo "File path not given!" && exit 1
    [ -z "$tofind" ] && echo "No argument to search provided!" && exit 1
    
    [ ! -d "$filepath" ] && echo "$filepath is  not a directory"  && exit 1

    if [ -d "$filepath" ] ; then
	basedir="${filepath}"
    else
    	basedir="$(dirname $filepath)"
    fi	
    for file in "${basedir}"/*; do
	#echo "file-> $file <-"
        if [ -n "$file" ] ; then
            matches=$(grep -i "$tofind" "$file" | wc -l)
            number_of_matches=$(( $number_of_matches + $matches ))
            number_of_files=$(( $number_of_files + 1 ))
    	fi
    done
    echo "The number of files are $number_of_files and the number of matching lines are $number_of_matches"
}

find "$1" "$2"
