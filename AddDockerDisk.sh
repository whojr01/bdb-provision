#!/bin/sh

NoDiskFound()
{

	if [[ ${#DISK[@]} -eq 0 ]] ; then
		echo "***********************************"
		echo "***********************************"
		echo "***********************************"
		echo "***********************************"
		echo "FAILED TO IDENTIFY DISK"
		echo
		echo "COULD NOT IDENTIFY DISK OF SIZE $DISKARG"
		echo "ABORTING... NO ACTION TAKEN"
		echo "***********************************"
		echo "***********************************"
		echo "***********************************"
		echo "***********************************"
		exit 1
	fi
}

ChkResult()
{
        echo "################################"
        echo "$CMD_DES"
        echo
        echo "$CMD ${CMDARG[@]}"
        echo
        ( exec $CMD ${CMDARG[@]} )
        if [ $? -eq 0 ] ; then
                echo "Status: Success"
       else
                echo "*******************************"
                echo "Status: Failed."
                [ $BENIGN -eq 1 ] && echo "Action: Aborting..." && exit 1
                echo "Action: Continuing."
        fi
}
 

# mkdockervol.sh
# Attempts to determine the proper device to use to create the docker thinpools required for the
# enterprise edition of Docker. It does this based on the best "guess" possible when it iterrogates
# the system looking for the required drive.
#
#
IFS=$'\n'

if [[ -z $1 ]]; then
	echo "Expected disk size. ex. 8192";
	exit 1;
fi

PVCREATE=/usr/sbin/pvcreate
VGCREATE=/usr/sbin/vgcreate
LVCREATE=/usr/sbin/lvcreate
LVCONVERT=/usr/sbin/lvconvert
LVCHANGE=/usr/sbin/lvchange
VGEXTEND=/usr/sbin/vgextend
LVEXTEND=/usr/sbin/lvextend
PVS=/usr/sbin/pvs
VGS=/usr/sbin/vgs
LVS=/usr/sbin/lvs
LVSCAN=/usr/sbin/lvscan
VGSCAN=/usr/sbin/vgscan
PVSCAN=/usr/sbin/pvscan

DISKARG=$1
DISKSIZE=$(($DISKARG*1024**2))
SECTORSIZE=512
BENIGN=1
result=0
CMD=""


echo "########################################"
echo "Getting all disks from fdisk"
echo "########################################"
echo

# Scan the partition table looking for physical disk devices that match the exact size described
# by the global variable DISKSIZE and does not have a partition table and set the results in an array
# called DISK.
ent=0

# Collect all the disk block devices. Filter out any volume groups
for i in $(fdisk -l | grep "Disk /dev/" | grep -v "/dev/mapper")
do
	entry=( $(echo $i | awk '{print substr($2,0,length($2)-1)"\n"$5}') )

	# Now determine if the disk we have is currently being used (i.e. look for an assigned identifier )
	if [[ ${entry[1]} -eq $DISKSIZE ]] && [[ ! -n $(fdisk -l ${entry[0]} | grep "Disk identifier:") ]] ; then
		DISK[$ent]=${entry[0]}
		(( ent++ ))
	fi
#	echo "Disk  : ${entry[0]}"
#	echo "Size  : ${entry[1]}"
done

NoDiskFound
MAXDISKENTRIES=${#DISK[@]}

echo "Identified disks                          : ${DISK[@]}"

# Now, if there are any disks in the array we know they don't have a partition table and they meet our criteria
# so we need to check to see if they are part of a volume group.

# Get all of the volume groups.
PVLIST=($($PVS --noheadings -o pv_name))
echo "Physical Volumes used in Volume Groups    : [${PVLIST[@]}]"
echo "MAXDISKENTRIES => $MAXDISKENTRIES"

for (( diskent=0; diskent < MAXDISKENTRIES; diskent++ ))
do
	echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	echo "Processing [${DISK[$diskent]}]"
	for (( pvent=0; $pvent < ${#PVLIST[@]}; pvent++ ))
	do
		[[ ! -n ${DISK[$diskent]} ]] && continue
		PVLIST[$pvent]=${PVLIST[$pvent]// /}
		[[ ${PVLIST[$pvent]:0:${#DISK[$diskent]}} == ${DISK[$diskent]} ]] && echo "MATCHED VOLUME                            : ${PVLIST[$pvent]} == ${DISK[$diskent]}" && echo "REMOVING                                  : ${DISK[$diskent]}" && unset DISK[$diskent]
	done
done

NoDiskFound

echo "Identified the following available disks: ${DISK[@]}"
echo
echo
echo "########################################"
echo "Processing Volume Group Docker"
echo
docker_group_created=0

for (( diskent=0; diskent < MAXDISKENTRIES; diskent++ ))
do
	# If array element was removed skip it.
	[[ ! -n ${DISK[$diskent]} ]] && continue

	[[ -n $(lvs --noheadings -o vg_name | uniq | grep -i docker) ]]  && docker_group_created=1

	if [ $docker_group_created -eq 0 ]; then
		echo "Creating Docker group from DISK: ${DISK[@]}"
		echo

		# Initialize physical volume
		CMD_DES="Initialize physical volume ${DISK[$diskent]}"

		CMD="$PVCREATE"
		CMDARG=(${DISK[$diskent]})
		ChkResult

		# Create volume group docker
		echo
		CMD_DES="Create volume group docker"
		CMD="$VGCREATE"
		CMDARG=("docker" ${DISK[$diskent]})
		ChkResult
		 
		# Create two logical volumes: thinpool and thinpoolmeta
		CMD_DES="Create two logical volumes: Thinpool and thinpoolmeta"
		CMD="$LVCREATE"
		CMDARG=("--wipesignatures" "y" "-n" "thinpool" "docker" "-l" "95%VG")
		ChkResult

		CMD_DES="Ceating thinpoolmeta"
		CMD="$LVCREATE"
		CMDARG=("--wipesignatures" "y" "-n" "thinpoolmeta" "docker" "-l" "1%VG")
		ChkResult

		# Convert the volumes to a thin pool and a storage location for metadata for the thin pool.
		CMD_DES="Combine the thinpool and thinpoolmeta LVs into a thin pool LV."
		CMD="$LVCONVERT"
		CMDARG=("-y" "--zero" "n" "-c" "512k" "--thinpool" "docker/thinpool" "--poolmetadata" "docker/thinpoolmeta")
		ChkResult

		if [ -f /etc/lvm/profile/docker-thinpool.profile ] ; then
			echo "**********************************"
			echo "WARNING NOT MODIFYING [docker-thinpool.profile]"
			echo
			echo "The file /etc/lvm/profile/docker-thinpool.profile exists."
			echo "The following contents were to be added."
			echo
			echo "activation {"
			echo "      thin_pool_autoexend_treshold=80"
			echo "      thin_pool_autoextend_percent=20"
			echo "}"
			echo "***********************************"
		else
			echo "####################################"
			echo "Creating docker thinpool profile"

			(
			cat << THINPROFILE
activation {
	thin_pool_autoextend_threshold=80
	thin_pool_autoextend_percent=20
}

THINPROFILE
) | tee /etc/lvm/profile/docker-thinpool.profile

		fi

		CMD_DES="Combine the data and metadata LVs into a thin pool LV."
		CMD="$LVCHANGE"
		CMDARG=("--metadataprofile" "docker-thinpool" "docker/thinpool")
		ChkResult

		CMD_DES="Enable monitoring for all LV volumes"
		CMD="$LVS"
		CMDARG=("-o+seg_monitor")
		ChkResult

		# Preserve lib docker in case something goes bad.
		if [ -d /var/lib/docker ] ; then
			echo
			echo "########################################"
			echo "Preserve lib docker just in case"
			mkdir /var/lib/docker.bk
			mv /var/lib/docker/* /var/lib/docker.bk
		fi

(
cat << DAEMON
{
	"storage-driver": "devicemapper",
	"storage-opts": [
		"dm.thinpooldev=/dev/mapper/docker-thinpool",
		"dm.use_deferred_removal=true",
		"dm.use_deferred_deletion=true"
	]
}
DAEMON
) | tee /etc/docker/daemon.json

	else
		echo "Adding DISK: ${DISK[$diskent]} to Docker Group"
		echo

		CMD_DES="Create new physical volume"
		CMD="$PVCREATE"
		CMDARG=(${DISK[$diskent]})
		ChkResult

		# Extend the volume group to include the new physical volume
		CMD_DES="Extend volume group to include ${DISK[$diskent]}"
		CMD="$VGEXTEND"
		CMDARG=("docker" "${DISK[$diskent]}")
		ChkResult

		# Now get the free physical extents of the added drive.
		echo
		echo "Get the free physical extents of the added drive"
		echo "extents=(\$($VGS -ovg_free_count --noheadins))"
		extents=($($VGS -ovg_free_count --noheadings))
		FREE_EXTENTS=${extents[1]// /}
		echo "Free extents: $FREE_EXTENTS"
		echo

		# Now extend the thinpool volume group
		CMD_DES="Extending the thinpool volume group"
		CMD="$LVEXTEND"
		CMDARG=("-l" "+$FREE_EXTENTS" "/dev/docker/thinpool")
		ChkResult

	fi
done

# now display the status of the disks
CMD_DES="Display physical volumes"
CMDARG=()
CMD="$PVSCAN"
ChkResult

# now display the status of the disks
CMD_DES="Display volume groups"
CMDARG=()
CMD="$VGSCAN"
ChkResult

# now display the status of the disks
CMD_DES="Display logical volumes"
CMDARG=()
CMD="$LVSCAN"
ChkResult
echo "########################################"
echo "$0 : Completed successfully check logs"
echo "########################################"

