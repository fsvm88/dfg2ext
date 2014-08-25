#This file contains functions specific to exclusions

#Check if exclusions file exists: if it exists preload it, else warn user
function loadexcl () {
	EXFILE=exfile-$1
	if [[ -s $EXFILE ]]; then
		ebegin "Loading exclusions from file"
		#WARNING: this is not from file, provides a safe way to include by default, \
		#			always our .dfg directory that will _nearly always_ contain fragmented files \
		#			and thus provide some false positives. \
		#			this is safe because this function gets executed only ONCE during script's run. \
		#			if in some near future this behaviour has to be changed, \
		#			then we shall unset EXVARS *BEFORE* going into the conditional checks.
		EXVARS=$2\\n
		while read linex; do
			EXVARS=$EXVARS$linex\\n
		done < $EXFILE
		eend $?
		echo -e "EXVARS is:\\n$EXVARS"
	else
		eerror "Exclusion file $EXFILE does not exist. \
Please fill it in with the files you need to exclude."
		ewarn "If you want to defragment also loopback filesystems, \
since version 0.4 it is NEEDED to unmount them first."
		if [[ $EXADV == 0 && ! -s $EXFILE ]]; then
			show_exclusions_warnings "$DFGDIR" "$EXFILE"
			exit 1
		fi
	fi
}

#If necessary add mounted filesystems as exclusions
function loopexcl () {
	FLOOPS=`mount | grep loop | sed 's/.on.*//' | sed 's/.type.*//' | grep -e "[0-9A-Za-z]"`
	if [ "$FLOOPS" != "" ]; then
		ebegin "Adding mounted loopback filesystems to exclusions list"
		EXVARS=$EXVARS$FLOOPS
		eend $?
	else
		einfo "No mounted loopback filesystem(s) were detected"
	fi
}