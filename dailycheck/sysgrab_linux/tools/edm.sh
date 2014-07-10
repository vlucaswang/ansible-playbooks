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
NAME="EDM"

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

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/usr/epoch/EB/config/eb.cfg"
copy_single_file "/usr/epoch/etc/patches/eng_patches"
copy_single_file "/usr/epoch/EB/bin/HISTORY"
copy_single_file "/usr/epoch/EB/bin/VERSION"

# List of commands to run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "/usr/epoch/bin/edmproc -list"
run_single_command "/usr/epoch/bin/epshowprod"
run_single_command "/usr/epoch/bin/epshowmod"
run_single_command "/usr/epoch/bin/evmstat -dV"
run_single_command "/usr/epoch/bin/evmstat -lV"
run_single_command "/usr/epoch/bin/edm_client_info"

exit $RC
