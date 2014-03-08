#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script for handling Solutions Enabler commands
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Solutions Enabler"

PATH=${PATH}:/usr/symcli/bin:/usr/symcli/storbin

RUNTIME=480

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

copy_single_file "/var/symapi/config/symapi_licenses.dat"

echo >> ${RPT}

# Specific handling routine for Solutions Enabler
# Check for existance of gatekeeper, before running commands
# Assumption that syminq is available, if Solutions Enabler installed

MAN_CMD=syminq
CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`

if [ ${CMD_EXIST} -eq 0 ]
then
	printf "\nUnable to find syminq....continuing" | tee -a ${RPT}
	exit 0
else
	echo 
	run_single_command "${MAN_CMD}"

	#	Check if any output from $MAN_CMD.  If so, assume $MAN_CMD 
	# 	is installed
	if [ -f ${SCRIPT_TMP}/${MAN_CMD}.txt ]
    	then
		#
		# Build variable list detailing number of gatekeepers detected
		#
		# Mode 		0 Gatekeepers		>0 Gatekeepers
		# autoexec	Skip commands		Run commands
		# interactive	Prompt customer		Run commands
		#
		GKLIST=`cat ${SCRIPT_TMP}/${MAN_CMD}.txt | awk '$2 ~ /GK/ && $7 ~ /2880/ { print $1 }' | wc -l`
       		if [ ${GKLIST} -eq 0 -a ${AUTOEXEC} -eq 0 ]
       		then
				RUN=OFF
           			break ;
       		elif [ ${GKLIST} -eq 0 -a ${AUTOEXEC} -eq 1 ]
		then
			printf "\n\n" | tee -a ${RPT}

# Display the following Warning Message if no Gatekeepers detected

cat << EndWarning | tee -a ${RPT}

***************************** WARNING *****************************
  No GateKeepers have been detected.  If you choose to continue,
  Solutions Enabler will choose a device to communicate with the
  Symmetrix. This device may be part of a data volume, and under 
  heavy I/O may have an impact on your performance.
*******************************************************************

EndWarning

			printf "Do you wish to continue (y/n) : "
			while read ANS
			do
				case ${ANS} in
				y|Y) echo "Continuing running ${NAME} Commands" | tee -a ${RPT}
					RUN=ON
					break
					;;
				n|N) printf "\nYou have chosen to abort ${NAME} commands" | tee -a ${RPT}
					RUN=OFF
					break
					;;
				*) echo "Please answer (y/n) : \c"
			  		;;
				esac
			done
		else
			RUN=ON
		fi
	else 
       		echo "Output from ${CMD} not found....continuing" | tee -a {$RPT}
    	fi
fi

# Specific handling for repeat commands based on unique 
# Symmetrix Serial Number

if [ ${RUN} = "ON" ]
then
	# List of commands to run.  The following are generic

	printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

	run_single_command "symcfg -v list"

	SCRIPT_TMP_SAVE=${SCRIPT_TMP}
	NAME_SAVE=${NAME}

  	for i in `symcfg list | awk 'NF ==7 { print $1 }' | grep [0-9]`
  	do

    		SYMCLI_SID=${i}
		export SYMCLI_SID

      		SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}
		NAME="${NAME_SAVE} Commands against Symmetrix ${i}"

		check_dir

		# List of commands to run.  These are targetted against
		# a specific Symm, as defined by SYMCLI_SID

		printf "\n\nRunning ${NAME}\n" | tee -a ${RPT}

		run_single_command "symcfg -dir all -v list"
		run_single_command "symcfg -connections list"

	done

	# Restore variables to normal in case further processing desired

	SCRIPT_TMP=${SCRIPT_TMP_SAVE}
	NAME=${NAME_SAVE}

fi

echo | tee -a ${RPT}

exit ${RC}
