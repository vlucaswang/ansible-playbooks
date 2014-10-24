#
# Script for handling Volume Logix
#
RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="Volume Logix"

RUNTIME=450

# check_dir	- Check for existance of temporary directory

if [ ! -f ${SCRIPTS}/tools.main ]
	then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

check_dir

# Specific handling routine for Volume Logix
# Checks for existance of either fpath or rofpath

CMD_EXIST=`which fpath 2>&1 | awk -f ${AWK}/check_exe.awk`
if [ ${CMD_EXIST} -eq 0 ]
then
	CMD_EXIST=`which rofpath 2>&1 | awk -f ${AWK}/check_exe.awk`

	if [ ${CMD_EXIST} -eq 0 ]
	then
		printf "\n\n${NAME} utilities cannot be found....continuing" | tee -a ${RPT}
		exit 0
	else
		FPATH=rofpath
	fi
else
	FPATH=fpath
fi

export FPATH

# Specific handling routine for Volume Logix.
# Multistep command for queries against multiple VCMDB devices

printf "\n\nPlease wait while we determine your Volume Logix Configuration " | tee -a ${RPT}

ARRAY=`${FPATH} lshostdev -q 2> /dev/null | awk 'BEGIN { ORS = "\n" } NF == 7 && $7 ~ /VCMDB/ { print $5 }' | sort -u`

SCRIPT_TMP_SAVE=${SCRIPT_TMP}
NAME_SAVE=${NAME}

for i in $ARRAY
do
	VCMDBDEVICE=`${FPATH} lshostdev | grep ${i} | awk '$7 ~ /VCMDB/ { print $1 }' | head -1`
	export VCMDBDEVICE

	SCRIPT_TMP=${SCRIPT_TMP_SAVE}/${i}
	NAME="${NAME_SAVE} Commands against Symmetrix ${i}"
	
	check_dir

	# List of commands to run

	printf "\n\nRunning ${NAME}\n" | tee -a ${RPT}

	run_single_command "${FPATH} lsdb"
	run_single_command "${FPATH} lshosts"
	run_single_command "${FPATH} lssymmdev"
	run_single_command "${FPATH} lshostdev"
	run_single_command "${FPATH} lshbawwn"

done

SCRIPT_TMP=${SCRIPT_TMP_SAVE}
NAME=${NAME_SAVE}

exit ${RC}
