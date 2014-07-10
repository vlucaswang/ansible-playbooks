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
NAME="InfoMover File Transfer (IFT)"

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

INSTALL=/opt/emc/ift

if [ -d ${INSTALL} ]
then
	printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

	cd ${INSTALL} 
	printf "\nTarring ${NAME} Configuration Files" | tee -a ${RPT}
	tar_files "*/config/*.ini" "${SCRIPT_TMP}/ift_config.tar"

	FILE_LIST=`find . -name infomover\* -mtime 14 -print`

        if [ -n "${FILE_LIST}" ]
        then
		printf "\nTarring ${NAME} Log Files" | tee -a ${RPT}
                tar_files "${FILE_LIST}" "${SCRIPT_TMP}/ift_logs.tar"
        else
                printf "\n\nNo log files found modified in the past 14 days" | tee -a ${RPT}
        fi
fi


exit $RC
