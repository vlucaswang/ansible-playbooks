#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#	Set initial return code
RC=0

SCRIPT_TMP=${EMC_TMP}/${BASENAME}

NAME="EMC Recover Point Driver"
RUNTIME=180

if [ ! -f $SCRIPTS/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	exit 1
else
	. $SCRIPTS/tools.main
fi

check_dir

#
# OS specific commands
#

if [ ${OS} = "SunOS" -o ${OS} = "AIX" ]
then
	RP_DIR="/kdriver/info_collector"
	if [ -d ${RP_DIR} ]
        then 
        	printf "\n\nCollecting information on ${NAME}\n" | tee -a ${RPT}
        	printf "\n\nGetting Input Values for ${NAME}\n" | tee -a ${RPT}
        	cd ${RP_DIR}
        	tempFile="inputValues"
        	printf "AID\nANAME\nCNAME\nCMAIL\n" | tee -a ${tempFile}
        	./info_collect.sh < ${tempFile}
        	rm -rf ${tempFile}
        	logFile=`ls -rt *.tar.gz | tail -1 | awk /${HOSTNAME}/`
		cd ${HOME}
                copy_single_file "${RP_DIR}/${logFile}"
        else 
        	printf "\n Directory ${RP_DIR} doesn't exist" | tee -a ${RPT}
        	exit 2
        fi
else
        printf "\n\nUnable to proceed with Recover Point....exiting"
        printf "\nCurrent version of EMCGrab supports logs collection using Recover Point only for Solaris and AIX host.\n" 
fi

exit ${RC}
