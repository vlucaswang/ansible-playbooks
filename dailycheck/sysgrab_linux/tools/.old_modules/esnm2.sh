#
# Script for handling ESN Manager v2.0
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="ESN Manager"

RUNTIME=60

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

copy_single_file "/usr/emc/ESN_Manager/logs/esnm.log"
copy_single_file "/usr/emc/ESN_Manager/logs/messages"

INSTALL=/usr/emc

if [ -d "${INSTALL}/esnapi" ]
then
	cd ${INSTALL}

	tar_dir "esnapi/*/data" "esnapi_logs.tar"
fi

exit $RC
