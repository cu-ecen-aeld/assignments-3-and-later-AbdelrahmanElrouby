#!/bin/sh

writefile=$1
writestr=$2

# Get the directory path from the file path
dir_path=$(dirname "$writefile")

# Check if the directory exists, if not, create it
if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path"
fi

if [ $# -ne 2 ]
then
	echo "There is a missing parameter"
	exit 1 
else
	echo $writestr > $writefile
fi

