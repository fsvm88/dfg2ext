#!/bin/bash

. /sbin/functions.sh

a=0
while [[ $a -ne 10 ]]; do
	echo -e "$a\r"
	let a++
done