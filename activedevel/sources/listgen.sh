#This file contains functions specific to the generation of file list

#genlist $CPART $ROOTACC $FSYS

#Generate list of files
function genlist () {
	einfo "Generating list of files to defragment\r"
	
	#Avoid reusing same files when looping	(let FCOUNT++)
	#Now we want some economy, looping for many times maybe be deleterious
	FCOUNT=0
	#Version 0.5.0.0.3: FIXED: optimize long command sequences
	#Generate list of files and strip from cdavl output every line that doesn't contain " \
	#characters used to identify files (should be faster than separate versions)
	#Also strip /dev directory (we cannot defrag that dir)
	$DAVLEXEC -v "$1" | grep '"' | grep -v '"/dev/' > frag$FCOUNT
	
	#Strip files unable to be accessed from root if running in limited user mode
	if [[ $2 -eq 0 ]]; then
		einfo "Deleting files outside your directory from the list"
		grep "$HOME" frag$FCOUNT > frag$(($FCOUNT+1))
		let FCOUNT++
	fi
	
	#Strip from the lines everything that's not the pure filename.\
	#cdavl per-line output is in this format: "/foo/bar" (bar inode no.) is fragmented (bar statistics)
	sed 's/"(.*//' frag$FCOUNT | sed 's/"//g' > frag$(($FCOUNT+1))
	let FCOUNT++
	
	#Strip files from exclusion variables
	if [ "$EXVARS" != "" ]; then
		einfo "Filtering exclusions"
		grep -v -e "$(echo -e "$EXVARS")" frag$FCOUNT > frag$(($FCOUNT+1))
		let FCOUNT++
	fi
	
	#Version 0.5.0.0.3: Code syntax cleanup, added if checking before
	#Add necessary path if it's not the root filesystem
	if [ "$ROOTFS" -eq 0 ]; then
		sed s:\/:$3/: frag$FCOUNT > frag$(($FCOUNT+1))
		let FCOUNT++
	fi
	
	#If hardexcluded files exists it means that some files cannot be defragmented, thus exclude them automatically
	if [[ -e hardexcluded-$1 ]]; then
		einfo "Some previous loop determined that some files cannot be defragmented, excluding them\r"
		comm -2 -3 frag$FCOUNT hardexcluded-$1 > frag$(($FCOUNT+1))
		let FCOUNT++
	fi
	
	#Sort and uniq (should not be needed) the file before defragmenting
	sort frag$FCOUNT | uniq > frag$(($FCOUNT+1))
	let FCOUNT++
}

#Check the generated file list and exclude directories automatically (removing need of dirs-file)
function checkdirs () {
	DIRSFILE="dirs-$1-fly"
	if [[ ! -e $DIRSFILE ]]; then
		einfo "Checking for directories in generated list"
		
		DIRS=0
		while read linedir; do
			if [ -d "$linedir" ]; then
				echo "$linedir" >> dirs-$1-fly
				DIRS=1
			fi
		done < frag$FCOUNT

		if [ -e "dirs-$1-fly" ]; then
			sort dirs-$1-fly | uniq > temp2
			mv temp2 dirs-$1-fly
		fi

		if [ $DIRS -eq 1 ]; then
			comm -2 -3 frag$FCOUNT dirs-$1-fly > frag$(($FCOUNT+1))
			let FCOUNT++
		fi
		
		unset DIRS
	elif [[ -e $DIRSFILE ]]; then
		einfo "Directory file exists from previous pass, skipping check"
	fi
	unset DIRSFILE
}