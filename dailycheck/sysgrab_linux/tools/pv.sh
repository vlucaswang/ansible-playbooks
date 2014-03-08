#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
#	Set initial return code
RC=0

SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="PowerPath Volume Manager (PPVM)"

# Obtain installation path from pkginfo
if [ ${OS} = "SunOS" ]
then

	INST_PATH=`pkginfo -r EMCpower`
	PATH=${PATH}:${INST_PATH}/EMCpower/bin:${INST_PATH}/EMCpower/bin/sparcv9

elif [ ${OS} = "HP-UX" ]
then
	INST_PATH=/opt
	PATH=${PATH}:${INST_PATH}/EMCpower/bin

fi

export PATH

RUNTIME=120

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

check_dir

# List of files to copy

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/etc/PPVM_config*"
copy_single_file "/.profile"

# In case customer defines alternative path for log files during installation
# This will only work if the command powervadm is detected

CMD=powervadm
CMD_EXIST=`which ${CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`

if [ ${CMD_EXIST} -eq 0 ]
then
	printf "\n\n${CMD} ....not found - continuing" | tee -a ${RPT}

else

	LOG_DIR=`powervadm info | grep "Log Directory" | cut -f2 -d":"` 
	LOG_PATH=`dirname ${LOG_DIR} | sed 's/ //g'`

	export LOG_DIR LOG_PATH

	copy_single_file "${LOG_PATH}/PPVM_audit_log*"
	copy_single_file "${LOG_PATH}/PPVM_host_info_${HOSTNAME}"

	# List of commands to run

	printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

	run_single_command "pkgparam -v EMCPPsdk"
	run_single_command "pkgparam -v EMCvg"
	run_single_command "emcpmgr list"
	run_single_command "emcpmgr list -p"
	run_single_command "emcpmgr version"
	run_single_command "powervadm activeCmds"
	run_single_command "powervadm getConfig"
	run_single_command "powervadm info"
	run_single_command "powervadm list"
	run_single_command "powervadm list -vg"
	run_single_command "powervadm show"
	run_single_command "powervadm show -hostinactive"

	# Build list of Volume Groups

	VG=`powervadm list -vg | awk 'NF == 1 { print $1 }'`

	# Run commands against each imported Volume Group

	SCRIPT_TMP_SAVE=${SCRIPT_TMP}
	for i in ${VG}
	do
		echo "\n\nRunning Commands against Volume Group : ${i}" | tee -a ${RPT}

		SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}

		check_dir

		run_single_command "powervg list -vg ${i} -vol"
		run_single_command "powervg show -vg ${i}"
		run_single_command "powervg show -vg ${i} -se"
		run_single_command "powervg show -vg ${i} -se -sf native"
		run_single_command "powervg show -vg ${i} -se -sf arrayunique"
		run_single_command "powervg show -vg ${i} -se -sf pseudo"
	
		# Backup VG Meta Data to file

		run_single_command "powervmeta backup -vg ${i} -f ${SCRIPT_TMP}/powervmeta_backup_${i}" "powervmeta_backup_-f_powervmeta_backup_${i}"

		# Build list of Volumes within specified Disk Group

		VOL=`powervg list -vg ${i} -vol | awk '$1 ~ /[0-9]/ { print $3 }'`

		for j in ${VOL}
		do
			echo "\n\nRunning Commands against Volume ${j} : (Group ${i})" | tee -a ${RPT}
			run_single_command "powervol show -vg ${i} -vol ${j}"
			run_single_command "powervol show -vg ${i} -vol ${j} -layout"
			run_single_command "powervol show -vg ${i} -vol ${j} -sf native"
		done
	done

	SCRIPT_TMP=${SCRIPT_TMP_SAVE}

fi

exit ${RC}
