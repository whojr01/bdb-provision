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
# drive - standard disk with a file system and Group has to be equal to none.
#
# Paramaters: 4 thin thingrp 5 lv lvgrp 10 drive none
#

fatal()
{
	echo "Error: $1"
	exit 1
}

funDrive()
{
	echo "IN Drive 1 [$1] 2 [$2] 3 [$3]"

	dskdev=$1
	dsktype=$2
	dskgrp=$3

	echo "1 [$dskdev] 2 [$dsktype] 3 [$dskgrp]"
	
}


funThin()
{
        echo "In Thin 1 [$1] 2 [$2] 3 [$3]"

        dskdev=$1
        dsktype=$2
        dskgrp=$3

        echo "1 [$dskdev] 2 [$dsktype] 3 [$dskgrp]"

}

funLv()
{
        echo "IN Lv 1 [$1] 2 [$2] 3 [$3]"

        dskdev=$1
        dsktype=$2
        dskgrp=$3

        echo "1 [$dskdev] 2 [$dsktype] 3 [$dskgrp]"

}

MAXARGS=3
DISKSIZE=0
DISKTYPE=1
DISKGRP=2
TMPMNT=$(pwd)/$$

[ ! -d $TMPMNT ] && mkdir $TMPMNT || fatal "Can't create themp mount directory [$TMPMNT]"


(( x=$#%$MAXARGS ))
[ $# -lt $MAXARGS -o $x -ne 0 ] && fatal "Not enough parameters passed [$*]"


IFS="
"

cnt=0

while [[ $1 ]]
do
	(( x=$cnt%$MAXARGS ))
	(( dsktp= $cnt + $DISKTYPE ))
	(( dskgp= $cnt + $DISKGRP ))
	if [ $x -eq 0 ]; then
		[ $( echo $1 | sed -e 's/^\([0-9]*\)$/num/' ) != "num" ] && fatal "Invalid Disk Size [$1]"
		(( disks[$cnt]=${1}*1024**2 ))

		case $2 in
			drive | thin | lv )
				disks[$dsktp]=$2
				;;
			* )
				fatal "Invalid disk type"
		esac

		[[ $2 = drive && $3 != none ]] && fatal "Drive type Group must be set to none"
		disks[$dskgp]=$3
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
			[[ $( mount ${entry[0]} $TMPMNT 2>&1 | tail -1 | sed -e "s/.*\(unknown filesystem type '(null)'\).*/empty/") = "empty" ]] ; then
			disks[$dskent]=${entry[0]}
		fi
		umount $TMPMNT 2> /dev/null
	done
done

rmdir -v $TMPMNT

echo "Disk Array 2"
echo ${disks[@]}


# Check to see if all drives in the disks arrary have been allocated to a system device.

for (( dskent=0; $dskent < ${#disks[@]}; dskent+=3 ))
do
	[[ ${disks[$dskent]:0:4} != /dev ]] && fatal "All drives not allocated. FATAL"
done

echo Contents
echo ${disks[@]}

for (( dskent=0; $dskent < ${#disks[@]}; dskent+=3 ))
do

	(( dsktp= $dskent + $DISKTYPE ))
        (( dskgp= $dskent + $DISKGRP ))

	case ${disks[$dsktp]} in

	drive)	echo "Drive"
		funDrive ${disks[$dskent]} ${disks[$dsktp]} ${disks[$dskgp]}
		;;

        thin)  echo "Thin"
                funThin ${disks[$dskent]} ${disks[$dsktp]} ${disks[$dskgp]}
                ;;

        lv)  echo "Lv"
                funLv ${disks[$dskent]} ${disks[$dsktp]} ${disks[$dskgp]}
                ;;

	esac

done


