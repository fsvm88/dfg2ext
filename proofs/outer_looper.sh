#!/bin/bash

. /sbin/functions.sh

CONTINUE=1
ROOTACC=1
MINIMUM=0
MAXIMUM=0
NCOUNTER=0
LINES=1
ARRAY[0]=12
ARRAY[1]=25
ARRAY[2]=50
ARRAY[3]=75
ARRAY[4]=100

inner_looper () {
	einfo "Inner looper gets executed"
}

inner_looper
if [ "$MINIMUM" -gt "-1" -a "$ROOTACC" -eq "1" ]; then
	einfo "First if gets executed"
	if [ "$MINIMUM" -le "$LINES" ]; then
		einfo "Minimum is less or equal than lines"
		while [ "$CONTINUE" -eq "1" ]
		do
			einfo "(1) Executing while loop"
			ARRAY[$NCOUNTER]=$LINES
			let NCOUNTER++
			if [ "$NCOUNTER" -ge "3" ]; then
				if [ ${ARRAY[$NCOUNTER-1]} -ge ${ARRAY[$NCOUNTER-2]} ] && [ ${ARRAY[$NCOUNTER-2]} -ge ${ARRAY[$NCOUNTER-3]} ]; then
					einfo "(2) Three loops have gone without any benefit from defragmentation"
					einfo "(2) The script will stop now"
					CONTINUE=0
				else
					einfo "(2) Continuing script (non-stop loop)"
					CONTINUE=1
				fi
			fi
			if [ "$NCOUNTER" -gt "1" ]; then
				if [ "$CONTINUE" -eq "1" ]; then
					if [ "$MAXIMUM" != "" ] && [ ${ARRAY[$NCOUNTER-1]} -lt $MAXIMUM ]; then
							einfo "(2) Desired maximum threshold has been reached, the script will stop now"
							CONTINUE=0
					fi
				fi
			fi
			if [ "$CONTINUE" -eq 1 ]; then
				#defragment
				einfo "(3) Setting continue to 1 after defrag"
				inner_looper
				CONTINUE=1
			fi
		done
	else
		einfo "The number of fragmented files is below the defined threshold"
		einfo "The script will stop now"
		exit 0
	fi
elif [ "$ROOTACC" -eq "0" ]; then
	einfo "Second if gets executed"
		while [ "$CONTINUE" -eq "1" ]
		do
			einfo "(1) Executing while loop"
			ARRAY[$NCOUNTER]=$LINES
			if [ "$NCOUNTER" -ge 3 ]; then
				if [ "${ARRAY[$NCOUNTER-1]} -ge ${ARRAY[$NCOUNTER-2]}" -a "${ARRAY[$NCOUNTER-2]} -ge ${ARRAY[$NCOUNTER-3]}" ]; then
					einfo "(2) Three loops have gone without any benefit from defragmentation"
					einfo "(2) The script will stop now"
					CONTINUE=0
				else
					einfo "(2) Continuing script (non-stop loop)"
					CONTINUE=1
				fi
			fi
			if [ "$CONTINUE" -eq 1 ]; then
				#defragment
				einfo "(3) Setting continue to 1 after defrag"
				inner_looper
				CONTINUE=1
			fi
			let NCOUNTER++
		done
fi