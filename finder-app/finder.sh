#!/bin/sh

filesdir=$1
searchstr=$2
n=2
x=0
y=0

if [ $# -ne $n ] 
then
	echo "There is a missing parameter"
	exit 1 
else
	y="$(grep -r $searchstr $filesdir -c | awk -F: '{sum+=$2} END {print sum}')"
	x="$(grep -rl $searchstr $filesdir | wc -l)"
	echo "The number of files are ${x} and the number of matching lines are ${y}"	
fi


