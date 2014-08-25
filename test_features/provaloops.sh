#!/bin/bash

. /sbin/functions.sh

EXVARS="prova\\n"

echo -e "Outer: $EXVARS"

FLOOPS=`mount | grep loop | sed 's/.on.*//' | sed 's/.type.*//' | grep -e "[0-9A-Za-z]"`
if [ "$FLOOPS" ]; then
	ebegin "Adding mounted loopback filesystems to exclusions list"
	EXVARS=$EXVARS$FLOOPS
	echo -e "Internal: $EXVARS"
	eend $?
else
	einfo "No mounted loopback filesystem was detected"
fi