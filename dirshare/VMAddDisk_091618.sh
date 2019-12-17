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

ChkResult()
{
	echo "#######################"
	echo $CMD_DES
	echo
	( exec $CMD ${CMDARG[@]} )
	if [ $? -eq 0 ] ; then
		echo Status: Success
	else
		echo "************************"
		echo Status: Failed
		fatal "Action: Aborting..."
	fi
}

funNext()
{
	DIR=$1
	vol=$(/bin/ls -tr $DIR | sort -V | tail -1)
	curcnt=$(echo $vol | sed -e 's/^[a-zA-Z]*\([0-9]*\)$/\1/')
	(( next=${curcnt}+1 ))

}

funFmt()
{
	echo "IN funFMT 1 [$1] 2 [$2]"
	fmtcmds=$1
	fmtdrv=$2
	# Initialize the drive and create a single partition
        echo "Standalone Drive - Initialize drive"
        echo $FDISKCMDS | /usr/sbin/fdisk $dskdev
        if [ $? -eq 0 ] ; then
               echo Status: Success
        else
                echo "************************"
                echo Status: Failed
                fatal "Action: Aborting..."
        fi
}

funExt()
{
	echo "IN funExt 1 [$1] 2 [$2] 3 [$3]"
	extdrv=$1
	extgrp=$2
	extnam=$3

	echo "Extending LV Group $extgrp to include $extdrv"

	CMD_DES="Create new physical volume"
	CMD=$PVCREATE
	CMDARG=($dskdev)
	ChkResult

	# Extend the volume group to include the new physical volume
	CMD_DES="Extend volume group to include $dskdev"
	CMD=$VGEXTEND
	CMDARG=($dskgrp $dskdev)
	ChkResult

	# Now get the free physical extents of the added drive
	echo
	echo "Get the free physical extents of the added drive"
	extents=($($VGS $dskgrp -ovg_free_count --noheadings))
	FREE_EXTENTS=${extents[0]// /}
	echo "Free Extents Available: $FREE_EXTENTS"
	echo

	# Extend the thinpool volume group by FREE_EXTENTS
	CMD_DES="Extending the thinpool volume group"
	CMD=$LVEXTEND
	CMDARG=(-l +$FREE_EXTENTS /dev/${dskgrp}/${dskgrp}thinpool)
	ChkResult
}	


funDrive()
{
	echo "IN Drive 1 [$1] 2 [$2] 3 [$3]"

	dskdev=$1
	dsktype=$2
	dskgrp=$3

	echo "1 [$dskdev] 2 [$dsktype] 3 [$dskgrp]"

	# Format the drive as Linux
	funFmt $FDISKCMDS $dskdev

	# The partition will always be 1 there for we format ${dskdev}1
	CMD_DES="Standalone Drive - Create filesystem"
	CMD=$MKFS
	CMDARG=(-f ${dskdev}1)
	ChkResult
	
}


funThin()
{
	#
	# No allocation meathod is specified. Assume normal.
	#

	grpcreated=0	# If set to 1 group is created.

        echo "In Thin 1 [$1] 2 [$2] 3 [$3]"

        dskdev=$1
        dsktype=$2
        dskgrp=$3

        echo "1 [$dskdev] 2 [$dsktype] 3 [$dskgrp]"

	# check to see if the group exists
	[[ -n $(lvs --noheadings -o vg_name | uniq | grep -i $dskgrp) ]] && grpcreated=1
	if [ $grpcreated -eq 0 ]; then
		# Initialize physical volume
		CMD_DES="Initialize physical volume $dskdev"
		CMD=$PVCREATE
		CMDARG=($dskdev)
		ChkResult

		# Create volume group
		CMD_DES="Create Volume group"
		CMD=$VGCREATE
		CMDARG=($dskgrp $dskdev)
		ChkResult

		# Create two logical volumes thinpool and thinpoolmeta
		CMD_DES="Create logical volume: Thinpool"
		CMD=$LVCREATE
		CMDARG=(--wipesignatures y -y -n ${dskgrp}thinpool $dskgrp -l 80%VG)
		ChkResult

		CMD_DES="Create logical volume: Thinpoolmeta"
		CMD=$LVCREATE
		CMDARG=(--wipesignatures y -y -n ${dskgrp}thinpoolmeta $dskgrp -l 10%VG)
		ChkResult

		# Convert the volume to a thin pool and storage location for metadat and for the thin pool
		CMD_DES="Combine the thinpool and thinpoolmeta LVs into a thin pool LV".
		CMD=$LVCONVERT
		CMDARG=(-y --zero n --thinpool /dev/$dskgrp/${dskgrp}thinpool --poolmetadata /dev/$dskgrp/${dskgrp}thinpoolmeta)
		ChkResult

		if [ -f /etc/lvm/profile/${dskgrp}-thinpool.profile ] ; then
			echo "*******************************"
			echo "WARNING NOT MODIFYING [$dskgrp-thinpool.profile]"
			echo
			echo "The file /ect/lvm/profile/${dskgrp}-thinpool./profile exists"
			echo "The following contents were to be added."
			echo
			echo "activiation {"
			echo "		thin_pool_autoexended_threshold=80"
			echo "		thin_pool_autoexended_percent=20"
			echo "}"
		else
			echo "################################"
			echo "Creating $dskgrp thinpool profile"
			( cat << THINPROFILE
activation {
	thin_pool_autoextend_threshold=80
	thin_pool_autoextend_percent=20
}
THINPROFILE
			) | tee /etc/lvm/profile/${dskgrp}-thinpool.profile
		fi

		# Assign the thin pool profile
		CMD_DES="Assign the thin pool profile to volume"
		CMD=$LVCHANGE
		CMDARG=(--metadataprofile ${dskgrp}-thinpool /dev/$dskgrp/${dskgrp}thinpool)
		ChkResult

		CMD_DES="Enable monitoring for all LV Volumes"
		CMD=$LVS
		CMDARG=(-o+seg_monitor)
		ChkResult

		# Create the filesystem

		CMD_DES="Create filesystem for thinpool"
		CMD=$MKFS
		CMDARG=(-f /dev/${dskgrp}/${dskgrp}thinpool)
		ChkResult

	else
		# Adding additional storage to the volume group it is assumed
		# the storage will be added to the thin pool and not the 
		# meta pool. The meta pool must be extended manually.
		#
		# The volume is extended by 100% of the free extents available.

		echo "Adding DISK: $dskdev to group $dskgrp"

		funExt $dskdev $dskgrp "thinpool"
	fi

}

funLv()
{
	grpcreated=0
        echo "IN Lv 1 [$1] 2 [$2] 3 [$3]"

        dskdev=$1
        dsktype=$2
        dskgrp=$3

        echo "1 [$dskdev] 2 [$dsktype] 3 [$dskgrp]"

        # check to see if the group exists
        [[ -n $(lvs --noheadings -o vg_name | uniq | grep -i $dskgrp) ]] && grpcreated=1
        if [ $grpcreated -eq 0 ]; then
		# Initialize physical volume
                CMD_DES="Initialize physical volume $dskdev"
                CMD=$PVCREATE
                CMDARG=($dskdev)
                ChkResult

                # Create volume group
                CMD_DES="Create Volume group"
                CMD=$VGCREATE
                CMDARG=($dskgrp $dskdev)
                ChkResult

		# Create logical volume
		CMD_DES="Create Logical Volume"
		CMD=$LVCREATE
		CMDARG=(-l 100%FREE -y -n ${dskgrp}vol $dskgrp)
		ChkResult

                # Create the filesystem
                CMD_DES="Create filesystem for ${dskgrp}vol"
                CMD=$MKFS
                CMDARG=(-f /dev/${dskgrp}/${dskgrp}vol)
                ChkResult

	else
		# Extend the group with the physical volume
		funExt $dskdev $dskgrp "vol"
	fi
}

LVCHANGE=/usr/sbin/lvchange
LVCONVERT=/usr/sbin/lvconvert
LVCREATE=/usr/sbin/lvcreate
LVEXTEND=/usr/sbin/lvextend
LVS=/usr/sbin/lvs
LVSCAN=/usr/sbin/lvscan
PVCREATE=/usr/sbin/pvcreate
PVS=/usr/sbin/pvs
PVSCAN=/usr/sbin/pvscan
VGCREATE=/usr/sbin/vgcreate
VGEXTEND=/usr/sbin/vgextend
VGS=/usr/sbin/vgs
VGSCAN=/usr/sbin/vgscan
FDISK=/usr/sbin/fdisk
MKFS=/usr/sbin/mkfs.xfs
XFS_GROWFS=/usr/sbin/xfs_growfs
RESIZE2FS=/usr/sbin/resize2fs

MAXARGS=3
DISKSIZE=0
DISKTYPE=1
DISKGRP=2
TMPMNT=$(pwd)/$$

# FDISKCMDS - Command definiton
#
# Send the following commands to /usr/sbin/fdisk
#
# x   extra functionality (experts only)
# c   change number of cylinders
# <enter - must be blank line to accept default>
# v   verify the partition table
# r   return to main menu
# n   add a new partition
# p   primary (1 primary, 0 extended, 3 free)
# 1
# <enter - must be blank line to accept default>
# <enter - must be blank line to accept default>
# t   change a partition's system id
# 83  Linux
# w   write table to disk and exit
#

FDISKCMDS="
x
c

v
r
n
p
1


t
83
w
"

LVFDISKCMDS="
x
c

v
r
n
p
1


t
8e
w
"

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
	entry=( $( echo $i | awk '{print substr($2,0,length($2)-1)"\n"$5}' ) )

	for (( dskent=0; $dskent < ${#disks[@]}; dskent+=3 ))
	do
		if [[ ${disks[$dskent]:0:4} != /dev ]] &&
			[[ ${entry[1]} -eq ${disks[$dskent]} ]] &&
			[[ $(/usr/bin/ls ${entry[0]}? 2>/dev/null)nopartition = "nopartition" ]] &&
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

IFS=" "

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


