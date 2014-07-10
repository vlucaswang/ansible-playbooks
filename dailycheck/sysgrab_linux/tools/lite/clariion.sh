#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script for Clariion and Navicli
#
#----------------------------------------------------------------------------------------
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Clariion"

RUNTIME=300

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	printf "\n${BASENAME} - Unable to source file tools.main....exiting\n"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi


check_dir

# Function : check_ip
# Description	: Validate $1 to see if it conforms to a normal IP address.
#		: Reserved, malformed and out-of-range generate errors

check_ip()
{

IP_CHECK=`echo ${1} | awk -f ${AWK}/check_ip.awk`
if [ ${IP_CHECK} -eq 0 ]
then
	CLARIION_IP="${CLARIION_IP} ${1}"
	export CLARIION_IP

elif [ ${IP_CHECK} -eq 1 ]
then
	echo "This address '${1}' is reserved"

elif [ ${IP_CHECK} -eq 2 ]
then
	echo "One octet in '${1}' is greater than 255"

elif [ ${IP_CHECK} -eq 3 ]
then
	echo "'${1}' does not match the standard IP 'dot' notation"
fi		

}
	
#
# Copy Clariion Specific Files
#

printf "\n\nCollecting Configuration / Log Files for ${NAME}\n" | tee -a ${RPT}

copy_single_file "/etc/Navisphere/agent.config"
copy_single_file "/opt/Navisphere/bin/agent.config" "keep_dir_path"
copy_single_file "/etc/log/agent.log"
copy_single_file "/etc/rcS.d/agent"
copy_single_file "/etc/log/HostIdFile.txt"
copy_single_file "/usr/ssm/etc/log/HostIdFile.txt"
copy_single_file "/var/log/HostIdFile.txt"

printf "\n" | tee -a ${RPT}

#
# Run Commands against the Array
#

NAV_DIR=/opt/Navisphere/bin
PATH=${PATH}:${NAV_DIR}
SCRIPT_TMP_SAVE=${SCRIPT_TMP}
NAME_SAVE=${NAME}
export PATH
#
#PA:GERS_759 - To detect navicli or naviseccli
#
MAN_CMD=navicli
CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
if [ ${CMD_EXIST} -eq 0 ]
then
	MAN_CMD=naviseccli
	NAVISEC_CMD_EXIST=`which ${MAN_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
	if [ ${NAVISEC_CMD_EXIST} -eq 1 ]
        then
		MAN_CMD=naviseccli
		NAVISEC_CMD_EXIST=1
	fi
else
	MAN_CMD=navicli	
	CMD_EXIST=1
fi		
#PA:ADD:E1:GERS_759 - To detect navicli or naviseccli	
if [ ${CMD_EXIST} -eq 0 ] && [ ${NAVISEC_CMD_EXIST} -eq 0 ]
then
	echo ${CMD_EXIST}
        echo ${NAVISEC_CMD_EXIST}
        printf "\nNAVICLI & NAVISECCLI are not found....continuing" | tee -a ${RPT}

elif [ "${NOCLARIION}" = "TRUE" ]
then
	printf "\n\nNo Clariion Collection requested... \n" | tee -a ${RPT}
else

	#
	# If running interactively, and Clariion IP addresses
	# not defined on command line, then prompt for verification
	#

	if [ ${INQ_MODE} -eq 0 ]
	then

		# Use inq -clar_wwn and parse output 
		# for IP addresses

		printf "\nTrying to detect your Clariion SP IP addresses..."

		IP_DETECT=`${BIN}/${INQ} -no_dots -clar_wwn | awk 'NF == 6 { print $4 }' | sort -u`
		# Validate the IP address.  Any adddress which does not 
		# conform to standard 'dot' notation will be ignored.

		for i in ${IP_DETECT}
		do
			check_ip ${i}

		done

		printf "\n" | tee -a ${RPT}

		# If running interactive, and no IP addresses detected
		# or pass validation check, prompt customer

		if [ -z "${CLARIION_IP}" -a ${AUTOEXEC} -eq 1 ]
		then

			# We need to confirm the type of Clariion Array

			printf "\nIs this either an FC4700 / CX Series Array (y/n) ? "
			read ANSWER

			if [ ${ANSWER} = "Y" -o ${ANSWER} = "y" ]
			then

				while true
				do
					printf "Please enter the IP Addresses (one per line) : "
					read IP
					if [ -n "${IP}" ]
					then
						check_ip ${IP}
					else
						break
					fi
				done
				
			else
				break
				
			fi
		fi

	fi

	#
	# If CLARIIONIP is set, either from command line or from
	# routine above, then run commands, otherwise default to
	# non FC4700 / CX arrays.
	#

	if [ -n "${CLARIION_IP}" ]
	then

		HOSTIP=`echo ${CLARIION_IP} | sed 's/,/ /g'`

		# Strip any duplicate IP addresses.  This is feasible
		# due to entries defined on the command line, and 
		# those automatically detected.

		IP_TMP=""
		for a in ${HOSTIP}
		do
			DUPLICATE=0
			
			for b in ${IP_TMP}
			do
				if [ "${a}" = "${b}" ]
				then
					DUPLICATE=1
				fi
			done

			if [ ${DUPLICATE} -eq 1 ]
			then
				echo "Removing Duplicate IP Address ${a}" >> ${RPT}
			else
				IP_TMP="${IP_TMP} ${a}"
			fi
		done

		HOSTIP=${IP_TMP}
		
		# End of duplicate IP handling.

		echo "List of IP Addresses : ${HOSTIP}" >> ${RPT}

		for i in ${HOSTIP}
		do
            	if [ ${MAN_CMD} = "navicli" ]
		then
				SCRIPT_TMP=${SCRIPT_TMP}/${i}
				check_dir
	
				printf "\nRunning ${MAN_CMD} against ${NAME_SAVE} SP : ${i}\n" | tee -a ${RPT}
	
				# Check to see whether SP Interface is responding
	
				${MAN_CMD} -h ${i} getagent > /dev/null 2>&1
				if [ $? -eq 0 ]
				then
               				run_single_command "${MAN_CMD} -h ${i} getagent" "${MAN_CMD} getagent"
					run_single_command "${MAN_CMD} -h ${i} getsptime -spa" "${MAN_CMD} getsptime -spa"	
					run_single_command "${MAN_CMD} -h ${i} getsptime -spb" "${MAN_CMD} getsptime -spb"
					run_single_command "${MAN_CMD} -h ${i} getlog" "${MAN_CMD} getlog"
					run_single_command "${MAN_CMD} -h ${i} getall" "${MAN_CMD} getall"
					run_single_command "${MAN_CMD} -h ${i} systemtype" "${MAN_CMD} systemtype"
					run_single_command "${MAN_CMD} -h ${i} getdisk" "${MAN_CMD} getdisk"
					run_single_command "${MAN_CMD} -h ${i} getlun" "${MAN_CMD} getlun"
					run_single_command "${MAN_CMD} -h ${i} getlun -ismetalun" "${MAN_CMD} getlun -ismetalun"
                                        run_single_command "${MAN_CMD} -h ${i} getlun -rg -type -default -owner -crus -capacity" "${MAN_CMD} getlun -rg -type -default -owner -crus -capacity"
					run_single_command "${MAN_CMD} lunmapinfo ${i}" "${MAN_CMD} lunmapinfo"
					run_single_command "${MAN_CMD} -h ${i} getcrus" "${MAN_CMD} getcrus"
					run_single_command "${MAN_CMD} -h ${i} port -list -all" "${MAN_CMD} port -list -all"	
					run_single_command "${MAN_CMD} -h ${i} storagegroup -list" "${MAN_CMD} storagegroup -list"	
					run_single_command "${MAN_CMD} -h ${i} failovermode" "${MAN_CMD} failovermode"
					run_single_command "${MAN_CMD} -h ${i} arraycommpath" "${MAN_CMD} arraycommpath"	
					run_single_command "${MAN_CMD} -h ${i} spportspeed -get" "${MAN_CMD} spportspeed -get"
	
					printf "\n" | tee -a ${RPT}
				else

					echo "SP Interface at '${i}' is not responding....skipping this SP" | tee -a ${RPT}
				fi
	
				SCRIPT_TMP=${SCRIPT_TMP_SAVE}
				NAME=${NAME_SAVE}
		elif [ ${MAN_CMD} = "naviseccli" -a ${AUTOEXEC} -eq 1 ]
		then
				SCRIPT_TMP=${SCRIPT_TMP}/${i}
				check_dir
				printf "\nRunning ${MAN_CMD} against ${NAME_SAVE} SP : ${i}\n" | tee -a ${RPT}								
				while [ -z "$NAVISEC_USER" ] || [ -z "$NAVISEC_PASS" ] || [ -z "$NAVISEC_SCOPE" ]
				do
					printf "\nPlease enter the USERNAME for ${i} : "
					read NAVISEC_USER
					printf "\nPlease enter the PASSWORD for ${i} : "
					read NAVISEC_PASS
					printf "\nPlease enter the SCOPE for ${i} : "
					read NAVISEC_SCOPE
					if [ ! -n "$NAVISEC_USER" ] || [ ! -n "$NAVISEC_PASS" ] || [ ! -n "$NAVISEC_SCOPE" ]
					then
						printf "\nThe username ,  password or scope cannot be blank"
						printf "\nPlease Enter it once again.......\n"
					fi
				done

				${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getagent > /dev/null 2>&1
				if [ $? -eq 0 ]
				then			
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getagent" "${MAN_CMD} getagent"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getsptime -spa" "${MAN_CMD} getsptime -spa"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getsptime -spb" "${MAN_CMD} getsptime -spb"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getlog" "${MAN_CMD} getlog"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getall" "${MAN_CMD} getall"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} systemtype" "${MAN_CMD} systemtype"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getdisk" "${MAN_CMD} getdisk"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getlun" "${MAN_CMD} getlun"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getlun -ismetalun" "${MAN_CMD} getlun -ismetalun"
                                        run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getlun -rg -type -default -owner -crus -capacity" "${MAN_CMD} getlun -rg -type -default -owner -crus -capacity"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} getcrus" "${MAN_CMD} getcrus"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} port -list -all" "${MAN_CMD} port -list -all"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} storagegroup -list" "${MAN_CMD} storagegroup -list"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} failovermode" "${MAN_CMD} failovermode"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} arraycommpath" "${MAN_CMD} arraycommpath"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} spportspeed -get" "${MAN_CMD} spportspeed -get"
					run_single_command "${MAN_CMD} -h ${i} -user ${NAVISEC_USER} -password ${NAVISEC_PASS} -scope ${NAVISEC_SCOPE} metalun -list" "${MAN_CMD} metalun -list"
					printf "\n" | tee -a ${RPT}
				else
				        echo "SP Interface at '${i}' is not responding....skipping this SP" | tee -a ${RPT}
				fi

				SCRIPT_TMP=${SCRIPT_TMP_SAVE}
				NAME=${NAME_SAVE}
				NAVISEC_USER=""
				NAVISEC_PASS=""
				NAVISEC_SCOPE=""		
                #Run following commands when script run in non-iterative mode and naviseccli security file has been created.
                elif [ ${MAN_CMD} = "naviseccli" -a ${AUTOEXEC} -eq 0 ]
                then
				printf "\nEMCGrab is running under auto executable mode."
				printf "\nIt will run naviseccli commands assuming that security file (using -AddUserSecurity) has already been created."
				
				${MAN_CMD} -h ${i} getagent > /dev/null 2>&1
				if [ $? -eq 0 ]
				then			
					run_single_command "${MAN_CMD} -h ${i} getagent" "${MAN_CMD} getagent"
					run_single_command "${MAN_CMD} -h ${i} getsptime -spa" "${MAN_CMD} getsptime -spa"
					run_single_command "${MAN_CMD} -h ${i} getsptime -spb" "${MAN_CMD} getsptime -spb"
					run_single_command "${MAN_CMD} -h ${i} getlog" "${MAN_CMD} getlog"
					run_single_command "${MAN_CMD} -h ${i} getall" "${MAN_CMD} getall"
					run_single_command "${MAN_CMD} -h ${i} systemtype" "${MAN_CMD} systemtype"
					run_single_command "${MAN_CMD} -h ${i} getdisk" "${MAN_CMD} getdisk"
					run_single_command "${MAN_CMD} -h ${i} getlun" "${MAN_CMD} getlun"
					run_single_command "${MAN_CMD} -h ${i} getlun -ismetalun" "${MAN_CMD} getlun -ismetalun"
                                        run_single_command "${MAN_CMD} -h ${i} getlun -rg -type -default -owner -crus -capacity" "${MAN_CMD} getlun -rg -type -default -owner -crus -capacity"
					run_single_command "${MAN_CMD} -h ${i} getcrus" "${MAN_CMD} getcrus"
					run_single_command "${MAN_CMD} -h ${i} port -list -all" "${MAN_CMD} port -list -all"
					run_single_command "${MAN_CMD} -h ${i} storagegroup -list" "${MAN_CMD} storagegroup -list"
					run_single_command "${MAN_CMD} -h ${i} failovermode" "${MAN_CMD} failovermode"
					run_single_command "${MAN_CMD} -h ${i} arraycommpath" "${MAN_CMD} arraycommpath"
					run_single_command "${MAN_CMD} -h ${i} spportspeed -get" "${MAN_CMD} spportspeed -get"
					run_single_command "${MAN_CMD} -h ${i} metalun -list" "${MAN_CMD} metalun -list"
					printf "\n" | tee -a ${RPT}
				else
				        printf "\n\nSecurity file not found or SP Interface at '${i}' is not responding....skipping this SP" | tee -a ${RPT}
				fi                
                fi
		done
	else
		printf "\nNo IP addresses defined" | tee -a ${RPT}

	fi
	
        #AP: This will collect agent information from host side
        run_single_command "navicli getagent"
fi


exit ${RC}

