#!/bin/bash

#Author: Neo2
#License: GNU/GPL
#Version: 0.5

. /sbin/functions.sh

#TODO:
#----- (+): FIX: make functions that generate simple checks return some status variable instead of re-checking everytime the same things
#	(+): FIX: general reschedule of the functions and of the program itself
#	(+): FIX: make some progress bar/x% number appear instead of boring "x lines of y" (also algorithm is not the best one)
#----- (+): FIX: find some way easier/safer than $HOME variable to determine current user (whoami should do)
#	(+): FIX: better error handling for functions
#	(+): FIX: optimize long command sequences (grep | sed | sed | sed) if there's a smarter way to do the same things, would speed things up
#	(+): CLEANUP: remove comments about deprecated code at some version, making script clearer to read
#	(+): ADD: enable script to use input commandline parameters instead of just using hardcoded ones
#	(+): ADD: enable script to loop until a defined threshold is reached (max # of frag. files less than threshold)
#					or when several passes have run without any benefit (max # of frag. files NEVER less than threshold, possible infinite loop)
#	(+-): ADD/REMOVE: instead of using dirs-exclusions, check every file for being or not a directory on-the-fly (removes need of dirs-file)


#Version 0.5.0.0.1:
#	(+): FIXED: find some way easier/safer than $HOME variable to determine current user (whoami should do)
#	(+): FIXED: make functions that generate simple checks return some status variable instead of re-checking everytime the same things
#	(+): FIXED: now lines-to-defragment with spaces in it (/foo/bar biz) are handled correctly (caused corrupted/nonsense "bar.unfragmented" files)
#	(+): FIXED: rescheduled genlist function
#	(+): FIXED: loop files exclusions
#	(+): CHANGED: introduced new naming scheme format (x.x.x.x) instead of old one (x.x), by 31st of December we would have been to version 10.0 :P
#Version 0.5:
#	(+): ADD: now using functions (should be more readable and flexible)
#	(+): FIX: rescheduled behaviour of some commands (mainly filters)
#Version 0.4:
#	(+): ADD: adding pseudo-graphics and porting to coloured output
#	(+): ADD: automatic exclusions for loopback filesystems
#Version 0.3:
#	(+): ADD: readding user-defined exclusions
#Version 0.2: modified mv behaviour,
#	(--): REMOVAL: removing need of exclusions
#	(+): FIXED: minor fixups
#	(+): FIXED: speed improvements
#Version 0.1:
#	(=): basic script

#Here follow variables
#Dfg home dir
DFGDIR=$HOME/.dfg
#[0.1]
#Next two variables are needed just to make EXVARS more flexible
#Set the architecture bits where dfg is supposed to run (for /lib** directory)
#ARCH=64
#Set the glibc version installed on your sistem (if you have multiple versions, only the one that is currently in use is needed)
#GCV=2.5
#[/0.1]
#The partition we want to defragment and extract its friendly name
PART=/dev/sda7
FPART=`echo $PART | sed 's/\/dev\///g'`
#Current defrag line during process
CLINE=0
#Total number lines count
LINES=0
#Temporary frag(x) file count
FCOUNT=0
#Exclude file
EXFILE=exfile-$FPART
DIRF=dirs-$FPART
#[0.1]
#Default exclusions.
#!WARNING WARNING WARNING!
#Leave /lib$ARCH/libc and /lib$ARCH/ld- in EXVARS else you'll screw up your sistem! Those files are libc binaries and are needed by any program. You will have to reboot with livecd and mv libc and ld-x.x.so
#/mnt/ is now excluded by default since cdavl performs analysis same line or by expanding the variable on multiple lines.
#You can also manually edit the exclude file.
#The separator for variables is the newline character.
#EXVARS="/dev/\\n/mnt/\\n/lib$ARCH/libc-$GCV.so\\n/lib$ARCH/ld-$GCV.so"
#EXVARS="/dev/\\n/lib$ARCH/libc-$GCV.so\\n/lib$ARCH/ld-$GCV.so\\n/bin/mv\\n/bin/cp\\n/bin/rm"
#[/0.1]
#Next variable controls the showing of advanced warnings and thus the working of the script itself
EXADV=1
EXVARS=""
ROOTACC=0
DETACC=`whoami`

#Check if we are root or not
checkroot () {
	if [ $DETACC != "root" ]; then
		ewarn "Your home directory is not root one!"
		ewarn "Your home directory is $HOME!"
		ewarn "When defragmenting I will defragment only files in your home directory!"
		ROOTACC=0
	else
		einfo "Root access granted"
		ROOTACC=1
	fi
}

#Check whether we are defragmenting root filesystem
checkrootfs () {
	FSYS=`mount | grep $PART | sed 's/.*on.//' | sed 's/.type.*//'`
	if [ $FSYS == "/" ]; then
		einfo "Defragmenting root filesystem, no need to add extra path"
	elif [ $FSYS != "/" ]; then
		einfo "This is not the root filesystem, extra path will be added"
	fi
}

#Check if dfg directory exists
checkrootdir () {
	if [ -d $DFGDIR ]; then
		einfo "Directory present"
	else
		ebegin "Directory does not exist, creating"
			mkdir $DFGDIR
		eend $?
	fi
#Changing to directory
	cd $DFGDIR
}

cleanup () {
	ebegin "Deleting old temporary files"
	rm -Rf frag* dtmp* 2*
	sync
	eend $?
}

#Unneeded since version 0.2
#Reintroduced and modified in version 0.3
#Check if exclusions file exists: if it exists preload it, else warn user
loadexcl () {
	if [ -s $EXFILE ]; then
		ebegin "Loading exclusions from file"
		while read linex; do
			EXVARS=$EXVARS$linex\\n
		done < $EXFILE
		eend $?
	else
		eerror "Exclusion file $EXFILE does not exist. Please fill it in with the files you need to exclude"
		ewarn "If you want to defragment also loopback filesystems, since version 0.4 it is NEEDED to unmount them first."
		if [ $EXADV == 0 ]; then
			ewarn "NOTE: Next lines of warning will be shown until you change EXADV variable to 1 at the beginning of this script or create the exclusion file."
			ewarn "Usually you might want to add big files (>1Gb)."
			ewarn "If you want to defragment also loopback filesystems, it is NEEDED to unmount them first."
			ewarn "If you need to create the exclusions file follow these steps:"
			ewarn "Complete path to exclusions file: $DFGDIR/$EXFILE"
			ewarn "cd $DFGDIR"
			ewarn "touch $EXFILE"
			ewarn 'echo "/path-to-file/file-to-exclude" >>' $EXFILE
			ewarn "The script won't continue unless you define exclusions list or modify EXADV variable. This is for safety reasons."
			ewarn "Copying and mv-ing a mounted loopback filesystem or something that's being modified as the script runs WOULD PROBABLY result in LOSS OF DATA."
			eerror "Exiting"
			exit 1
		fi
	fi
}

#If necessary add mounted filesystems as exclusions
loopexcl () {
	FLOOPS=`mount | grep loop | sed 's/.on.*//' | sed 's/.type.*//' | grep -e "[0-9A-Za-z]"`
	if [ "$FLOOPS" != "" ]; then
		ebegin "Adding mounted loopback filesystems to exclusions list"
		EXVARS=$EXVARS$FLOOPS
		eend $?
	else
		einfo "No mounted loopback filesystem was detected"
	fi
}

#Check if cdavl is installed: if it is copy its data about desired partition, else exit
checktools () {
	if [ -x /usr/bin/cdavl ]; then
		cdavl -v $PART > frag$FCOUNT
	else
		eerror "davl tools are not installed! dfg cannot work without them! Please emerge it!"
		exit 1
	fi
}

genlist () {
	ebegin "Generating list of files to defragment"
	
	#Strip from cdavl output every line that doesn't contain " characters used to identify files
	grep '"' frag$FCOUNT > frag$(($FCOUNT+1))
	let FCOUNT++
	
	#Version 5.0.0.1: FIX: reschedule: unuseful to parse thousands of lines if they will not be used, lets grep them first
	#Strip files unable to be accessed from root if running in limited user mode
	if [ $ROOTACC == 0 ]; then
		einfo "Deleting files outside your directory from the list"
		grep "$HOME" frag$FCOUNT > frag$(($FCOUNT+1))
		let FCOUNT++
	fi
	
	#Strip from the lines everything that's not the pure filename. cdavl per-line output is in this format: "/foo/bar" (bar inode no.) is fragmented (bar statistics)
	sed 's/(.*//' frag$FCOUNT | sed 's/"//g' > frag$(($FCOUNT+1))
	let FCOUNT++
	
	#Strip files from exclusion variables
	if [ "$EXVARS" != "" ]; then
		einfo "Filtering exclusions"
		grep -v -e "$(echo -e "$EXVARS")" frag$FCOUNT > frag$(($FCOUNT+1))
		let FCOUNT++
	fi
	
	#Version 5.0.0.1: FIXED: adding backslashes where there are spaces is not needed anymore
	#sed 's/ /\\ /g' frag$FCOUNT | sed s:\/:$FSYS/: > frag$(($FCOUNT+1))
	#Add necessary path if it's not the root filesystem
	sed s:\/:$FSYS/: frag$FCOUNT > frag$(($FCOUNT+1))
	let FCOUNT++
	
	#Strip files from directory exclusions
	einfo "Integrating previous info from dirs file"
	if [ -s $DIRF ]; then
		comm -2 -3 frag$FCOUNT $DIRF | sed 's/\t//g' > frag$(($FCOUNT+1))
		let FCOUNT++
	else
		ewarn "No pre-existing dirs file was found! It will be generated at the end of this (first) run"
	fi
	
	#Sort the file before defragmenting
	sort frag$FCOUNT > frag$(($FCOUNT+1))
	let FCOUNT++
	
	eend $?
}

#Print number of lines to defragment
showlines () {
	LINES=$(wc -l frag$FCOUNT | sed 's/[^0-9][A-z]*.*//g')
	einfo "Number of lines: $LINES"
}

defragment () {
	ebegin "Specific file defragmentation"
	sync
	while read line; do
		sync
		let CLINE++
		if [ $[$CLINE%100] == 0 ]; then
			echo "$CLINE of $LINES"
		fi
		#[0.2]
		#Moved out of the loop, decreases temporal complexity
		#	if [ $CLINE == $LINES ]; then
		#		echo "$CLINE of $LINES"
		#	fi
		#[/0.2]
		#Copy
		cp --preserve=all "$line" "$line.unfragmented" 2>> 2cp
		sync
		#[0.2]
		#Delete fragmented, can be skipped since mv does the job anyway
		#	rm $line 2>> 2rm
		#[/0.2]
		#Move unfragmented over fragmented
		mv "$line.unfragmented" "$line" 2>> 2mv
		#Make sure there are no stale files around
		rm -Rf "$line.unfragmented" 2>> /dev/null
		#End loop
		sync
	done < frag$FCOUNT

	if [ $CLINE == $LINES ]; then
		echo "$CLINE of $LINES"
	fi
	sync
	eend $?
}

parsefiles () {
	#Parse error file(s) for further directory exclusion
	ebegin "Parsing error files for further incremental defrags"
	#Next line is obsolete since rm is not used anymore
	#if [ -a 2cp ] && [ -a 2rm ]; then
	if [ -s 2cp ]; then
		cat 2cp | sed 's/.*`//g' | sed "s/'.*//g" | grep -v "unfragmented" > dtmp1
	#Next line(s) is/are obsolete since rm is not used anymore
	#	cat 2rm | grep "Is a directory" | sed 's/rm: cannot remove `//g' | sed 's/: Is a directory//g' | sed s/\'//g | sed 's/\t//g' | sort > dtmp2
	#	comm dtmp1 dtmp2 | sed 's/\t//g' > dtmp3
		if [ -s $DIRF ]; then
			einfo "Previous data was found. Updating"
			comm -2 dtmp1 $DIRF | sed 's/\t//g' | grep -v "unfragmented" | sort > $DIRF
		else
			einfo "No previous data was found. Creating new data file"
			sort dtmp1 > $DIRF
		fi
	fi
	eend $?
}


#***************************************************************************************************************************************
#****HERE FOLLOWS SCRIPT SEQUENCE (formerly "main" function)
#****ALL FUNCTIONS SHOULD BE WRIT ABOVE THIS POINT
#****IF YOU WISH TO HAVE A FUNCTION BE EXECUTED DURING SCRIPT'S RUN MODIFY THE ORDER BELOW
#****PLEASE ADD A SHORT COMMENT ABOUT THE OPERATIONS THE CALLED FUNCTION WILL EXECUTE 
#***************************************************************************************************************************************
einfo "Script beginning"
#Need to check the user that's running the script
checkroot
#Need to check the presence of the directory + first cleanup
checkrootdir
cleanup
#Are the needed tools present?
checktools
#Need to know if it's root filesystem
checkrootfs
#Configuring exclusions variables
loadexcl
loopexcl
#Get a pause
sync
sleep 1
#All conditions met --> generate the list of files to be defragmented + show initial data
genlist
showlines
#Now defragment them
defragment
#Parse the error files for future defragmentations and exclusions
parsefiles
#Final cleanup
#cleanup
einfo "Script ended without fatal errors."
exit 0
