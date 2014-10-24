#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script for handling PowerPath commands
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

run_single_command "powermt version"
run_single_command "powermt display dev=all"
run_single_command "powermt check_registration"

exit ${RC}
