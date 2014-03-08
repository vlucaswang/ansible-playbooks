#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
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
copy_single_file "/etc/inittab" "keep_dir_path"
#copy_dir "/sys" "recursive"
#copy_dir "/proc"
#copy_dir "/proc/driver" "recursive"
#copy_dir "/proc/scsi" "recursive"
#copy_dir "/proc/fs" "recursive"
#copy_dir "/proc/ide" "recursive"
#copy_dir "/proc/irq" "recursive"
#copy_dir "/proc/net" "recursive"
#copy_dir "/proc/sys" "recursive"
#copy_dir "/proc/sysvipc" "recursive"
#copy_dir "/proc/tty" "recursive"
tar_files "/etc/rc*" "rcfiles.tar"
tar_dir "/etc/rc.d" "rcdir.tar"

# For RedHat 2.6 kernels
#copy_dir "/usr/src/kernels/${OS_TYP}-${OS_MOD}/drivers/scsi" "recursive"
# SD:GERS_1011 : Added command to copy the files and folders under the path "/etc/sysconfig".
copy_dir "/etc/sysconfig" "recursive"
# SD:GERS_1063 : Added command to copy the files and folders under the path "/etc/udev".
#copy_dir "/etc/udev" "recursive"


#############################
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/Config.in" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/Makefile" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/hosts.c" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/hosts.h" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/scsi.c" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/sg.h" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/scsi_scan.c" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/scsi_merge.c" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/sd.c" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/drivers/scsi/lpfc/lpfc.conf.c" "keep_dir_path"
#copy_single_file "/usr/src/linux-${OS_VER2}/include/linux/tasks.h" "keep_dir_path"
#copy_single_file "/usr/include/scsi/sg.h" "keep_dir_path"
copy_single_file "/etc/fstab" "keep_dir_path"
copy_single_file "/etc/lilo.conf" "keep_dir_path"
copy_single_file "/etc/grub.conf" "keep_dir_path"
copy_single_file "/etc/modules.conf" "keep_dir_path"
copy_single_file "/etc/issue" "keep_dir_path"
copy_single_file "/etc/*-release" "keep_dir_path"
copy_single_file "/etc/rc.modules" "keep_dir_path"
copy_single_file "/etc/lvm/lvm.conf" "keep_dir_path"
copy_single_file "/etc/raidtab" "keep_dir_path"
copy_single_file "/boot/grub/grub.conf" "keep_dir_path"
copy_single_file "/boot/grub/menu.lst" "keep_dir_path"
#copy_single_file "/boot/initrd-${OS_VER2}.img" "keep_dir_path"
copy_single_file "/home/emulex/driver/lpfc.conf.c" "keep_dir_path"
copy_single_file "/proc/mdstat" "keep_dir_path"
copy_single_file "/etc/modprobe.conf" "keep_dir_path"
copy_single_file "/etc/modprobe.conf.local" "keep_dir_path"
copy_single_file "/etc/multipath.conf" "keep_dir_path"
copy_single_file "/var/lib/multipath/bindings" "keep_dir_path"
copy_single_file "/etc/iscsi.conf" "keep_dir_path"
copy_single_file "/etc/initiatorname.iscsi" "keep_dir_path"
copy_single_file "/etc/sysctl.conf" "keep_dir_path"

copy_single_file "/etc/group" "keep_dir_path"
copy_single_file "/etc/passwd" "keep_dir_path"
copy_single_file "/etc/services" "keep_dir_path"
copy_single_file "/etc/hosts" "keep_dir_path"
copy_single_file "/etc/env.local" "keep_dir_path"
copy_single_file "/etc/rc.local" "keep_dir_path"
copy_single_file "/etc/profile" "keep_dir_path"
copy_single_file "/etc/bashrc" "keep_dir_path"
copy_single_file "/etc/environment" "keep_dir_path"


#PA:ADD:S1:GERS_489 - To inclde system.map file 
# copy_single_file "/boot/System.map*" "keep_dir_path"   # Delete by spender
#PA:ADD:E1:GERS_489 - To inclde system.map file

# The following are Linux SuSE specific

copy_single_file "/etc/init.d/boot.localfs" "keep_dir_path"

# List of Commands to Run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "ls -Ralsi /usr/src"
run_single_command "ls -Ralsi /lib/modules"
run_single_command "ls -Ralsi /boot"
run_single_command "ls -Ralsi /dev"
run_single_command "lsmod"
run_single_command "lspci"
run_single_command "lspci -v"
run_single_command "lspci -vv"
run_single_command "rpm -qa"
run_single_command "ipcs -a"
run_single_command "crontab -l"
run_single_command "netstat -a"
run_single_command "netstat -r"
run_single_command "netstat -nr"
run_single_command "arp -a"
run_single_command "rpcinfo -p"
run_single_command "df -k"
run_single_command "df -kT"
run_single_command "df -Th"
run_single_command "uname -a"
run_single_command "hostname"
run_single_command "ulimit -a"
run_single_command "uptime"
run_single_command "date"
run_single_command "ps -efl"
run_single_command "ps -l"
run_single_command "env"
run_single_command "multipath -ll"
run_single_command "iscsi-ls -l"
run_single_command "iscsi-ls -c"
run_single_command "ip address"
run_single_command "ifconfig -a"

# SD:GERS_1063 : Added commands to capture output of "dmsetup ls", "dmsetup info" and "udevinfo".
run_single_command "dmsetup ls"
run_single_command "dmsetup info"

MAN_CMD=udevinfo
CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`

if [ ${CMD_EXIST} -eq 1 ]
then
	udevinfo -e > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
            	run_single_command "udevinfo -e"
	else
		run_single_command "udevinfo -d"
	fi
fi

#SD:GERS_440:Added 'dmesg' command for SuSE ES 10.

if [ ! -f /var/log/dmesg ]
then 
    run_single_command "dmesg"
fi    

#PA:GERS_441:Added command to capture iscsi session data
run_single_command "iscsiadm -m session --info"

printf "\n\nEnd of ${NAME} Specific Commands\n" | tee -a ${RPT}

#SD:ADD:S1:GERS_555:To run the 'fdisk -l' command.
run_single_command "fdisk -l"
#AP:ADD:GERS_466
run_single_command "fdisk -lu"
#AP:ADD:GERS_500
run_single_command "dmidecode"

#AP:GERS_809:Added commands to locate scsi devices. 
#These commands require "lsscsi" utility

run_single_command "lsscsi -c -l -k"
run_single_command "lsscsi -H -v -d -g"
run_single_command "lsscsi -v -d -g"

exit ${RC}
