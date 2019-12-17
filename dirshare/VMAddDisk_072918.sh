#!/bin/bash

# VMAddDisk.sh size type group
#
# size - The size of the disk
# type - The type of drive we want to create
# group - The volume group of the drive
#
# Types:
# thin - To create a thin provisioned drvie
# lv - to create a logical volume drive
# drive - standard disk with a file system
#
# Paramaters: 4 thin thingrp 5 lv lvgrp 10 drive none
#

fatal()
{
	echo "Error: $1"
	exit 1
}


MAXARGS=3
DISKSIZE=0
DISKTYPE=1
DISKGRP=2

(( x=$#%$MAXARGS ))
[ $# -lt $MAXARGS -o $x -ne 0 ] && fatal "Not enough parameters passed [$*]"


IFS="
"

cnt=0

while [[ $1 ]]
do
	(( x=$cnt%$MAXARGS ))
	if [ $x -eq 0 ]; then
		[ $( echo $1 | sed -e 's/^\([0-9]*\)$/num/' ) != "num" ] && fatal "Invalid Disk Size [$1]"
		(( disks[$cnt]=${1}*1024**2 ))
	else
		disks[$cnt]=$1
	fi
	(( cnt++ ))
	shift
done

echo "Disk Array"
echo ${disks[@]}

for i in $( fdisk -l 2>/dev/null | grep "Disk /dev/" | grep -v "/dev/mapper" )
do
	entry=( $( echo $i | awk '{print substr($2,0,length($2)-1)"\n"$5}') )

	for (( dskent=0; $dskent < ${#disks[@]}; dskent+=3 ))
	do
		if [[ ${disks[$dskent]:0:4} != /dev ]] &&
			[[ ${entry[1]} -eq ${disks[$dskent]} ]] &&
			[[ ! -n $( fdisk -l ${entry[0]} 2>/dev/null | grep "Disk identifier:") ]] ; then
			disks[$dskent]=${entry[0]}
		fi
	done
done

echo "Disk Array 2"
echo ${disks[@]}



