#!/bin/bash

. /sbin/functions.sh

while read line; do
	sync
	let CLINE++
	if [ $[$CLINE%100] == 0 ]; then
		echo "$CLINE of $LINES"
	fi
	#Copy
	cp --preserve=all "$line" "$line.unfragmented" 2>> 2cp
	sync
	MD5SUMF=`md5sum "$line" | sed 's/ .*//'`
	MD5SUMU=`md5sum "$line.unfragmented" | sed 's/ .*//'`
	echo -e "Sums:\\n$MD5SUMF\\n$MD5SUMU"
	if [[ "$MD5SUMF" == "$MD5SUMU" ]]; then
		echo -e "Comparison ok!"
		#Move unfragmented over fragmented
		mv "$line.unfragmented" "$line" 2>> 2mv
		#Make sure there are no stale files around
		if [[ -e "$line.unfragmented" ]]; then
			echo "$line" >> hardexcluded
			rm -Rf "$line.unfragmented" 2>> /dev/null
		fi
	else
		echo "$line" >> hardexcluded
	fi
	#End loop
	sync
done < exfile-try