#This file contains functions related to defragmentation without EDM

. ./misc.sh

#Defragments file on the list with simple defrag mode
function defragment () {
	CLINE=0
	einfo "Specific file defragmentation"
	sync

	if [[ $WMD5 -eq 0 ]]; then
		while read line; do
			let CLINE++
			update_screen "$CLINE" "$LINES" "${line}";
			copyfile "${line}" "${line}.unfragmented"
			movefile "${line}.unfragmented" "${line}"
			eval_hard_exclusion "${line}" "${FPART}"
		done < frag$FCOUNT
	elif [[ $WMD5 -eq 1 ]]; then
		while read line; do
			let CLINE++
			update_screen "$CLINE" "$LINES" "${line}";
			copyfile "${line}" "${line}.unfragmented"
			#Update MD5 sums
			MD5SUMF=`md5sum "${line}" | sed 's/ .*//' 2>> /dev/null`
			MD5SUMU=`md5sum "${line}.unfragmented" | sed 's/ .*//' 2>> /dev/null`
			#Next is just for some debugging, if you need some of course ;-)
			#echo -e "Sums:\\n$MD5SUMF\\n$MD5SUMU"
			if [[ "$MD5SUMF" == "$MD5SUMU" ]]; then
				movefile "${line}.unfragmented" "${line}"
				eval_hard_exclusion "${line}" "${FPART}"
			else
				echo "${line}" >> md5err-$FPART
				ewarn "!!!MD5 error on file:   ${line}"
			fi
		done < frag$FCOUNT
	fi
	
	delstale "${line}.unfragmented"

	update_loops "$(($NCOUNTER+1))" "$(($CTOSTOP-$STOPCOUNT))"
	sync
}
