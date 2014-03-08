#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script to collect Host specific configuration information
#
RC=0
SCRIPT_TMP=$EMC_TMP/${BASENAME}
COMMANDS=${SCRIPTS}/${CMD_DIR}/commands.${OS}
FILES=${SCRIPTS}/${FILE_DIR}/files.${OS}
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

# check_dir	- Check for existance of temporary directory
# copy_files	- Copy files from $FILES 
# run_commands	- Execute commands from $COMMANDS

check_dir

#
# Specific Handling for Linux
#

if [ ${OS} = "Linux" ]
then
	# List of Files to Copy
	copy_single_file "/var/log/messages*"
	copy_single_file "/var/log/boot.log*"
	copy_single_file "/var/log/dmesg"
	copy_single_file "/proc/version"
	copy_single_file "/usr/src/linux-${OS_VER}/drivers/scsi/scsi_scan.c"
	copy_single_file "/usr/src/linux-${OS_VER}/drivers/scsi/scsi_merge.c"
	copy_single_file "/usr/src/linux-${OS_VER}/drivers/scsi/sd.c"

	# List of Commands to Run
	exit ${RC}
fi
copy_files

run_commands

#
# Specific Handling Routines for SunOS, AIX, HP-UX and OSF1
#

#
# Specific Handling for SunOS
#

if [ ${OS} = "SunOS" -a -f /kernel/drv/fjpfca.conf ]
then
	echo "\n\nSpecific Options for Fujitsu HBAs" | tee -a ${RPT}
	copy_single_file "/kernel/drv/fjpfca.conf"
	PATH=${PATH}:/usr/sbin/FJSVpfca ; export PATH
	MAN_CMD="fc_info"
	CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
	if [ ${CMD_EXIST} -eq 0 ]
	then
		echo "Command ${MAN_CMD} not found....continuing" | tee -a ${RPT}
	else
		run_single_command "${MAN_CMD} -a"
		run_single_command "${MAN_CMD} -p"
		run_single_command "${MAN_CMD} -c"
		for ADAPTER in `${MAN_CMD} -a | awk '/^adapter=/ { print substr($1,9) }'`
		do
			run_single_command "${MAN_CMD} -i ${ADAPTER}"
		done
	fi
fi

#
# Specific Handling for AIX
#

if [ ${OS} = "AIX" ]
	then
	MAN_CMD=lscfg
	CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
	if [ ${CMD_EXIST} -eq 0 ]
	then
		echo "Command ${MAN_CMD} not found....continuing" | tee -a ${RPT}
	else
		FC=`lsdev -Cc adapter | grep fchan | awk '{ print $1 }'` 
		if [ `echo ${FC} | awk '{ print NF }'` -eq 0 ]
		then
			FC=`lsdev -Cc adapter | grep fcs | awk '{ print $1 }'`
			ADAPTER="0"
		else
			ADAPTER="1"
		fi

		if [ `echo ${FC} | awk '{ print NF }'` -ge 1 ]
		then 
			for INSTANCE in ${FC}
			do
				run_single_command "${MAN_CMD} -vl ${INSTANCE}" 
				run_single_command "lsattr -El ${INSTANCE}"
				if [ $ADAPTER -eq 0 ]
				then
					FC_CHILD=`echo ${INSTANCE} | sed -e 's/fcs/fscsi/g'`
				else
					FC_CHILD=`echo ${INSTANCE} | sed -e 's/fchan/fcp/g'`
				fi

				run_single_command "lsattr -El ${FC_CHILD}"
			done
		else
			echo "\nNo known fibre channel adapters found" | tee -a ${RPT}
		fi
	fi

	# Run lsattr against each entry reported by lsdev -C

	for i in `lsdev -C | awk '{ print $1 }'`
	do
		echo "---- lsattr -El $i ----" >> "${SCRIPT_TMP}/lsattr_lsdev_-C.txt"
		lsattr -El $i >> "${SCRIPT_TMP}/lsattr_lsdev_-C.txt"
	done
fi

#
# Specific Handling for HP-UX
#

if [ ${OS} = "HP-UX" ]
	then
	MAN_CMD=fcmsutil
	CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
	if [ ${CMD_EXIST} -eq 0 ]
	then
		echo "Command ${MAN_CMD} not found....continuing" | tee -a ${RPT}
	else
		HBA_TD=`ls -l /dev | grep td | awk '$10 ~ /td/ { print $10 }'`
		HBA_FCM=`ls -l /dev | grep fcm | awk '$10 ~ /fcm/ { print $10 }'`
		FC="${HBA_TD} ${HBA_FCM}"
        	if [ `echo ${FC} | awk '{ print NF }'` -eq 0 ]
        	then
			echo "\nNo known fibre channel adapters found" | tee -a ${RPT}
		else
			for INSTANCE in ${FC}
			do
				run_single_command "${MAN_CMD} /dev/${INSTANCE}" 
				run_single_command "${MAN_CMD} /dev/${INSTANCE} stat" 
			done
		fi
    	fi

	#
	# Routine for calling Customer Support Tool Manager (cstm)
	# This calls the script cstm.sh
	#
	MAN_CMD=cstm
	CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
	if [ ${CMD_EXIST} -eq 1 ]
	then
		printf "\n\nRunning Support Tool Manager (${MAN_CMD}) " | tee -a ${RPT}
		${SCRIPTS}/cstm.sh &
		PID=$!
		while [ `ps -p ${PID} | wc -l` -eq 2 ]
		do
			sleep 1
			printf "."
		done
	else
		printf "\n\nSupport Tool Manager (${MAN_CMD}) not found"
	fi

fi

#
# Specific Handling for OSF1 / Tru64
#

if [ ${OS} = "OSF1" ]
	then
	MAN_CMD=emxmgr
	CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
	if [ ${CMD_EXIST} -eq 0 ]
	then
		echo "Command ${MAN_CMD} not found....continuing" | tee -a ${RPT}
	else
		FC=`${MAN_CMD} -d | awk '$1 ~ /emx/ { print $0 }'`
		if [ `echo ${FC} | awk '{ print NF }'` -ge 1 ]
		then
			for INSTANCE in ${FC}
			do
			run_single_command "${MAN_CMD} -t ${INSTANCE}" 
			done
		else
			echo "\nNo known fibre channel adapters found" | tee -a ${RPT}
		fi
	fi
fi


exit ${RC}
