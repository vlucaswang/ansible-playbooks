#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#

RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Veritas Cluster Server"

PATH=$PATH:/opt/VRTSvcs/bin
export PATH

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

# Notification to advise customers to run EMCGrab on all
# clustered hosts

printf "\n\nPlease run EMCGrab on all hosts within the Cluster" | tee -a ${RPT}

sleep 2

# check_dir	- Check for existance of temporary directory

check_dir

# List of files to copy

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/etc/VRTSvcs/conf/config/main.cf"
copy_single_file "/etc/VRTSvcs/conf/config/types.cf"
copy_single_file "/var/VRTSvcs/log/engine_*.log"
copy_single_file "/var/VRTSvcs/log/hashadow-err_*.log"
copy_single_file "/var/VRTSvcs/log/hashadow_*.log"
copy_single_file "/etc/llttab"
copy_single_file "/etc/gabtab"
copy_single_file "/etc/llthosts"

# The following files are Geospan for VCS specific

copy_single_file "/var/VRTSvcs/log/EMC*.log"

# List of commands to run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "hastatus -summary"
run_single_command "hares -display"
run_single_command "hagrp -display"
run_single_command "haevent -display"
run_single_command "hasys -list"
run_single_command "hasys -state"
run_single_command "hasys -nodeid"
run_single_command "hatype -display"
run_single_command "hatype -list"
run_single_command "haclus -display"
run_single_command "llstat"
run_single_command "gabconfig -a"

exit ${RC}
