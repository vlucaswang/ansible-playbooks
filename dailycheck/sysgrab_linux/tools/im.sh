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
NAME="InfoMover IFS/IFT"

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

for i in ift ifs
do

        FILE=${i}
        BASENAME=${FILE}
        export BASENAME

        # If PPVM temporary directory exists, exit to avoid duplicate
        # module operation

        if [ -x ${SCRIPTS}/${FILE}.sh ]
        then
                sh ${SCRIPTS}/${FILE}.sh
        else
                printf "\nModule ${FILE} not found. Skipping ...\n" | tee -a ${RPT}
        fi
done

exit $RC
