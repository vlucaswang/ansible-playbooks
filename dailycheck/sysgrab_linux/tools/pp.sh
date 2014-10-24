#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="PowerPath"

RUNTIME=120

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

# check_dir	- Check for existance of temporary directory

check_dir

# List of files to copy

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/etc/rcS.d/S24powerstartup"
copy_single_file "/etc/powermt.custom"
copy_single_file "/etc/emcp_registration"
copy_single_file "/etc/powerpath_registration"
copy_single_file "/kernel/drv/emcp.conf"
copy_single_file "/opt/emcpower/emcpower.conf"
copy_single_file "/etc/emc/mpaa.*"
copy_single_file "/etc/emcp_devicesDB.dat"
copy_single_file "/etc/emcp_devicesDB.idx"
copy_single_file "/etc/emc/powerkmd.custom"
copy_single_file "/etc/modprobe.conf.pp"

#PA:ADD:GERS_594 - To collect error logs for latency monitoring
copy_single_file "/tmp/emcpsys*.*"

# List of commands to run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "powermt display"
run_single_command "powermt display dev=all"
run_single_command "powermt check_registration"

# Specific commands for PowerPth 3.x or later

run_single_command "powermt version"
run_single_command "powermt display options"
run_single_command "powermt display ports"
run_single_command "powermt display paths"
run_single_command "powermt display unmanaged"
run_single_command "powermt dump"

# Specific command for PPME in PPV5.0

run_single_command "powermig info -all -query"
copy_dir "/etc/emc/ppme" "recursive"

# Solaris Specific

if [ ${OS} = "SunOS" ]
then
	run_single_command "pkgparam -v EMCpower"

        #AP:GERS_629 - Collect new information on PowerPath Solaris 5.2 with RSA Encryption
        
        run_single_command "powervt version"

        if [ ! -f /etc/emc/.xcrypt_cfg_done ]
        then
              echo "Encryption has not been configured....exiting"
              exit 2
        else
              run_single_command "powervt xcrypt -info -dev all"
              copy_dir "/etc/emc/rsa/rkm_client/config"
              copy_dir "/etc/emc/rsa/cst/config"
        fi
fi

# Linux Specific

if [ ${OS} = "Linux" ]
then
	copy_dir "/etc/opt/emcpower"

       	#SD:GERS_1114 - Command to collect the Management Daemon file snmpd.conf
	copy_single_file "/etc/snmpd.conf" "keep_dir_path"

        #SD:GERS_1110 - Collect new information on PowerPath Linux 5.3  with RSA Encryption
        run_single_command "powervt version"

        if [ ! -f /etc/emc/.xcrypt_cfg_done ]
        then
              echo "Encryption has not been configured....exiting"
              exit 2
        else
              run_single_command "powervt xcrypt -info -dev all"
              copy_dir "/etc/emc/rsa/rkm_client/config"
              copy_dir "/etc/emc/rsa/cst/config"
        fi
	
fi

# HP Raid Manager Specific

if [ -d /HORCM ]
then

	# Run the raidquery command
	run_single_command "raidqry -h"

fi

# 
# Perform check to see whether any Volume Groups are configured
# by checking for any directories in /dev/emc/dsk
# This is specific to Powerpath 4.x or later
# 
# Volume Group Directories are created under
# /dev/emc (AIX)
# /dev/emc/dsk (SunOS and HP-UX)

# We are only interested in the exit code, hence /dev/null redirect

if [ ${OS} = "AIX" ]
then
        #SD:GERS_1112 - Collect new information on PowerPath AIX 5.3 with RSA Encryption
        run_single_command "powervt version"

        if [ ! -f /etc/emc/.xcrypt_cfg_done ]
        then
              echo "Encryption has not been configured....exiting"
              exit 2
        else
              run_single_command "powervt xcrypt -info -dev all"
              copy_dir "/etc/emc/rsa/rkm_client/config"
              copy_dir "/etc/emc/rsa/cst/config"
        fi 

	ls -d /dev/emc/* > /dev/null 2>&1
	RC=$?

else
	ls -d /dev/emc/dsk/* > /dev/null 2>&1
	RC=$?
fi

if [ ${RC} -eq 0 ]
then

	FILE=ppvm
	BASENAME=${FILE}
	export BASENAME

	# If PPVM temporary directory exists, exit to avoid duplicate
	# module operation

	if [ -d ${EMC_TMP}/${BASENAME} ]
	then 
		exit ${RC}

	elif [ -x ${SCRIPTS}/${FILE}.sh ]
	then
		sh ${SCRIPTS}/${FILE}.sh
	else
		printf "\nModule ${FILE} not found. Skipping ...\n" | tee -a ${RPT}
	fi
fi

exit ${RC}
