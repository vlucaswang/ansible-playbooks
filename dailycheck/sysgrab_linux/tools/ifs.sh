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
NAME="InfoMover File Server (IFS)"

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

SCRIPT_TMP_SAVE=${SCRIPT_TMP}
SCRIPT_TMP=${SCRIPT_TMP_SAVE}/ifs

INSTALL=/opt/emc/ifs

if [ -d ${INSTALL} ]
then
	printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

	copy_single_file "${INSTALL}/etc/iscfg.xml"
	copy_single_file "${INSTALL}/etc/ifs.env"
	copy_single_file "${INSTALL}/etc/ifs.server"

	cd ${INSTALL}/etc/log

	FILE_LIST=`find . -name EMCISlog\* -mtime 14 -print`

        if [ -n "${FILE_LIST}" ]
        then
		printf "\nTarring ${NAME} Log Files" | tee -a ${RPT}
                tar_files "${FILE_LIST}" "ifs_logs.tar"
        else
                printf "\n\nNo log files found modified in the past 14 days" | tee -a ${RPT}
        fi
	copy_single_file "/tmp/EMCERR"
fi


exit $RC
