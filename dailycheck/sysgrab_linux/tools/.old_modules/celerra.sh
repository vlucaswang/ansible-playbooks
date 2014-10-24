#!/bin/sh
#-------------------------------------------------------------------------------
# Copyright (C) by EMC Corporation, 2002
# All rights reserved.
#-------------------------------------------------------------------------------
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Celerra"

RUNTIME=300

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

PATH=${PATH}:/nas/bin:/nas/symcli/bin
export PATH

# check_dir	- Check for existance of temporary directory

check_dir

# List of files to copy

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

# The following files are configuration related for the Control Station

copy_single_file "/etc/hosts"
copy_single_file "/etc/fstab"
copy_single_file "/etc/inittab"
copy_single_file "/var/log/message*"
copy_single_file "/etc/modules.conf"
copy_single_file "/etc/host.conf"
copy_single_file "/etc/nsswitch.conf"
copy_single_file "/etc/ntpd.conf"
copy_single_file "/etc/resolv.conf"
copy_single_file "/etc/yp.conf"
copy_single_file "/etc/sysconfig/network-scripts/ifcfg-eth*"
copy_single_file "/etc/sysconfig/clock"
copy_single_file "/etc/sysconfig/network"

# The following commands are related to the Control Station

run_single_command "chkconfig --list"
run_single_command "date"
run_single_command "dmesg"
run_single_command "ifconfig -a"
run_single_command "lsmod"
run_single_command "ls -Ralsi /etc/rc3.d"
run_single_command "ls -Ralsi /etc/cron.*" "ls -Ralsi /etc/cron"
run_single_command "od -d /nas/loc/db/*"
run_single_command "netstat -l"
run_single_command "netstat -r"
run_single_command "ntpq -p"
run_single_command "ps -ef"
run_single_command "route"
run_single_command "uptime"
run_single_command "uname -a"

# The following files are Celerra specific

copy_single_file "/nas/sys/callhome.config"
copy_single_file "/nas/log/sys_log"
copy_single_file "/nas/log/admin_log"
copy_single_file "/nas/log/cmd_log"
copy_single_file "/nas/log/callhome.log"
copy_single_file "/nas/log/install.*.log"
copy_single_file "/nas/log/upgrade.*.log"
copy_single_file "/nas/log/instcli.log"
copy_single_file "/nas/log/symapi.log"
copy_single_file "/nas/log/sibpost.log"
copy_single_file "/nas/log/osmlog"

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "nas_version -l"
run_single_command "nas_symm -list"
run_single_command "nas_server -list"

# List of commands to run.  These are targetted against a 
# specific server instance

SCRIPT_TMP_SAVE=${SCRIPT_TMP}
NAME_SAVE=${NAME}

for i in `server_name ALL | awk '{ print $3 }'`
do
	SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}
	NAME="${NAME_SAVE} Commands against Server : ${i}"

	check_dir

	printf "\n\nRunning ${NAME}\n" | tee -a ${RPT}

	run_single_command "server_uptime ${i}" "server_uptime"
	run_single_command "server_date ${i}" "server_date"
	run_single_command "server_date ${i} timesvc" "server_date timesvc"
	run_single_command "server_version ${i}" "server_version"
	run_single_command "server_devconfig ${i} -list -scsi -all" "server_devconfig -list -scsi -all"
	run_single_command "server_sysconfig ${i} -pci" "server_sysconfig -pci"
	run_single_command "server_sysconfig ${i} -Platform" "server_sysconfig -Platform"
	run_single_command "server_sysstat ${i}" "server_sysstat"

	# Split outputs into cifs sub-directory
	SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}/cifs
	
	check_dir

	run_single_command "server_cifs ${i}" "server_cifs"
	run_single_command "server_cifsstat ${i}" "server_cifsstat"
	# run_single_command "server-cifs ${i} -o audit"

	# Split outputs into nfs sub-directory
	SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}/nfs

	check_dir

	run_single_command "server_nfsstat ${i}" "server_nfsstat"

	# Split outputs into FS sub-directory
	SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}/fs

	check_dir

	run_single_command "server_mount ${i}" "server_mount"
	run_single_command "server_df ${i}" "server_df"
	run_single_command "server_df ${i} -i" "server_df -i"
	run_single_command "nas_disk -list" "nas_disk -list"
	run_single_command "nas_volume -list" "nas_volume -list"
	run_single_command "nas_fs -list" "nas_fs -list"
	run_single_command "nas_fs -info -size -all" "nas_fs -info -size -all"
	run_single_command "server_export ${i}" "server_export"

	# Split outputs into Checkpoints sub-directory
	SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}/chkpts

	check_dir

	# Split outputs into Networks sub-directory
	SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}/network

	check_dir

	run_single_command "server_nis ${i}" "server_nis"
	run_single_command "server_dns ${i}" "server_dns"
	run_single_command "server_route ${i} -l" "server_route -l"
	run_single_command "server_ifconfig ${i} -a" "server_ifconfig -a"
	run_single_command "server_arp ${i} -a" "server_arp"
	run_single_command "server_netstat ${i} -i" "server_netstat -i"
	run_single_command "server_netstat ${i} -r" "server_netstat -r"
	run_single_command "server_sysconfig ${i} -v -l" "server_sysconfig -v -l"

done

SCRIPT_TMP=${SCRIPT_TMP_SAVE}
NAME=${NAME_SAVE}
	
# Check to determine back-end storage

SYMCLI_SID=`symcfg list | awk 'NF == 7 { print $1 }' | grep [0-9]`
CLARIION_IP=`grep SP /etc/hosts | awk '{ print $1 }'`

if [ -n "${SYMCLI_SID}" ]
then
	BASENAME=se
	export SYMCLI_SID BASENAME
	sh ${SCRIPTS}/se.sh
fi

if [ -n "${CLARIION_IP}" ]
then
	BASENAME=clariion
	export CLARIION_IP BASENAME
	sh ${SCRIPTS}/clariion.sh
fi

exit ${RC}
