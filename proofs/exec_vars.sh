#!/bin/bash

. /sbin/functions.sh


function call_cdavl () {
	$1
}

DAVLEXEC="/usr/bin/cdavl"

call_cdavl $DAVLEXEC
