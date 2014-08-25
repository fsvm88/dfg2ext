#!/bin/bash
. /sbin/functions.sh
. ./sources/misc.sh
. ./sources/dfgedm.sh
. ./sources/dfgnoedm.sh
. ./sources/edmspecs.sh
. ./sources/exclusions.sh
. ./sources/listgen.sh
. ./sources/lonelychecks.sh
. ./sources/loops.sh
. ./sources/parseargs.sh
. ./sources/usage.sh

#dfg - a defrag script with "advanced" features
#Author: Neo2
#License: GPLv3
#Version: 0.5.0.0.4
#Contact info: Neo2 on http://forums.gentoo.org/

#Tips for good programming
#	syntax cleanup:
#		-> use ' and " where needed in the best way possible (even when in checks like: "$variables")
#		-> recheck conditional checks and ensure brackets ([ ]) are used in the best way possible
#		-> trace any bugs with the looping structure, though it should work fine
#		-> trace possible unwanted behaviours when using spaces and escape characters in variables

#Last thing to do:
#port to C/C++ to speed things up with conditionals and simplify program's structure (it'll behave exactly like this)

#Lines marked with "-----" have been already integrated (showing progress of the work)
#TODO:
#-	(+): CLEANUP: rework list generation
#	(+): ADD: release cdavl patch
#	(+): ADD: implement sorting of list by filesize. this would reduce free space fragmentation somehow and allow \
#				for larger files to be defragmented better with lesser passes
#---	(+): ADD: implement functions called with arguments, so that we are sure that every function executes \
#				with minimum privileges on script's structure
#--	(+): CLEANUP: Optimize displaying of menus, warnings etc to fit in a shell line of 640x480~1024x768 (I'm programming in 1600x1200)
#----	(+): FIX: general reschedule of the functions and of the program itself
#-	(+): FIX: better error handling for functions
#--- 	(+): FIX: optimize long command sequences (grep | sed | sed | sed) if there's a smarter way to do the same things, \
#				would speed things up

#Version 0.5.0.0.4:
#     (+): CLEANUP: remove comments about deprecated code at some version, making script clearer to read \
#					-> prunning <=0.5.0.0.3

#Version 0.5.0.0.3 (2008-06-23):
#	(+): FIX: make some progress bar/x% number appear instead of boring "x lines of y" (also algorithm is not the best one)
#	(+): FIX: implement a patch in davl tools (requiring new version being released and so on) \
#				to enable the generation of a simple list like this script does without having to parse it anymore (HUGE SPEEDUP LITTLE WORK)
#	(+): FIX: now checkdirs actually checks if dir file has already been generated before, avoids useless work
#	(+): FIX: general reschedule of the functions (lots of one-run checks reintegrated into inner functions, \
#				very little overhead); code reduced by ~15-20%
#	(+): ADD: EDM (Enhanced Defrag Mode) \
#				-> basically implemented through filefrag, allowable only for root (FIBMAP ioctl used by filefrag is available only via root), \
#					no toggling available (don't see why anybody would disable this)
#				-> allows per-file looping instead of simple looping allover the list. Result? more defragmented files per pass without having to regen
#					the list (saves _incredible_ amounts of time)
#				-> max number of iterats per-file can be selected, exits automatically \
#					(*) when fragments = 1 \
#					(*) fragments = perfection (no perfection reported) \
#					(*) iterats > max_iterats (defaults to 15 if unset, allowable max to 30, autoadjusted if above)
#	(+): ADD: implement filefrag approach, allows to generate list a lot less times (now called EDM)
#	(+): ADD: introduced DAVLEXEC to handle non-standard installs
#	(+): CHANGED: checkrootdir() is now checkprogdir()
#	(+): FIX: rescheduled behaviour of checkdirs(), now it sorts and uniq's the file only once
#	(+): FIX: rescheduled behaviour of defrag() and defrag_with_md5()
#	(+): CLEANUP: introduced copyfile(), movefile(), delstale(), removes dependency on particular commands, \
#						allows clear script reading
#	(+): FIXED: reworked some on-screen display, now showing per-line progress, no more incredibly long listings
#	(+): FIXED: fixed behaviour with checkdirs(), now we sort and uniq the file so that we don't have gigabyte-file anymore
#	(+): FIXED: applied some hd-saving when in genlist(), now we always reuse same files
#	(+): FIXED: major out-of-one errors on loop structure
#	(+): ADD: added md5sum checks, created parallel defragment_with_md5() to avoid runtime conditional check when md5 check is not enabled. \
#			extended conditional tests during outer_looper() so that defragment_with_md5() gets properly executed. \
#			added commandline option "-c" to enable md5 checks. \
#			we are sure that the file we've copied is the same of the original one (MIGHT SLOW THINGS DOWN NOTICEABLY)
#	(+): FIXED: minor bugfixes on comparisons and conditional tests
#	(+): FIXED: rescheduled genlist() and checktools() to enable multiple list of files to be generated
#	(+): ADD: implemented commandline parsing
#	(+): ADD: implemented looping of the script with minimum and maximum threshold and automatic stop when no benefit
#Version 0.5.0.0.2 (2008-02-01):
#	(+): CLEANUP: remove comments about deprecated code at some version, making script clearer to read
#	(--): REMOVE: removing parsefiles function, along with directory filtering in genlist() and unneeded variables
#	(+): ADD: integrated checkdirs(), now working properly
#Version 0.5.0.0.1 (end-2007):
#	(+): FIXED: find some way easier/safer than $HOME variable to determine current user (whoami should do)
#	(+): FIXED: make functions that generate simple checks return some status variable instead of re-checking everytime the same things
#	(+): FIXED: now lines-to-defragment with spaces in it (/foo/bar biz) are handled correctly (caused corrupted/nonsense "bar.unfragmented" files)
#	(+): FIXED: rescheduled genlist()
#	(+): FIXED: loop files exclusions
#	(+): CHANGED: introduced new naming scheme format (x.x.x.x) instead of old one (x.x), by 31st of December we would have been to version 10.0 :P
#Version 0.5:
#	(+): ADD: now using functions (should be more readable and flexible)
#	(+): FIX: rescheduled behaviour of some commands (mainly filters)
#Version 0.4 (mid-2007):
#	(+): ADD: adding pseudo-graphics and porting to coloured output
#	(+): ADD: automatic exclusions for loopback filesystems
#Version 0.3:
#	(+): ADD: readding user-defined exclusions
#Version 0.2: modified mv behaviour,
#	(--): REMOVAL: removing need of exclusions
#	(+): FIXED: minor fixups
#	(+): FIXED: speed improvements
#Version 0.1 (late 2006):
#	(=): basic script

#Here follow variables
#[variables]
#Dfg home dir
DFGDIR=$HOME/.dfg
#Current defrag line during process
CLINE=0
#Total number lines count
LINES=0
#Temporary frag(x) file count
FCOUNT=0
#Exclude file
#EXFILE=exfile-$FPART
#Next variable controls the showing of advanced warnings and thus the working of the script itself
EXADV=1
#Initialization for some variables
EXVARS=""
ROOTACC=0
DETACC=`whoami`
NO_ARGS=0
E_OPTERROR=65
PART=`mount | grep "$CPART" | grep -e "ext[23]"`
CONTINUE=1
NCOUNTER=0
DAVLEXEC="/usr/bin/cdavl"
#MINIMUM=-1
#[/variables]

#***************************************************************************************************************************************
#****HERE FOLLOWS SCRIPT SEQUENCE (formerly "main" function)
#****ALL FUNCTIONS SHOULD BE WRIT ABOVE THIS POINT
#****IF YOU WISH TO HAVE A FUNCTION BE EXECUTED DURING SCRIPT'S RUN MODIFY THE ORDER BELOW
#****PLEASE ADD A SHORT COMMENT ABOUT THE OPERATIONS THE CALLED FUNCTION WILL EXECUTE 
#***************************************************************************************************************************************
einfo "Script beginning"
#Need to check the user that's running the script
checkroot $DETACC
#Parse commandline options
if [ $# == 0 ]; then  # Script invoked with no command-line args?
	showusage
	exit 2        # Exit and explain usage, if no argument(s) given.
fi

while getopts ":f:l:m:M:p:c" Option
do
	case $Option in
	c  ) einfo "You have chosen to run the program with md5sum checks!"
			einfo "This will be safer but somewhat slower!"
			WMD5=1;;
	f   ) ewarn "You have selected explicitly the maximum number of runs on per-file basis"
			ewarn "Setting this value too high might lead to infinite defrag times"
			ewarn "or to your disk being filled up"
			ewarn "If above 30, the value will be automatically adjusted"
			MAX_PERFILE=$OPTARG;;
	h  ) showusage
		exit 0;;
	l   ) einfo "Maximum loops to execute when no benefit:  $OPTARG"
			CTOSTOP=$OPTARG;;
	m ) einfo "Minimum threshold to begin defragmenting:   $OPTARG"
			MINIMUM=$OPTARG;;
	M ) einfo "Maximum threshold under which defragmentation will stop:   $OPTARG"
			MAXIMUM=$OPTARG;;
	p ) PART=$OPTARG
			einfo "Partition:   $PART"
			checkpart $PART;;
	* ) echo "Unimplemented option chosen. Exiting..."
			exit 1;;   # DEFAULT
	esac
done
shift $(($OPTIND - 1))
defaulting
keep_values_in_range
#Need to check the presence of the directory
checkprogdir $DFGDIR
#First cleanup is now run from inside checkrootdir(), makes no sense to cleanup a brand new directory
#cleanup
#Are the needed tools present?
checktools $DAVLEXEC
#Need to know if it's root filesystem
checkrootfs $FPART
#Configuring exclusions variables
loadexcl $FPART $DFGDIR
loopexcl
#Get a pause
sync
sleep 1
#All conditions met --> generate the list of files to be defragmented + show initial data
#genlist
#checkdirs
#showlines
if [[ $WMD5 -eq 0 ]]; then
	einfo "Skipping MD5 checks!"
elif [[ $WMD5 -eq 1 ]]; then
	einfo "MD5 checks activated!"
fi
outer_looper
#debug
#Now called from inner_looper and outer_looper
#Now defragment them
#defragment
#Final cleanup
#cleanup
einfo "Script ended without fatal errors."
exit 0
