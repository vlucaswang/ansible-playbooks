#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#	Set initial return code
RC=0

SCRIPT_TMP=${EMC_TMP}/${BASENAME}

NAME="EMC Replication Manager"

RUNTIME=60

if [ ! -f $SCRIPTS/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	exit 1
else
	. $SCRIPTS/tools.main
fi

check_dir

# Define list of files and commands using functions
# copy_single_file, and run_single_command.  For a full list of all the available
# functions, refer to tools.main


ERMDIR=/var/sadm/pkg/IR

if [ -d ${ERMDIR} ]
then
	echo "\nCollecting ${NAME} files" | tee -a ${RPT}
	BINLOC=`grep "Client=" ${ERMDIR}/IRIndicator | cut  -b8-666 |cut -f1 -d "|"`
	${BINLOC}/bin/ermer -silent -c ${HOSTNAME} -l ${SCRIPT_TMP}
else
	echo "\nNo Replication Manager files found" >> ${RPT}
fi

exit $RC
