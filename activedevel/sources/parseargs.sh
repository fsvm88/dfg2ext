#This file contains some functions specific to the parsing of commandline options

#Initialize to defaults values if options were not specified at commandline
defaulting () {
	if [[ $CTOSTOP == "" || $CTOSTOP -eq 0 ]]; then
		CTOSTOP=2
	fi
	if [[ $MINIMUM == "" || $MINIMUM -lt 0 ]]; then
		MINIMUM=0
	fi
	if [[ $WMD5 == "" ]]; then
		WMD5=0
	fi
	if [[ $MAX_PERFILE == "" ]]; then
		MAX_PERFILE=15
	fi
}

#Keep values in maximum ranges
keep_values_in_range () {
	if [[ $MAX_PERFILE -gt 30 ]]; then
		MAX_PERFILE=30
	fi
	if [[ $CTOSTOP -gt 10 ]]; then
		CTOSTOP=10
	fi
}