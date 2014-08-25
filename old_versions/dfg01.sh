#!/bin/bash

#Defrag script for ext2/ext3 filesystems
#Version: 0.1
#Author: Neo2
#This script was created to easily defragment the filesystem
#It takes informations from davl tools, which must be installed for the script to run

#Here follow variables
#Dfg home dir
DFGDIR=$HOME/.dfg
#Next two variables are needed just to make EXVARS more flexible
#Set the architecture bits where dfg is supposed to run (for /lib** directory)
ARCH=64
#Set the glibc version installed on your system (if you have multiple versions, only the one that is currently in use is needed)
GCV=2.5
#The partition we want to defragment and extract then its friendly name
PART=/dev/sda7
FPART=`echo $PART | sed 's/\/dev\///g'`
#The 
#Current defrag line during process
CLINE=0
#Total number lines count
LINES=0
#Temporary frag(x) file count
FCOUNT=0
#Exclude files
EXFILE=exfile-$FPART
DIRF=dirs-$FPART
#Default exclusions.
#!WARNING WARNING WARNING!
#Leave /lib$ARCH/libc and /lib$ARCH/ld- in EXVARS else you'll screw up your sistem! Those files are libc binaries and are needed by any program. You will have to reboot with livecd and mv libc and ld-x.x.so
#/mnt/ is now excluded by default since cdavl performs analysis on whole partition (it doesn't take into account mount points)
#You can specify either by adding the escape character \\n on same line or by expanding the variable on multiple lines.
#You can also manually edit the exclude file.
#The separator for variables is the newline character.
#EXVARS="/dev/\\n/mnt/\\n/lib$ARCH/libc-$GCV.so\\n/lib$ARCH/ld-$GCV.so"
EXVARS="/dev/\\n/lib$ARCH/libc-$GCV.so\\n/lib$ARCH/ld-$GCV.so\\n/bin/mv\\n/bin/cp\\n/bin/rm"

#Add glibc files to exclusions
if [ -s $EXFILE ]; then
	if grep -q "libc-[0-9].[0-9].so" $EXFILE && grep -q "ld-[0-9].[0-9].so" $EXFILE && grep -q "\/mv" $EXFILE && grep -q "\/cp" $EXFILE
		then echo "[*] Exclusions file has minimum requirements, going ahead..."
	else
		echo "[!] Exclusions file doesn't have minimum requirementes! Dfg will try to identify needed ones..."		
	fi
fi

#Check if we are root or not
if [ $HOME != /root ]; then
	echo "[!] Your home directory is not root one!"
	echo "[!] Your home directory is $HOME!"
	echo "[!] When defragmenting I will defragment only files in your home directory!"
else
	echo "[*] Root access granted."
fi

#Check whether we are defragmenting root filesystem
FSYS=`mount | grep $PART | sed 's/.*on.//' | sed 's/.type.*//'`
if [ $FSYS == / ]; then
	echo "[*] Defragmenting root filesystem, no need to add extra path."
elif [ $FSYS != / ]; then
	echo "[*] This is not the root filesystem, extra path will be added."
fi

#Check if dfg directory exists
if [ -d $DFGDIR ]; then
	echo "[*] Directory present."
else
	echo "[!] Directory does not exist, creating..."
	mkdir $DFGDIR
	echo "[*] Directory created."
fi

cd $DFGDIR

echo "[*] Deleting old temporary files..."
rm -Rf frag* dtmp* 2*

echo "[*] Generating list of files to defrag..."

#Check if cdavl is installed: if it is copy its data about desired partition, else exit
if [ -x /usr/bin/cdavl ]; then
	cdavl -v $PART > frag$FCOUNT
else
	echo "[!] davl tools are not installed! dfg cannot work without them! Please emerge it!"
	exit 1
fi

#Check if exclusions file exists: if it exists preload it, else create a new one with basic requirements
if [ -s $EXFILE ]; then
	echo "[*] Adding exclusions..."
	while read linex; do
		EXVARS=$EXVARS$linex\\n
	done < $EXFILE
else
	echo "[!] Exclusion file $EXFILE does not exist! Creating an empty one."
	touch $EXFILE
fi

#Check if exclusions file is populated with minimum requirements. If it is not, populate it
if [ -s $EXFILE ]; then
	if grep -q "libc-[0-9].[0-9].so" $EXFILE && grep -q "ld-[0-9].[0-9].so" $EXFILE && grep -q "\/mv" $EXFILE && grep -q "\/cp" $EXFILE
		then echo "[*] Exclusions file already has minimum requirements."
	else
		echo "[!] Exclusions file doesn't have minimum requirements! Dfg will try to identify needed ones..."		
	fi
fi

#Generate list of files, stripping unneeded ones
grep '"' frag$FCOUNT > frag$(($FCOUNT+1))
let FCOUNT++
sed 's/(.*//' frag$FCOUNT | sed 's/"//g' > frag$(($FCOUNT+1))
let FCOUNT++
grep -v -e "$(echo -e $EXVARS)" frag$FCOUNT > frag$(($FCOUNT+1))
let FCOUNT++
sed 's/ /\\ /g' frag$FCOUNT | sed s:\/:$FSYS/: > frag$(($FCOUNT+1))
let FCOUNT++
if [ $HOME != /root ]; then
	echo "[*] Deleting files outside your directory..."
	grep "$HOME" frag$FCOUNT > frag$(($FCOUNT+1))
	let FCOUNT++
fi
echo "[*] Done generating list of files."

#Check if we have previous dirs exclusion file
if [ -s $DIRF ]; then
	echo "[*] Found pre-existing dirs file, integrating info..."
	comm -2 -3 frag$FCOUNT $DIRF | sed 's/\t//g' > frag$(($FCOUNT+1))
	let FCOUNT++
	echo "[*] Info integrated."
else
	echo "[!] No pre-existing dirs file was found! It will be generated at the end of this (first) run"
fi

#Sort the file before defragmenting
sort frag$FCOUNT > frag$(($FCOUNT+1))
let FCOUNT++

#Print number of lines to defragment
LINES=$(wc -l frag$FCOUNT | sed 's/[^0-9][A-z]*.*//g')
echo "[*] Number of lines: $LINES"

echo "[*] Beginning specific file defragmentation... (flushing buffers before and after)"
sync
while read line; do
	sync
	let CLINE++
	if [ $[$CLINE%100] == 0 ]; then
		echo "$CLINE of $LINES"
	fi
#Moved out of the loop, decreases temporal complexity
#	if [ $CLINE == $LINES ]; then
#		echo "$CLINE of $LINES"
#	fi
#Copy
	cp --preserve=all $line $line.unfragmented 2>> 2cp
	sync
#Delete fragmented, can be skipped since mv does the job anyway
#	rm $line 2>> 2rm
#Move unfragmented over fragmented
	mv $line.unfragmented $line 2>> 2mv
#End loop
	sync
done < frag$FCOUNT
if [ $CLINE == $LINES ]; then
	echo "$CLINE of $LINES"
fi
sync
echo "[*] Files defragmented!"



#Parse error file(s) for further directory exclusion
echo "[*] Parsing error files for further incremental defrags..."
#Next line is obsolete since rm is not used anymore
#if [ -a 2cp ] && [ -a 2rm ]; then
if [ -s 2cp ]; then
	cat 2cp | sed 's/.*`//g' | sed "s/'.*//g" > dtmp1
#Next line(s) is/are obsolete since rm is not used anymore
#	cat 2rm | grep "Is a directory" | sed 's/rm: cannot remove `//g' | sed 's/: Is a directory//g' | sed s/\'//g | sed 's/\t//g' | sort > dtmp2
#	comm dtmp1 dtmp2 | sed 's/\t//g' > dtmp3
	if [ -s $DIRF ]; then
		echo "[*] Previous data was found. Updating..."
		comm -2 dtmp1 $DIRF | sed 's/\t//g' | sort > $DIRF
	else
		echo "[*] No previous data was found. Creating new data file..."
		sort dtmp1 > $DIRF
	fi
fi

#Final cleaning
echo "[*] Files parsed. Removing temporary unused files..."
rm -Rf frag* dtmp* 2*
echo "[*] Files removed. Script ended without errors."
