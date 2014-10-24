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

# List of files to copy

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/etc/vx/emc.d/config.txt"
copy_single_file "/etc/vx/*.exclude"

#SD:GERS_463 - Command added to copy Veritas Log file for both GUI and CLI.
copy_single_file "/var/vx/isis/command.log" "keep_dir_path"
copy_single_file "/var/adm/vx/cmdlog" "keep_dir_path"


# List of commands to run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "vxdisk list"
run_single_command "vxdisk -e list"
run_single_command "vxdisk -s list"
run_single_command "vxdisk -o alldgs list"
run_single_command "vxdg list"
run_single_command "vxprint -ht"
run_single_command "vxprint -m rootdg"
run_single_command "vxdmpadm listctlr all"
run_single_command "vxdmpadm listenclosure all"
run_single_command "vxdmpdbprint"
run_single_command "vxddladm listjbod"
run_single_command "vxddladm listsupport"
run_single_command "vxdctl mode"
run_single_command "vxdctl -c mode"
run_single_command "vxlicense -p"
run_single_command "vxlicrep"
run_single_command "vxlicrep -e"
run_single_command "vxdmpadm listapm all" #AP:GERS_584
run_single_command "vxdmpadm stat restored" #AP:GERS_400

#PA:GERS_465 - Added "vxdmpadm getattr" command to determine iopolicy

enclName=`vxdmpadm listctlr all | cut -c46-90 | tail +3`
for name in $enclName
do
run_single_command "vxdmpadm getattr enclosure $name iopolicy"
done

#PA:GERS_485
if [ "${VXDMPDEBUG}" = "Y" ]
then
    printf "\nRunning vxdmpdebug script...\n" | tee -a ${RPT} 
    `echo "y" | vxdmpdebug`
    tempFile=`ls -rt /tmp/ | tail -1`
    `mv -f /tmp/$tempFile /tmp/vxdmpdebug.txt`
    copy_single_file "/tmp/vxdmpdebug.txt"
fi

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

# List / generate map files for each known disk group

CMD=vxdg
CMD_EXIST=`which ${CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
if [ ${CMD_EXIST} -eq 1 ]
then
	for DG in `vxdg -q list 2>> ${ERR_RPT} | awk '{ print $1 }'`
	do
		run_single_command "vxdg list ${DG}"
		run_single_command "vxprint -g ${DG} -Qqm" 
	done
fi

exit ${RC}
