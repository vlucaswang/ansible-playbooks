#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Model script for a new component
#
#-------------------------------------------------------------------------------

#	Set initial return code
RC=0

# Basename is the name of this script without the .sh suffix
# Directory for command output and files
SCRIPT_TMP=${EMC_TMP}/${BASENAME}

# Some Appropriate ID for this component
NAME="EMC Open Migrator/LM (DRU)"

# Specify a specific RUNTIME for module, overriding the default
# defined in tools.main.  This value is based in seconds
RUNTIME=60

if [ ! -f $SCRIPTS/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	exit 1
else
	. $SCRIPTS/tools.main
fi

# check_dir	- Check for existance of temporary directory

#	Checks creates $SCRIPT_TMP directory
check_dir

# Define list of files and commands using functions
# copy_single_file, and run_single_command.  For a full list of all the available
# functions, refer to tools.main

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

INSTALL="/etc/opt/EMCom"
if [ -d ${INSTALL} ]
then
	cd ${INSTALL} && tar_dir "clirep" "clirep.tar"
	cd ${INSTALL} && tar_dir "properties" "properties.tar"
fi

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "stormigrate"
run_single_command "stormigrate -def"
run_single_command "stormigrate list"
run_single_command "stormigrate tune"
run_single_command "stormigrate props"

SCRIPT_TMP_SAVE=${SCRIPT_TMP}

MAN_CMD=stormigrate
CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`

if [ ${CMD_EXIST} -eq 1 ]
then
	SESSIONS=`stormigrate list 2> /dev/null | awk 'NF == 2 {print $1}' | tail +3`

	if [ -n "${SESSIONS}" ]
	then
		printf "\n\nListing Configured Sessions\n" | tee -a ${RPT}
		for i in ${SESSIONS}
		do
			SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}
			check_dir

			run_single_command "stormigrate show -session ${i}"
			run_single_command "stormigrate query -session ${i}"
		done
	else
		printf "\nNo Sessions Found\n" | tee -a ${RPT}
	fi
fi
	
SCRIPT_TMP=${SCRIPT_TMP_SAVE}

if [ -d /var/emcom/log ]
then
	printf "\n\nCollecting Open Migrator logs modified in the last 14 days" | tee -a ${RPT}

	cd /var/emcom/log && FILE_LIST=`find . -name emcom\*log -mtime -14 -print`

	if [ -n "${FILE_LIST}" ]
	then 
		tar_files "${FILE_LIST}" "omlogs.tar"
	else
		printf "\n\nNo files found modified in the past 14 days" | tee -a ${RPT}
	fi
elif [ -d /var/EMCom/log ]
then
	printf "\n\nCollecting Open Migrator logs modified in the last 14 days" | tee -a ${RPT}

	cd /var/EMCom/log && FILE_LIST=`find . -name emcom\*log -mtime -14 -print`

	if [ -n "${FILE_LIST}" ]
	then 
		tar_files "${FILE_LIST}" "omlogs.tar"
	else
		printf "\n\nNo files found modified in the past 14 days" | tee -a ${RPT}
	fi
else
	printf "\n\nOpen Migrator Log Directory Not Found" >> ${RPT}
fi

exit $RC
