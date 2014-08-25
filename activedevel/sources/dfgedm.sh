#This file contains functions related to defragmentation with EDM

. ./misc.sh

#Defragments file on the list with EDM
function defragment_with_edm () {
	CLINE=0
	einfo "Specific file defragmentation"
	sync
	
	if [[ $WMD5 -eq 0 ]]; then
		while read line; do
			let CLINE++
			update_screen "$CLINE" "$LINES" "${line}";
			defragfile "${line}"
		done < frag$FCOUNT
	elif [[ $WMD5 -eq 1 ]]; then
		while read line; do
			let CLINE++
			update_screen "$CLINE" "$LINES" "${line}";
			
			defragfile_with_md5 "${line}"
		done < frag$FCOUNT
	fi
	
	update_loops "$(($NCOUNTER+1))" "$(($CTOSTOP-$STOPCOUNT))"
	sync
}
