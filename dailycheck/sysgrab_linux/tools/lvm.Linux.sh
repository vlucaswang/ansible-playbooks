#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script for handling Linux Logical Volume Manager Commands
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Logical Volume Manager"

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

printf "\n\nTarring ${NAME} Log Files\n" | tee -a ${RPT}

# Any specific handling routines here
# MultiStep command for HP-UX Logical Volume Manager

SCRIPT_TMP_SAVE=${SCRIPT_TMP}

printf "\n\nRunning ${NAME} commands for ${OS}\n" | tee -a ${RPT}

CMD="vgdisplay"
CMD_EXIST=`which ${CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`

if [ ${CMD_EXIST} -eq 0 ]
then
	echo "Not found...continuing"

else
	run_single_command "vgdisplay -v"
	run_single_command "pvdisplay -v"
	run_single_command "lvdisplay -v"
	run_single_command "lvmdiskscan"
	run_single_command "pvscan -v"
	run_single_command "lvs -v"
	run_single_command "pvs -v"
	run_single_command "vgs -v"
	run_single_command "lvm version"
	run_single_command "lvm dumpconfig"
	copy_single_file "/etc/lvm/lvm.conf"
	tar_dir "/etc/lvm" "lvm_backups.tar"
fi


exit ${RC}
