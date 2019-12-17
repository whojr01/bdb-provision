#!/bin/bash

# UpdateHostsFile.sh
# This script is called from systemd to check the ipfile.txt for new VM IP entries. If found
# it then appends the list of IPs to the /etc/hosts file.
#


VAGRANTSHARE=/media/sf_admin
HOSTDATAFILE=ipfile.txt
UPDATESYSTEMFILE=/etc/hosts
LOGTAG="VAGRANT"
UPDATESEPARATOR="==================== DONT UPDATE BEYONE THIS LINE ======================="
TMPFILE=/tmp/vagranthostfile$$

IFS="
"

RegenHostFile() {
	# logger -s -i -p info -t $LOGTAG "$0 : Checking/Updating ipfile $VAGRANTSHARE/$HOSTDATAFILE"
	fnd=0
	[ -f $TMPFILE ] && rm -f $TMPFILE
	for line in `cat $UPDATESYSTEMFILE`
	do
		[ $line == $UPDATESEPARATOR ] && fnd=1
		[ $fnd -eq 0 ] && echo $line >> $TMPFILE
	done

	if [ ! -f "$VAGRANTSHARE/$HOSTDATAFILE" ] ; then
		logger -s -i -p warning -t $LOGTAG "Error: $0 : Can't access ipfile $VAGRANTSHARE/$HOSTDATAFILE"
		exit 1
	fi

	echo >> $TMPFILE
	echo $UPDATESEPARATOR >> $TMPFILE

	for line in `cat "$VAGRANTSHARE/$HOSTDATAFILE"`
	do
		line=`echo $line | sed -e 's/[\n\r]$//'`
		echo $line >> $TMPFILE
	done

	cp $TMPFILE $UPDATESYSTEMFILE
	rm -f $TMPFILE
}


RegenHostFile

