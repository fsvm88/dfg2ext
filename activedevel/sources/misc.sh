#This file contains some miscellaneous functions

#Fast cleanup of stale/temporary files
function cleanup () {
	einfo "Deleting old temporary files"
	rm -Rf frag* 2* dirs-*-fly hardexcluded-*
	sync
}

function copyfile () {
	cp --preserve=all "$1" "$2" 2>> 2cp
	sync
}

function movefile () {
	mv "$1" "$2" 2>> 2mv
	sync
}

function delstale () {
	rm -Rf "$1" 2>> /dev/null
	sync
}

function eval_hard_exclusion () {
	if [[ -e "${1}" || -e "${1}.unfragmented" ]]; then
		echo "${1}" >> hardexcluded-$2
		break;
	fi
}