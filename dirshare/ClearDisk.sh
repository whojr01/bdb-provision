#!/bin/bash

# This script is dangerous since it destroys the partitions on 
# the disks /dev/sdb through /dev/sde.


DRIVES="b c d e"

echo
echo This will destroy the contents of the drives listed below.

for i in $DRIVES
do
	ls /dev/sd$i
done

echo "Are you absolutely sure you want to do this enter (kanGar0o)?"
read response

[[ $response == kanGar0o ]] || exit 1

for i in $DRIVES
do
	echo "Gone! Wiped disk."
	ls /dev/sd$i
	dd if=/dev/zero of=/dev/sd$i bs=512 count=1
	wipefs -a /dev/sd$i
done

echo "I hope your not crying..."
