#!/bin/bash
# Exercising getopts and OPTIND
# Script modified 10/09/03 at the suggestion of Bill Gradwohl.


# Here we observe how 'getopts' processes command line arguments to script.
# The arguments are parsed as "options" (flags) and associated arguments.

# Try invoking this script with
# 'scriptname -mn'
# 'scriptname -oq qOption' (qOption can be some arbitrary string.)
# 'scriptname -qXXX -r'
#
# 'scriptname -qr'    - Unexpected result, takes "r" as the argument to option "q"
# 'scriptname -q -r'  - Unexpected result, same as above
# 'scriptname -mnop -mnop'  - Unexpected result
# (OPTIND is unreliable at stating where an option came from).
#
#  If an option expects an argument ("flag:"), then it will grab
#+ whatever is next on the command line.

NO_ARGS=0 
E_OPTERROR=65

macro () {
	if [ $MINIMUM -lt $LINES ]; then
		TODEFRAG = 1
	fi
}


if [ $# -eq "$NO_ARGS" ]  # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-mMp)"
  exit $E_OPTERROR        # Exit and explain usage, if no argument(s) given.
fi  
# Usage: scriptname -options
# Note: dash (-) necessary


while getopts ":m:M:p:" Option
do
  case $Option in
    m     ) echo "Scenario #1: option -m- with argument \"$OPTARG\"   [OPTIND=${OPTIND}]"
			MINIMUM=$OPTARG;;
    M     ) echo "Scenario #2: option -M- with argument \"$OPTARG\"   [OPTIND=${OPTIND}]"
			MAXIMUM=$OPTARG;;
    p     ) echo "Scenario #3: option -p- with argument \"$OPTARG\"   [OPTIND=${OPTIND}]"
			PART=$OPTARG;;
    #  Note that option 'q' must have an associated argument,
    #+ otherwise it falls through to the default.
    *     ) echo "Unimplemented option chosen.";;   # DEFAULT
  esac
  genlist
  macro
done

shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non option item supplied on the command line
#+ if one exists.

exit 0

#   As Bill Gradwohl states,
#  "The getopts mechanism allows one to specify:  scriptname -mnop -mnop
#+  but there is no reliable way to differentiate what came from where
#+  by using OPTIND."