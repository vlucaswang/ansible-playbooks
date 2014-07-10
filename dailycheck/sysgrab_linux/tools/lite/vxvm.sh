#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script for handling Veritas Volume Manager
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Veritas Volume Manager"

PATH=${PATH}:/usr/lib/vxvm/diag.d:/etc/vx/diag.d:/opt/VRTS/bin
export PATH

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


# List of commands to run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "vxdisk list"
run_single_command "vxlicrep"

# Specific Handling Routines for Veritas Volume Manager

# GetDmpNodes for each enclosure as reported by 'listenclosure all'

CMD=vxdmpadm
CMD_EXIST=`which ${CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
if [ ${CMD_EXIST} -eq 1 ]
then
	ENC=`${CMD} listenclosure all | awk '$4 ~ /CONNECTED/ { print $1 }'`
	for i in ${ENC}
	do
		run_single_command "${CMD} getdmpnode enclosure=${i}"
	done
fi


exit ${RC}
