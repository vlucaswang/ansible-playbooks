#
# Script for handling FibreZone
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="FibreZone"

RUNTIME=180

# Specific script variables
#
if [ -z "${FZ_ROOT}" ]
then
	FZ_ROOT="/usr/emc/FibreZone"

	PATH=${PATH}:${FZ_ROOT}/bin
	export PATH
else
	FZ_ROOT=${FZ_ROOT}
fi

export FZ_ROOT

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

copy_single_file "${FZ_ROOT}/log/fz_unix_install.log"
copy_single_file "${FZ_ROOT}/log/api"
copy_single_file "${FZ_ROOT}/log/cmdln"
copy_single_file "${FZ_ROOT}/log/libi"
copy_single_file "${FZ_ROOT}/db/members"
copy_single_file "${FZ_ROOT}/db/zones"
copy_single_file "${FZ_ROOT}/db/units"
copy_single_file "${FZ_ROOT}/db/configs"

# List of commands to run

printf "\n\nRunning ${NAME} Specific Commands\n" | tee -a ${RPT}

run_single_command "fzone zone -list"
run_single_command "fzone member -list"
run_single_command "fzone Zone_set -list"
run_single_command "fzone unit -list"
run_single_command "fzone interface -list"
run_single_command "fzone version"

exit ${RC}
