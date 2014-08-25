#This file contains some functions that are of exclusive use of EDM

# (+): ADD: EDM (Enhanced Defrag Mode) \
#		-> basically implemented through filefrag, allowable only for root (FIBMAP ioctl used by filefrag is available only via root), \
#			no toggling available (don't see why anybody would disable this)
#		-> allows per-file looping instead of simple looping allover the list. Result? more defragmented files per pass without having to regen
#			the list (saves _incredible_ amounts of time)
#		-> max number of iterats per-file can be selected, exits automatically \
#			(*) when fragments = 1 \
#			(*) fragments = perfection (no perfection reported) \
#			(*) iterats > max_iterats (defaults to 15 if unset, allowable max to 30, autoadjusted if above)

. ./misc.sh

function edmdebug () {
	clear
	echo "Before $1"
	if [[ $CURRENTFRAGS -gt 0 ]]; then echo "CURRENTFRAGS:   $CURRENTFRAGS"; fi
	if [[ $PERFECTION -gt 0 ]]; then echo "PERFECTION:   $PERFECTION"; fi
	if [[ $CUR_PERFILE -gt 0 ]]; then echo "CUR_PERFILE:   $CUR_PERFILE"; fi
	if [[ $MAX_PERFILE -gt 0 ]]; then echo "MAX_PERFILE:   $MAX_PERFILE"; fi
	if [[ $FILE != "" ]]; then echo "FILE:   $FILE"; fi
	if [[ $NEXTFILE != "" ]]; then echo "NEXTFILE:   $NEXTFILE"; fi
}

function update_frags_count_for_edm () {
	CURRENTFRAGS=`/sbin/filefrag "$1" | sed 's,'$1': ,,' | sed 's:[^0-9].*::'`
	PERFECTION=`/sbin/filefrag "$1" | sed 's:'$1'.*,.*[^0-9] ::' | sed 's:[^0-9].*::'`
}

most_inner_looper () {
			edmdebug "copying"
			if [[ $CURRENTFRAGS -lt $MIN_FRAGMENTS ]]; then
				MIN_FRAGMENTS=$CURRENT_FRAGS
				LOWEST_FILE=$CUR_PERFILE
			fi
			copyfile "$1" "$2"
			let CUR_PERFILE++
			FILE=$NEXTFILE
			update_frags_count_for_edm "$FILE"
}

function perfile_looper () {
	while [[ $CUR_PERFILE -ne $MAX_PERFILE ]]; do
		NEXTFILE="${1}.unfragmented.$CUR_PERFILE"
		most_inner_looper "${FILE}" "${NEXTFILE}"
		if [[ $CURRENTFRAGS -eq 1 || $PERFECTION == "" ]]; then
			break;
		fi
	done
	FILE="${1}.unfragmented.$LOWEST_FILE"
}

function defragfile () {
	CUR_PERFILE=0
	FILE="${1}"
	LOWEST_FILE=$CUR_PERFILE
	update_frags_count_for_edm "$FILE"
	edmdebug "while loop"
	while [[ $CURRENTFRAGS -gt $PERFECTION && $CUR_PERFILE -ne $MAX_PERFILE ]]; do
		update_frags_count_for_edm "${FILE}"
		
		perfile_looper

		edmdebug "moving"
		movefile "${FILE}" "${1}"
		eval_hard_exclusion "${FILE}" "${FPART}"
		edmdebug "deleting"
		delstale "${1}.unfragmented.*"
		if [[ $CURRENTFRAGS -eq 1 || $PERFECTION == "" || $CUR_PERFILE -eq $MAX_PERFILE ]]; then
			break;
		fi
	done
}

function defragfile_with_md5 () {
	CUR_PERFILE=0
	FILE="${1}"
	LOWEST_FILE=$CUR_PERFILE
	MD5SUMF=`md5sum "${1}" | sed 's/ .*//' 2>> /dev/null`
	update_frags_count_for_edm "${FILE}"
	edmdebug "while loop"
	while [[ $CURRENTFRAGS -gt $PERFECTION && $CUR_PERFILE -ne $MAX_PERFILE ]]; do
		update_frags_count_for_edm "${FILE}"
		
		perfile_looper

		MD5SUMU=`md5sum "${FILE}" | sed 's/ .*//' 2>> /dev/null`
		
		if [[ "$MD5SUMF" == "$MD5SUMU" ]]; then
			movefile "${FILE}" "${1}"
			eval_hard_exclusion "${FILE}" "${FPART}"
		else
			echo "${FILE}" >> md5err-$FPART
			ewarn "!!!MD5 error on file:   ${FILE}"
		fi
		
		edmdebug "deleting"
		delstale "${1}.unfragmented"
		
		if [[ $CURRENTFRAGS -eq 1 || $PERFECTION == "" || $CUR_PERFILE -eq $MAX_PERFILE ]]; then
			break;
		fi
	done
}

#most_inner_looper
#	il file successivo è uguale a
#	se i frammenti correnti sono minori del minimo
#		il minimo di frammenti è uguale ai frammenti correnti
#		l'indice del file con meno frammenti è uguale all'indice corrente
#	copia il file corrente in quello successivo
#	aumenta il contatore delle iterazioni
#	il file successivo diventa il file corrente
#	aggiorna frammenti

#fintanto che (i frammenti correnti sono maggiori della perfezione) e (il numero corrente di iterazioni non è uguale al massimo)
#	aggiorna frammenti
#	fintanto che il numero corrente di iterazioni non è uguale al massimo
#		most_inner_looper
#		se i frammenti correnti sono uguali a uno o la perfezione non è specificata allora
#			interrompi il ciclo while interno
#	muovi il file corrente nel file di partenza (la copia originale)
#	elimina eventuali file rimanenti
#	se la perfezione non è specificata
#		esci dal ciclo