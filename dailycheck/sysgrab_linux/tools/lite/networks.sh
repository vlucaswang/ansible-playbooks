#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2009-2012 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script for handling EMC Networker Commands
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Network"

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

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}
#Copy network files, if needed in future

# List of commands to run
printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

MAN_CMD=inquire
CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`

if [ ${CMD_EXIST} -eq 0 ]
then
	printf "\nUnable to find inquire....continuing" | tee -a ${RPT}
else
        run_single_command "${MAN_CMD}"
fi

exit ${RC}
