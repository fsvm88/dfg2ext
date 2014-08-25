#This file contains the two main loops that compose program structure

#Version 0.5.0.0.3: ADD: loopifying script!
#Generates list everytime, should be called inside other functions such as outer_looper
function inner_looper () {
	genlist $PART $ROOTACC $FSYS $DAVLEXEC
	checkdirs $FPART
	showlines
}

function outer_looper () {
#Initialize variables before going to loop
STOPCOUNT=0
#Call inner_looper to generate the file list and obtain the number of lines
inner_looper
#If $MINIMUM is initialized to a proper value and if the script gets executed with root privileges, \
#take into account also MINIMUM and MAXIMUM thresholds.
#This is because we have no way to determine how many fragmented files will be \
#in the user directory BEFORE having the commandline options.
#If this isn't taken into account, since generating the list of files requires some time \
#also on faster systems, a bored/unexperienced user \
#may be tricked into thinking that it's a script bug if he has set proper values but the script doesn't follow his rules.
#Check if MINIMUM and ROOTACC...
if [[ $MINIMUM -gt -1 && $ROOTACC -eq 1 ]]; then
#	einfo "First if gets executed"
	#Check if MINIMUM is less or equal than LINES, if it is we shall defragment. Otherwise go straight to exit.
	if [[ $MINIMUM -le $LINES ]]; then
#		einfo "Minimum is less or equal than lines"
		while [ $CONTINUE -eq 1 ]
		do
			#Update last array position with newer lines info
			ARRAY[$NCOUNTER]=$LINES
			
			#Check if the counter is greater than or equal than 2
			#If it is, then we can check when defragmentation apports no benefit and increase \
			#STOPCOUNT that holds information on how many loops have gone without benefit.
			#Note that this isn't the conditional that triggers the exit from the loop, that conditional is ahead.
			if [[ $NCOUNTER -ge 1 ]]; then
				#If -1 defrag pass is greater than -2 defrag pass
				if [[ ${ARRAY[$NCOUNTER]} -ge ${ARRAY[$NCOUNTER-1]} ]]; then
					CONTINUE=1
					let STOPCOUNT++
				else
					CONTINUE=1
				fi
			fi
			
			#Check if the counter is greater or equal than 1
			#If it is, and CONTINUE is not already set to trigger the exit from the loop (0), \
			#if MAXIMUM is set and the last defragmentation was already under \
			#threshold, we inform the user that the script will stop because the maximum threshold has been \
			#reached, then we set CONTINUE to 0.
			#Note that since inner_looper gets re-executed after defrag and the COUNTER is \
			#incremented _after_ the end of the loop \
			#we need to check COUNTER-1 element of the array, _not_ COUNTER
			#AA: This triggers the exit from the loop.
			if [[ $NCOUNTER -ge 1 ]]; then
				if [[ $CONTINUE -eq 1 ]]; then
					if [[ $MAXIMUM != "" && ${ARRAY[$NCOUNTER]} -lt $MAXIMUM ]]; then
							einfo "Desired maximum threshold has been reached, the script will stop now"
							CONTINUE=0
					fi
				fi
			fi
			
			#FIXED: Rescheduled: should come right after the benefit-check above to avoid unneeded loops when variable has been already incremented.
			#AA: This triggers the exit from the loop after the benefit-check above.
			if [[ $STOPCOUNT -eq $CTOSTOP ]]; then
				einfo "The script has looped $STOPCOUNT times without adding any benefit, the script will stop now"
				CONTINUE=0
			fi
			
			#If previous checks were successful, then CONTINUE should be set to 1.
			#If is so, run defragment, re-execute analysis and ensure CONTINUE is still set to 1 to rerun the checks.
			if [[ $CONTINUE -eq 1 ]]; then
				defragment__with_edm
				inner_looper
				CONTINUE=1
			fi
			
			#Increment the COUNTER variable. This is used to keep the array synched to the loop. MUST be the last action.
			let NCOUNTER++
		done
	#If the partition is already defragmented the way the user wants it just get rid of defragmenting
	#Note: such condition DOESN'T exist in limited-user mode below.
	else
		einfo "The number of fragmented files is below the defined threshold"
		einfo "The script will stop now"
	fi
#If the script is not executed with root privileges, avoid checking for MINIMUM and MAXIMUM thresholds (discard them)
elif [[ $ROOTACC -eq 0 ]]; then
#	einfo "Second if gets executed"
		while [ $CONTINUE -eq 1 ]
		do
			#einfo "(1) Executing while loop"
			#Update last array position with newer lines info
			ARRAY[$NCOUNTER]=$LINES
			
			#Check if the counter is greater than or equal than 2
			#If it is, then we can check when defragmentation apports no benefit and increase STOPCOUNT that holds information \
			#on how many loops have gone without benefit
			#Note that this isn't the conditional that triggers the exit from the loop, that conditional is ahead.
			if [[ $NCOUNTER -ge 1 ]]; then
				if [[ ${ARRAY[$NCOUNTER]} -ge ${ARRAY[$NCOUNTER-1]} ]]; then
					CONTINUE=1
					einfo "(2) Increasing STOPCOUNT: $STOPCOUNT"
					let STOPCOUNT++
				else
					einfo "(2) Continuing script (non-stop loop)"
					CONTINUE=1
				fi
			fi
			
			#FIXED: Rescheduled: should come right after the benefit-check above to avoid unneeded loops when variable has been already incremented.
			#AA: This triggers the exit from the loop after the benefit-check above.
			if [[ $STOPCOUNT -eq $CTOSTOP ]]; then
				einfo "(2) The script has looped $STOPCOUNT times without adding any benefit, the script will stop now"
				CONTINUE=0
			fi
			
			#If previous checks were successful, then CONTINUE should be set to 1.
			#If is so, run defragment, re-execute analysis and ensure CONTINUE is still set to 1 to rerun the checks.
			if [[ $CONTINUE -eq 1 ]]; then
				defragment
				einfo "(3) Setting continue to 1 after defrag"
				inner_looper
				CONTINUE=1
			fi
			
			#Increment the COUNTER variable. This is used to keep the array synched to the loop. MUST be the last action.
			let NCOUNTER++
		done
fi
}
