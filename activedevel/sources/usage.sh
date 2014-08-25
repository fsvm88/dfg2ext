#This file collects usage/debug/print instructions for the script

#Shows usage
function showusage () {
	eerror "Usage: `basename $0` options (-flmMpc)"
	eerror "At least -p <partition> is required!"
	eerror "Thresholds are defined in number of files"
	eerror "-option (default), description"
	eerror "-c (NN), enables md5 checks during defrag to ensure data consistency"
	eerror "-f (15), maximum number of loops to spend on a single file before going ahead (if no other blocking condition occours)"
	eerror "-l (2), maximum number of loops to execute with no benefit before stopping"
	eerror "-m (0), minimum number of fragmented files to start defragmenting"
	eerror "-M (NS), minimum number of fragmented files to stop defragmenting (how many files you want to keep fragmented even if the script could continue)"
	eerror "-p (NS), partition that shall be defragmented"
	eerror "-h, this help"
	eerror "Notes: -M option will result in at least one loop being executed anyway"
	eerror "Notes: -f option will be considered only with root access"
}

show_exclusion_warnings () {
	ewarn "NOTE: Next lines of warning will be shown until \
	you change EXADV variable to 1 at the \
	beginning of this script or create the exclusion file."
	ewarn "Usually you might want to add big files (>1Gb)."
	ewarn "If you want to defragment also loopback filesystems, \
	it is NEEDED to unmount them first."
	ewarn "If you need to create the exclusions file follow these steps:"
	ewarn "Complete path to exclusions file: $DFGDIR/$EXFILE"
	ewarn "cd $1"
	ewarn "touch $2"
	ewarn 'echo "/path-to-file/file-to-exclude" >>' $2
	ewarn "The script won't continue unless you define exclusions list or modify EXADV variable.\
	This is for safety reasons."
	ewarn "Copying and mv-ing a mounted loopback filesystem or something that's being modified \
	as the script runs WOULD PROBABLY result in LOSS OF DATA."
	ewarn "Also, since version 0.5.0.0.3 MD5 checksums have been integrated \
	to prevent such situations. They're not default, though."
	ewarn "Please DO exclude huge files (>~300Mb). \
	Probably they will be correctly defragmented and somehow the filesystem \
	will reduce the number of fragments but they will put your system under HEAVY \
	load and possibly make it unresponsive. \
	Put some loops together and you've got a defragmentation \
	that takes days instead of hours. \
	Note that these files may never be completely defragmented \
	(total fragments = 1) and obviously appear \
	in all the loops (INFINITE defrag times)."
	eerror "Exiting"
	exit 1
}

#Print number of lines to defragment
function showlines () {
	LINES=`wc -l frag$FCOUNT | sed 's/[^0-9][A-z]*.*//g'`
	einfo "Number of lines: $LINES"
}

#Update screen after each file
function update_screen () {
	printf "(%d/%d),file:%s               \r" "$1" "$2" "$3";
}

#Update screen after each loop
function update_loops () {
	printf "\nLoops executed: %2d, min loops to end: %2d\n" "$1" "$2";
}