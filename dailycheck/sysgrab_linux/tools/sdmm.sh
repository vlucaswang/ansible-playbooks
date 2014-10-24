#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}

RUNTIME=60

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	exit 1
else
	. ${SCRIPTS}/tools.main
fi

# check_dir	- Check for existance of temporary directory

check_dir


# Prompt user for install location of SDMM if not installed
# in default path of /usr/emc

# This checks for SDMM 1.5.x

NAME="SDMM (version 1.5.x)"

printf "\n\nCollecting Configuration and Log files for '${NAME}'\n" | tee -a ${RPT}

DEF_INSTALL=/usr/emc/sdmm
DIR_NAME=`basename ${DEF_INSTALL}`

check_sw_inst

if [ $? -eq 0 ]
then

	cd ${INSTALL}

	DIR_LIST="config/am config/policy config/profile config/script 
		  config/settings config/site db log"

	for i in ${DIR_LIST}
	do
		tar_dir "${i}" "sdmm_1.5.x.tar"
	done

fi

# This checks for SDMM 2.x

NAME="SDMM (version 2.x)"

printf "\n\nCollecting Configuration and Log files for '${NAME}'\n" | tee -a ${RPT}

DEF_INSTALL=/usr/emc/sdmm2.0
DIR_NAME=`basename ${DEF_INSTALL}`

check_sw_inst

if [ $? -eq 0 ]
then

	copy_single_file "${INSTALL}/*"

	cd ${INSTALL}

	DIR_LIST="*"

	for i in ${DIR_LIST}
	do
		tar_dir "${i}" "sdmm_2.x.tar"
	done

fi

exit ${RC}

