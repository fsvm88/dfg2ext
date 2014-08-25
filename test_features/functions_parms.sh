#!/bin/bash

. /sbin/functions.sh

function stupid () {
	return 1;
}

stupid

if [[ "$?" -eq 1 ]]; then
	echo "Stupid!"
fi
