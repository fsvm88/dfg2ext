#!/bin/bash

. /sbin/functions.sh

while getopts ":m:M:p:" opt
do
	case $opt in
#		[eunDN] ) param+=$opt;;
#		[bBgGkK] ) param+=$opt; binOpt+=$opt;;
		m ) echo "Scenario #1: option -m-   [OPTIND=${OPTIND}] PARAMETER=$((OPTIND+1)) $OPTARG";;
		M ) echo "Scenario #2: option -M-   [OPTIND=${OPTIND}] PARAMETER=$((OPTIND+1)) $OPTARG";;
		p ) echo "Scenario #3: option -p-   [OPTIND=${OPTIND}] PARAMETER=$((OPTIND+1)) $OPTARG altro";;
		* ) echo "Default";;
	esac
done

shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non option item supplied on the command line
#+ if one exists.

exit 0