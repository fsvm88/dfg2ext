#!/bin/bash


PART=/dev/sda7
FPART=`echo $PART | sed 's/\/dev\///g'`
EXFILE=exfile-$FPART
DIRF=dirs-$FPART
PROVA=`grep -q "libc" $EXFILE`
EXVARS="/dev/\\n/libc-\\n/ld-\\n/bin/mv\\n/bin/cp\\n/bin/rm"
#EXVAR2=`echo -E $EXVARS`

if [ -s $EXFILE ]; then
	if grep -q "libc-[0-9].[0-9].so" $EXFILE && grep -q "ld-[0-9].[0-9].so" $EXFILE && grep -q "\/mv" $EXFILE && grep -q "\/cp" $EXFILE
		then echo "Prova superata!"
	else
		echo "Prova fallita!"
	fi
fi