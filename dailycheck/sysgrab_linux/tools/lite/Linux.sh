#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script to collect Host (Linux) specific configuration information
# Lite version
RC=0
SCRIPT_TMP=${EMC_TMP}/host
NAME=${OS}

RUNTIME=300

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

# Descriptions on all the functions can be found
# in the file 'tools.main'

check_dir

# Strip smp from ${OS_VER} for SMP enabled kernels

OS_VER2=`echo ${OS_VER} | sed -e 's/-smp//ig'`
OS_TYP=`uname -r |sed -e 's/smp/\-smp/g'`
OS_MOD=`uname -m`

# List of Files to Copy

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/var/log/messages*" "keep_dir_path"
copy_single_file "/var/log/boot.log*" "keep_dir_path"
copy_single_file "/var/log/dmesg" "keep_dir_path"
copy_single_file "/proc/cpuinfo" "keep_dir_path"
copy_single_file "/proc/version" "keep_dir_path"
copy_single_file "/proc/uptime" "keep_dir_path"
copy_single_file "/proc/loadavg" "keep_dir_path"
copy_single_file "/proc/meminfo" "keep_dir_path"
copy_single_file "/proc/pci" "keep_dir_path"
copy_single_file "/proc/mdstat" "keep_dir_path"
copy_single_file "/proc/stat" "keep_dir_path"
copy_single_file "/proc/partitions" "keep_dir_path"
copy_single_file "/proc/scsi/scsi" "keep_dir_path"
copy_single_file "/proc/net/dev" "keep_dir_path"
copy_single_file "/proc/sys/fs/file-nr" "keep_dir_path"
copy_single_file "/proc/sys/fs/inode-nr" "keep_dir_path"
copy_dir "/sys/class/scsi_host" "recursive"
copy_dir "/proc/driver" "recursive"
copy_dir "/proc/scsi" "recursive"
copy_dir "/proc/fs" "recursive"
copy_dir "/proc/ide" "recursive"
copy_dir "/proc/sys" "recursive"
copy_single_file "/etc/modules.conf" "keep_dir_path"
copy_single_file "/etc/*-release" "keep_dir_path"
copy_single_file "/etc/lvm/lvm.conf" "keep_dir_path"
copy_single_file "/etc/raidtab" "keep_dir_path"
copy_single_file "/etc/modprobe.conf" "keep_dir_path"

# List of Commands to Run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "lsmod"
run_single_command "rpm -qa"
run_single_command "ifconfig -a"
run_single_command "df -k"
run_single_command "df -kT"
run_single_command "df -Th"
run_single_command "uname -a"
run_single_command "hostname"
run_single_command "uptime"
run_single_command "date"
run_single_command "ps -efl"
run_single_command "ps -l"
run_single_command "env"

#AP:ADD:GERS_500
run_single_command "dmidecode"

#SD:ADD:S1:GERS_555:To run the 'fdisk -l' command.
run_single_command "fdisk -l"

exit ${RC}
