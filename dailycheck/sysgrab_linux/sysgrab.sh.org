#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Author	: EMC Corporation
#

HOME=`pwd`
RC=0

#
# Source environment file
#


if [ -f ${HOME}/sysgrab.main ]
	then
	. ${HOME}/sysgrab.main
else
	echo "Unable to source sysgrab.main"
	RC=1
	echo "RC=1" > $HOME/variables
fi
#
# Capture abnormal exits, user interruption to allow for clean exit
#

trap "clear; echo \"Interrupt Caught....exiting\"; cleanup; exit 1" 1 2 3 15

#
# Lock file management, and ensure clean startup environment
#
start
initialise

#
# Handle command line arguments / parameters
#
# -h		- Display usage
# -v		- Display version
# -o		- Comma seperated list of modules
# -cleanup	- Remove temporary files.  Typically invoked
#		- from 3rd party scripts
# -nodelete	- Don't delete temporary files after completion
# -autoexec	- Bypasses interactive prompts
# -backup	- Takes backup of configuration.  Sets autoexec.
# -clariionIP	- Comma seperated list of IP Addresses for Clariion
# -ip		- Same as for clariionIP
# -symmid       - Allows selection of Symmetrix or bypass of Symmetrix data collection
# -OUTDir	- Define path to Output directory		# MG: ADD: GERS_480 - New command line option added
# -vxdmpdebug   - Runs vxdmpdebug script with 'y' as default option enabled 
#
# The following options are normally used with -autoexec
#
# -EMCDir	- Define path to EMC installation directory
# -case		- Service Request Number
# -party	- PartyNumber of customer (Site-ID)
# -customer	- Company Name
# -contact	- Contact Name
# -email	- Contact Email Address
# -phone	- Contact Phone Number

SAVE_CMDLINE=$*
AUTOEXEC=1;
OPT_VAR=1;
while [ $# -gt 0 ] 
do
	SHFT=2
	case $1 in
		-h)		usage; exit 0;;
		?)		usage; exit 0;;
		-v)		echo Version ${VERSION}; exit 0;;
		-o)		MODULES=`echo $2 | sed 's/,/ /g'`;;
		-man)		man -M ${HOME}/man sysgrab.sh; exit 0;;
		-cleanup)	cleanup; exit 0;;
		-nodelete)	DELETE=OFF; SHFT=1;;
		-autoexec)	AUTOEXEC=0; SHFT=1;;
		-backup)	AUTOEXEC=0; CLARIFY_ID="sysGrab Backup"
				BACKUP=ON; SHFT=1;;
		-debug)		exec > ${TRACE} 2>&1; AUTOEXEC=0;
				set -x; DBG=0; SHFT=1;;
		-quiet)		exec > /dev/null 2>&1; AUTOEXEC=0;
				SHFT=1;;
		-lite)		HEAT=ON; export HEAT; SHFT=1;;
		-legal)	        OPT_VAR=0; SHFT=1;; 
		-EMCDir)	EMC_DIR=$2;;
		-OUTDir)	OUT_DIR=$2;;			# MG: ADD: GERS_480 - New command line option added
                -vxdmpdebug)    VXDMPDEBUG="Y"; export VXDMPDEBUG;SHFT=1;;
		-case)		CLARIFY_ID=$2; CC_ID=$2;;
		-party)		PARTY_NUMBER=$2;;
		-customer)	CUSTOMER_ID=$2;;
		-contact)	CONTACT_ID=$2;;
		-email)		EMAIL_ID=$2;;
		-phone)		CONTACTPHONE_ID=$2;;
		-clustname)	CLUSTNAME=$2; export CLUSTNAME;;
		-clariionIP)	CLARIION_IP="${CLARIION_IP} $2"; export CLARIION_IP;;
		-ip)		CLARIION_IP="${CLARIION_IP} $2"; export CLARIION_IP;;
		-noclariion)	NOCLARIION="TRUE"; export NOCLARIION;SHFT=1;;
		-symmid)	MODE="$2"; export MODE;;
		*)	    echo "Unknown command line option: ${1}";exit;;
	esac	
	shift ${SHFT}
done

#
# Read legal notice and then proceed
#

# SD:MOD: Depending on the variables set, it will work.
if [ ${OPT_VAR} -eq 1 -a ${AUTOEXEC} -eq 1 ]
then
	legal_notice
elif [ ${OPT_VAR} -eq 1 -a ${AUTOEXEC} -eq 0 ]
then
	legal_notice
elif [ ${OPT_VAR} -eq 0 -a ${AUTOEXEC} -eq 1 ]
then
	echo "Unknown command line option";
        exit;
fi 

#
# Create temporary directory for outputs 
#

if [ ! -d ${EMC_TMP} ]
then
	mkdir ${EMC_TMP}
fi

# MG: ADD: GERS_480 - Set default for OUT_DIR -------------START--------------------------------

#
# Set default for OUT_DIR, unless OUTDir was defined as 
# command line argument
#

if [ -z "${OUT_DIR}" ]
then
	OUT_DIR=${HOME}/outputs
fi
export OUT_DIR

# MG: ADD: GERS_480 - Set default for OUT_DIR -------------END----------------------------------

if [ ! -d ${OUT_DIR} ]
then
	mkdir ${OUT_DIR}
fi

#
# Set default for EMC_DIR, unless EMCDir was defined as 
# command line argument
#
if [ -z "${EMC_DIR}" ]
then
	EMC_DIR=/usr/sys
fi
export EMC_DIR

#
# Decide whether to provide interactive prompts
# Dependant on whether AUTOEXEC flag is set
#
if [ ${AUTOEXEC} -ne 0 ]
then
	interact

else
	if [ ! "${USER}" = "root" ]
	then
		# Check for UID
		USER_ID=`grep ${USER} /etc/passwd | cut -f3 -d:`

		if [ ${USER_ID} -ne 0 ]
		then
			echo "** WARNING **" >> ${RPT}
			echo "Not running as user root, or as user with real UID of 0" >> ${RPT}
		fi
	fi
	
	# Write user info to Log file
	confirmation
fi

#
# Normalize Clarify ID to 10 characters unless in Backup Mode
#

if [ "${BACKUP}" = "ON" ]
then
	CC_ID="Backup"
else
	CC_ID=`echo ${CC_ID} | awk -f ${AWK}/normalize_clarify.awk`

        #       Insure that CC_ID is numeric
	echo ${CC_ID} | grep '[^1234567890]' > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		printf "\nService Request ID must be numeric: ${CC_ID} \n" | tee -a ${RPT}
		exit 1
	fi
fi


#
# Create relevant symbolic link to temporary directory
#

if [ "${BACKUP}" = "ON" ]
then
	ln -s ${EMC_TMP} Backup
	SRC_DIR=Backup
else
	SRC_DIR=CC${CC_ID}_${HOSTNAME}_`date +%d%m%y%H%M`
	ln -s ${EMC_TMP} ${SRC_DIR}
fi

#
# Build up list of commands to be run based 
# on OS and optional modules supplied via -o param.
# This function also performs automated detection of limited SW
#

#AP:ADD:GERS_487:To check for VMware host.
vmware_support
#PA:S1:ADD:GERS_882:To check NCR Server
check_ncr_server
#PA:E1:ADD:GERS_882

module 

#
# Document modules and other command line options to log file
#

printf "\nGrabScript version: ${VERSION}" | tee -a ${RPT}
printf "\nCommand line options: ${SAVE_CMDLINE}" | tee -a ${RPT}
printf "\nModules to be processed: ${CMD_LIST}\n" | tee -a ${RPT}

if [ "${VXDMPDEBUG}" = "Y" ]
then
    printf "\nNOTICE: You have choose to run vxdmpdebug script. It will 
            cause a momentary stoppage of any vxvm configuration actions.  
            This should not harm any data, however it may cause some 
            configuration operations.  Any vxvm configuration changes should 
            be completed before running this script.\n" | tee -a ${RPT}
fi

#
# Create emtpy file in SCRIPT_TMP based on OS
# to automate parsing routines
#

touch ${EMC_TMP}/${OS}

#
# Run all the commands in the list to 
# perform data collection.
#

START_TIME="`date +%d/%m/%y` - `date +%H:%M:%S`"

for file in `echo ${CMD_LIST}`
do
	BASENAME=${file}
	export BASENAME

	# Write start time for each module
	TIME="`date +%d/%m/%y` - `date +%H:%M:%S`"
	printf "\n\nModule ${file} started at : ${TIME}" >> ${RPT}

	if [ -x ${SCRIPTS}/${file}.sh ]
	then
		# Check for sufficient space remaining
		fs_check

		# Write entry to ${ERR_RPT} for error diagnosis
		printf "\nRunning module - ${file}" >> ${ERR_RPT}

		if [ "${HEAT}" = "ON" ]
		then
			
			sh ${SCRIPTS}/lite/${file}.sh
		else
			sh ${SCRIPTS}/${file}.sh

		fi

	else
		printf "\nModule ${file} not found.  Skipping ...\n" | tee -a ${RPT}
	fi

done

END_TIME="`date +%d/%m/%y` - `date +%H:%M:%S`"

#
# Copy temporary files into Case Directory
# Tar files together
# Remove temporary files

if [ "${BACKUP}" = "ON" ]
then
	TAR_FILE=${HOSTNAME}_`date +%Y-%m-%d-%H.%M.%S`_${OS}_sysgrab_V${VERSION}__backup.tar
else
	if [ ${HEAT} = "ON" ]
	then
		TAR_FILE=${HOSTNAME}_`date +%Y-%m-%d-%H.%M.%S`_${OS}_sysgrab_V${VERSION}_lite_CC"${CC_ID}".tar
	else
		TAR_FILE=${HOSTNAME}_`date +%Y-%m-%d-%H.%M.%S`_${OS}_sysgrab_V${VERSION}_full_CC"${CC_ID}".tar
	fi
fi

# Write out time statistics and the name of the tar file to Log File 
# so we can identify file name in case changed by customer
# 
printf "\n\nData Collection Started at : ${START_TIME}" >> ${RPT}
printf "\n\nData Collection Finished at : ${END_TIME}" >> ${RPT}
printf "\n\nOutput Filename is : ${TAR_FILE}.${TAR_SUFFIX}\n" >> ${RPT}

if [ ${AUTOEXEC} -eq 1 ]
then
	cp ${HOME}/History ${HOME}/${SRC_DIR}
fi

#
# Copy customer.profile to tmp directory
#
cp ${HOME}/customer.profile ${EMC_TMP}/customer.profile

# 
# Copy legal notice to tmp directory
#
cp ${HOME}/EMC_LEGAL_NOTICE.txt ${EMC_TMP}/EMC_LEGAL_NOTICE.txt

# Generate Root Level indexes

printf "\nFinishing Data Collection, please wait... "

root_level_index

#
# Create tar file
#
printf "\n\nCreating and compressing Tar File ${TAR_FILE}"
tar chf ${OUT_DIR}/${TAR_FILE} ${SRC_DIR}/* & >/dev/null 2>&1
PID=$!
while [ `ps -p ${PID} | wc -l` -eq 2 ]
do
	sleep 1
	printf "."
done

# Compress tar file based on $COMPRESS

${COMPRESS} ${OUT_DIR}/${TAR_FILE} & > /dev/null 2>&1
PID=$!
while [ `ps -p ${PID} | wc -l` -eq 2 ]
do
	sleep 1
	printf "."
done

echo

#
# Completion and return of any paramters for initial calling program
#
if [ -z "${EXTERNAL}" ]
then
	echo

	echo "All outputs are located in the `basename ${OUT_DIR}` directory"
	echo "Output Filename is :"
	printf "\n"
	echo "${TAR_FILE}.${TAR_SUFFIX}"
	printf "\n"
	echo "Please submit this file to EMC for Analysis.  Thank you"

	echo
	cleanup
	
else
	dump_variables_and_exit 0
fi

exit ${RC}
