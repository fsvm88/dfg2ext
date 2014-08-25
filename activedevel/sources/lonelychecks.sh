#This file contains functions used to check some conditions that will be checked only once

#Called by checkargs(), checks if partition contains a valid filesystem
function checkpart () {
	TEMP=`mount | grep "$1" | grep -e "ext[23]"`
	if [ "$TEMP" != "" ]; then
		einfo "Detected supported filesystem on partition"
		#Extract the friendly name of the partition to defragment
		FPART=`echo $1 | sed 's./dev/..g'`
	else
		eerror "Failure in detecting correct filesystem!"
		eerror "Probably the selected partition doesn't contain a valid ext2/3 filesystem!"
		eerror "Script will now exit!"
		exit 2
	fi
}

#Check if we are root or not
function checkroot () {
	if [ $1 != "root" ]; then
		ewarn "Your home directory is not root one!"
		ewarn "Your home directory is $HOME!"
		ewarn "When defragmenting I will defragment only files in your home directory!"
		ewarn "Also, minimum fragmentation threshold will not be taken into account, since we're defragmenting just a set of files"
		ROOTACC=0
	else
		einfo "Root access granted"
		ROOTACC=1
	fi
}

#Check whether we are defragmenting root filesystem
function checkrootfs () {
	FSYS=`mount | grep $1 | sed 's/.*on.//' | sed 's/.type.*//'`
	ROOTFS=0
	if [[ $FSYS == "/" ]]; then
		einfo "Defragmenting root filesystem, no need to add extra path"
		ROOTFS=1
	elif [[ $FSYS != "/" ]]; then
		einfo "This is not the root filesystem, extra path will be added"
		ROOTFS=0
	fi
}

#Check if dfg directory exists
function checkprogdir () {
	if [ -d $1 ]; then
		einfo "Directory present"
		cd "$1"
#		cleanup
	else
		ebegin "Directory does not exist, creating"
			mkdir "$1"
			cd "$1"
		eend $?
	fi
	cd "$1"
}

#Check if cdavl is installed. If it's not, exit
function checktools () {
	if [ -x $1 ]; then
		einfo "davl tools have been successfully detected!"
	else
		eerror "davl tools are not installed! dfg cannot work without them! Please emerge them!"
		exit 1
	fi
}