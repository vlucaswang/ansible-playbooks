#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Solutions Enabler"
RUN=OFF

DATE_STAMP=`date +%d/%m/%Y `
DATE_CALC=` echo ${DATE_STAMP} 14 | awk -f ${AWK}/date_calc.awk`
PATH=${PATH}:/usr/symcli/bin:/usr/symcli/storbin
export PATH

RUNTIME=540

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

SCRIPT_TMP_SAVE=${SCRIPT_TMP}
NAME_SAVE=${NAME}

get_symm_data()
{
    SYMCLI_SID=${1}
    export SYMCLI_SID

    SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${1}
    NAME="${NAME_SAVE} Commands against Symmetrix ${1}"

    check_dir

    # List of commands to run.  These are targetted against
    # a specific Symm, as defined by SYMCLI_SID

    printf "\n\nRunning ${NAME}\n" | tee -a ${RPT}

    run_single_command "symcfg verify"
    run_single_command "symcfg -dir all -v list"
    run_single_command "symcfg -connections list"
    run_single_command "symcfg -app -v list"
    run_single_command "symcfg -fa all -port list"
    run_single_command "symcfg -sa all -port list"
    run_single_command "symcfg -ra all -port list"
    run_single_command "symcfg list -lock"
    run_single_command "symcfg list -lockn all"
    run_single_command "sympd list"
    run_single_command "sympd list -vcm"
    run_single_command "symdev list"
    run_single_command "symdev -v list"
    run_single_command "symdev -rdfa list"
    run_single_command "symdev -rdfa -v list"
    run_single_command "symbcv list"
    run_single_command "symbcv -v list"
    run_single_command "symrdf list"
    run_single_command "symrdf -v list"
    run_single_command "symrdf -rdfa list"
    run_single_command "symrdf -rdfa -v list"
    run_single_command "symsnap list"
    run_single_command "symsnap list -savedevs"
    run_single_command "symclone list"
    run_single_command "symaudit show"
    run_single_command "symaudit -start_date ${DATE_CALC} list"
    run_single_command "symaudit -v -start_date ${DATE_CALC} list"
    run_single_command "symevent list"
    run_single_command "symmask list logins"
    run_single_command "symmaskdb list database"
    run_single_command "symmaskdb -v list database"
    run_single_command "symmaskdb -f ${SCRIPT_TMP}/symmaskdb_backup.bin backup -noprompt" "symmaskdb_backup"

    #PA:ADD:S1:GERS_586 - To add symdev list -resv command     
    run_single_command "symdev list -resv"

    if [ -n "${HBA}" ]
    then
	for i in ${HBA}
	do
 	  run_single_command "symmaskdb list devs -wwn ${i}"
	done
    fi

    #SD:GERS_1046 : To add the command symmaskdb list devs -wwn for all the identifiers.
    IDENTIFIERS=`symmask list logins | awk '/^[1-9]/ {print $1}' | sort -nr | uniq`  
    OUTPUT="symmaskdb_list_devs_-wwn_all"
    add_text
    echo ${IDENTIFIERS} | xargs -n1 symmaskdb list devs -wwn >> ${SCRIPT_TMP}/${OUTPUT}.txt 2>> ${ERR_RPT} &

    #SD:GERS_1033 : Adding commands for Solutions Enabler 7.
    SYMCLI_VER=`symcli | awk '/\(SYMCLI\) Version/ { print substr($7,0,2) }'`
    if [ -n "$SYMCLI_VER" ]
    then 
    	echo $SYMCLI_VER | grep '7' > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
    	    printf "\n\nRunning Soultions Enabler 7 Specific Commands\n" | tee -a ${RPT}
            	
            run_single_command "symaccess -sid ${SYMCLI_SID} list logins"
            INIT_GROUP=`symaccess list -sid ${SYMCLI_SID} | awk '$4 ~ /Initiator/ { print $1 }'`
    	    OUTPUT="symaccess_show_-type_init_all"
    	    add_text
    	    if [ -n "${INIT_GROUP}" ]
    	    then
    		for ARG in ${INIT_GROUP}
    		do
    		    symaccess show ${ARG} -type init -detail -sid ${SYMCLI_SID} >> ${SCRIPT_TMP}/${OUTPUT}.txt 2>> ${ERR_RPT} & 
    		done
    	    fi
    	    SYMACCESS_DATE=`date +%B.%d.%Y`
    	    SYMACCESS_DB="${SYMCLI_SID}_${SYMACCESS_DATE}.aclx"
    	    run_single_command "symaccess -sid ${SYMCLI_SID} -f ${SCRIPT_TMP}/${SYMACCESS_DB} backup -noprompt" "symaccess_backup"
    	    MASK_VIEW_NAME=`symaccess -sid ${SYMCLI_SID} list view -v | grep "Masking View Name" | awk '{ print $5 }'`
    	    if [ -n "${MASK_VIEW_NAME}" ]
    	    then
    		for ARG in ${MASK_VIEW_NAME}
    		do
        	    run_single_command "symaccess show view ${ARG} -sid ${SYMCLI_SID}"
      		done
    	    fi
        fi
    fi
}


# List of files to copy

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/var/symapi/db/symapi_db.bin"
copy_single_file "/var/symapi/config/[a-z]*"

echo >> ${RPT}

# Specific handling routine for Solutions Enabler
# Check for existance of gatekeeper, before running commands
# Assumption that syminq is available, if Solutions Enabler installed

MAN_CMD=syminq
CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`

if [ ${CMD_EXIST} -eq 0 ]
then
	printf "\nUnable to find syminq....continuing" | tee -a ${RPT}
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
                #PA:GERS_818:Changed GK from 4800 to 9600
                #
		GKLIST=`cat ${SCRIPT_TMP}/${MAN_CMD}.txt | awk '$2 ~ /GK/ && $7 <=9600 { print $1 }' | wc -l`
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

	run_single_command "symcli -def"
	run_single_command "symdg list"
	run_single_command "symdg -v list"
	run_single_command "symcg list"
	run_single_command "symcfg list"
	run_single_command "symcfg -v list"
	run_single_command "symcfg -db"
	run_single_command "symcfg -semaphores list"
	run_single_command "syminq hba -fibre"
	run_single_command "syminq hba -scsi"
	run_single_command "symhost show -config"
	run_single_command "stordaemon list"
	run_single_command "stordaemon -v list"

        # SD:GERS_1109 : removed command 'symmask list hba' and added equivalent command 'syminq hba'
        run_single_command "syminq hba"

	if [ `which syminq 2>&1 | awk -f ${AWK}/check_exe.awk` -eq 1 ]
	then
	  	HBA="`syminq hba 2> /dev/null | awk '/Port WWN/ { print $4 }' | sort -n | uniq`" 
  	fi

 	SYMCFG_LIST=`symcfg list | awk 'NF == 7 { print $1 }' | grep [0-9]` 	
	export SYMCFG_LIST

  	if [ -z "${MODE}" ]
  	then
		for i in ${SYMCFG_LIST}
	  	do
	             get_symm_data "${i}"
		done  	     

        elif [ "$MODE" = "prompt" -o "$MODE" = "PROMPT" ]  	
	then
  		for i in ${SYMCFG_LIST}
		do
		     printf "\n\nCollect data for Symmetrix ${i} (y/n) ? "
 		     read ANSWER
                     if [ ${ANSWER} = "Y" -o ${ANSWER} = "y" ]
		     then
                       SYM_LIST="${SYM_LIST} ${i}"
			export SYM_LIST
		     fi 		     
		done
  		for i in ${SYM_LIST}
	  	do
	             get_symm_data "${i}"
		done

        elif [ "${MODE}" = "bypass" -o "${MODE}" = "BYPASS" ]
	then
		printf "\n\nSymmetrix data collection by serial number bypassed\n" | tee  -a ${RPT}
        fi
	

	# Specific handling for listing of any configured device groups
	# based on existance of symdg list, created from running command 
	# "symdg list"

	# Listing device groups requires a gatekeeper so only included 
	# if commands are run.

	# Since the introduction of 5.3, symdg list / symdg -v list will 
	# only report on device groups configured against the Symm 
	# referenced by SYMCLI_SID

	unset SYMCLI_SID

	DG=`symdg -v list 2>> ${ERR_RPT} | grep "Group Name:" | awk 'BEGIN {FS = ":" } { print $2 }'`

	if [ -n "${DG}" ]
	then
		printf "\n\nListing Configured Device Groups\n" | tee -a ${RPT}

		for i in ${DG}
		do
			SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}
			
			check_dir

			run_single_command "symdg show ${i}" 

			DG_TYPE=`symdg show ${i} 2>> ${ERR_RPT} | grep "Group Type" | awk '{ print $4 " " $5 }'`

			if [ `echo ${DG_TYPE} | awk '{ print NF }'` -eq 2 ]
			then
				run_single_command "symrdf -g ${i} query" 
				run_single_command "symrdf -g ${i} -rdfa query"
			
			elif [ ${DG_TYPE} = "REGULAR" ]
			then
				run_single_command "symmir -g ${i} query"
			
			elif [ ${DG_TYPE} = "RDF1" -o ${DG_TYPE} = "RDF2" ]
			then
				run_single_command "symrdf -g ${i} query"
			
			fi

			# Copy the symreplicate logs for the device group
			# If the copy succeeds, ie log file is present, run
			# symreplicate against the device group

			copy_single_file "/var/symapi/log/symreplicate_dg_${i}.log"

			if [ $? -eq 0 ]
			then
				run_single_command "symreplicate -g ${i} show -all2"
			fi	
		done
	fi

	unset SYMCLI_SID

	CG=`symcg -v list 2>> ${ERR_RPT} | grep "Group Name:" | awk 'BEGIN { FS = ":" } { print $2 }'`


	if [ -n "${CG}" ]
	then
		printf "\n\nListing Configured Consistency Groups\n" | tee -a ${RPT}

		for i in ${CG}
		do
			SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}
			
			check_dir

			run_single_command "symcg show ${i}" 

		done
	fi

fi

# Restore variables to normal in case further processing desired

SCRIPT_TMP=${SCRIPT_TMP_SAVE}
NAME=${NAME_SAVE}

#
#	Specific handling for daemon log files under SE 5.1
#

if [ -d /usr/symcli/daemons ]
then
	printf "\n\nCopying log files for all installed Daemons" | tee -a ${RPT}

	for i in `ls /usr/symcli/daemons`
	do
		cd /var/symapi/log && FILE_LIST=`find . -name ${i}\* -mtime -14 -print` 
		tar_files "${FILE_LIST}" "daemonlogs.tar" 
	done

else
	printf "\n\nNo Installed daemons detected" >> ${RPT}
fi

#
# 	Specific handling to collect last 14 days worth of symapi logs
#

if [ -d /var/symapi/log ]
then
	printf "\n\nCollecting SYMAPI logs modified in the last 14 days" | tee -a ${RPT}

	cd /var/symapi/log && FILE_LIST=`find . -name symapi\*log -mtime -14 -print`

	if [ -n "${FILE_LIST}" ]
	then 
		tar_files "${FILE_LIST}" "symapilogs.tar"
	else
		printf "\n\nNo files found modified in the past 14 days" | tee -a ${RPT}
	fi
else
	printf "\n\nSYMAPI Log Directory Not Found" >> ${RPT}
fi

echo | tee -a ${RPT}

exit ${RC}
