#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Runs SCSI Inquiry Utility
#
# Updated to reflect support for the latest inq, version 7.3-653
# (SIL Version V6.0.3.0 (Edit Level 653)
#
# Some inqs are based on version 7.3-255, to maintain limited functionality
# despite OS being EOL.

RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="inq - inquiry"

RUNTIME=420

# Added as a separate item for force usage of EMC's inq supplied with EMC Grab
# inq is compressed, therefore needs to be uncompressed before running

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

check_dir

printf "\n\nCollecting ${NAME} Information\n" | tee -a ${RPT}

#       execute INQ

if [ -x ${BIN}/${INQ} ]
then
	DIR_SAVE=`pwd`
	cd ${BIN}

	run_single_command "${INQ} -no_dots"
	run_single_command "${INQ} -no_dots -et"
	run_single_command "${INQ} -no_dots -btl"
	run_single_command "${INQ} -no_dots -compat"
	run_single_command "powerprotect '${INQ} -celerra'"

	# Specific commands only available with later versions of INQ

	if [ ${INQ_MODE} -eq 0 ]
	then
		
		run_single_command "${INQ} -hba"

		# Lets read the original base inq output
		
		SOURCE_FILE="${SCRIPT_TMP}/${INQ}_-no_dots.txt"
		if [ -f ${SOURCE_FILE} ]
		then

			# Determine whether any products are defined as OPEN
			# as this will define whether we call hdsdevs.sh

			grep OPEN ${SOURCE_FILE} > /dev/null 2>&1 

			if [ $? -eq 0 -a -x ${SCRIPTS}/hdsdevs ]
			then
				# There are Hitachi devices found.  
				# Run script hdsdevs.sh
				
				run_single_command "hdsdevs"
				run_single_command "${INQ} -no_dots -f_hds"
				run_single_command "${INQ} -no_dots -hds_wwn"

			fi

			grep DGC ${SOURCE_FILE} > /dev/null 2>&1 

			if [ $? -eq 0 ]
			then
				# There are Data General (Clariion) devices found.  
				# Run script hdsdevs.sh
				
				run_single_command "${INQ} -no_dots -clar_wwn"
				run_single_command "${INQ} -no_dots -f_clariion"

			fi

			grep SYMMETRIX ${SOURCE_FILE} > /dev/null 2>&1 

			if [ $? -eq 0 ]
			then
				# There are Symmetrix  devices found.  
				
				run_single_command "${INQ} -no_dots -f_emc"
				run_single_command "${INQ} -no_dots -sym_wwn"

			fi

		fi
	fi

	cd ${DIR_SAVE}

	sleep 5			
else
	printf "\n${BIN}/${INQ} not found" | tee -a ${RPT}
fi

printf "\n" | tee -a ${RPT}

exit ${RC}
