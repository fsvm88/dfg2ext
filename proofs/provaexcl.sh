#!/bin/bash

. /sbin/functions.sh

cd $HOME/.dfg
EXFILE=exfile-sda7

if [ -s $EXFILE ]; then
	ebegin "Loading exclusions from file"
	while read linex; do
		EXVARS=$EXVARS$linex\\n
	done < $EXFILE
	eend $?
else
	eerror "Exclusion file $EXFILE does not exist. Please fill it in with the files you need to exclude"
	ewarn "If you want to defragment also loopback filesystems, since version 0.4 it is NEEDED to unmount them first."
fi

echo -e "$EXVARS"