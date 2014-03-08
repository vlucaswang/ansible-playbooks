#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script for handling ECC commands
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}

RUNTIME=180

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

# Specific handling routines for ECC

# Create empty files to which we can append the configuation and log files
# eccconfig.tar - All *.ini and *.rcfile files
# ecclogs.tar   - All *.log and *.trc files within last 2 days

# If ECC 5.x default installation path is /usr/ecc
# If ECC 4.x default installation path is /usr/emc

#	0 => false   1 => true
FOUND=0

NAME="ECC (version 5.x)"

printf "\n\nCollecting Configuration and Log files for ${NAME}\n" | tee -a ${RPT}

# ECC 5.x

DEF_INSTALL="/usr/ecc"
DIR_NAME=`basename ${DEF_INSTALL}`

check_sw_inst

if [ $? -eq 0 ]
then
	cd ${INSTALL}

	# Build list of Configuration Files

	FILE_LIST=`find ./exec \( -name "*.ini" -o -name "*.rcfile" \) 2>> ${ERR_RPT}`

	if [ -n "${FILE_LIST}" ]
	then
		printf "\nTarring ${NAME} Configuration Files" | tee -a ${RPT}
		tar_files "${FILE_LIST}" "ecc_config.tar"
	else
		printf "\nNo ECC 5.x Configuration Files found" | tee -a ${RPT}
	fi

	# Build list of log files

	FILE_LIST=`find ./exec \( -name "*.log*" -o -name "*.trc" \) -mtime -2 2>> ${ERR_RPT}`

	if [ -n "${FILE_LIST}" ]
	then
		printf "\nTarring ${NAME} Log Files" | tee -a ${RPT}
		tar_files "${FILE_LIST}" "ecc_logs.tar"
	else
		printf "\nNo ${NAME} Log Files found" | tee -a ${RPT}
	fi

fi

echo >> ${RPT}

# ECC 4.x

NAME="ECC (version 4.x)"

printf "\n\nCollecting Configuration and Log files for ${NAME}\n" | tee -a ${RPT}

DEF_INSTALL="/usr/emc/ECC"
DIR_NAME=`basename ${DEF_INSTALL}`

check_sw_inst

if [ $? -eq 0 ]
then
	cd ${INSTALL}

	# If more than one directory is required, create variable DIR_LIST
	# and perform a loop for each entry defined.

	tar_dir "data" "ecc4.tar"

	# Define List of Static Files

	FILE_LIST="EMCversion.log" 

	printf "\nTarring ${NAME} Log Files" | tee -a ${RPT}
	tar_files "${FILE_LIST}" "ecc4.tar"

	# Build List of Poller files 

	FILE_LIST=`find . -name "*poller*"`

	if [ -n "${FILE_LIST}" ]
	then
		tar_files "${FILE_LIST}" "ecc_poller.tar"
	fi
fi



exit ${RC}

