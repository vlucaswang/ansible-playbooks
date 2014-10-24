#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
# Script to print out the definition files

# Source tools.main
if [ ! -f $HOME/emcgrab.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. $HOME/emcgrab.main 
fi

module

if [ $# -eq 0 ]
then
	usage
	exit 0
else
	if [ $1 = "all" ]
		then
		DEFAULT_CMDS="$CMD_LIST"
	else
		DEFAULT_CMDS=`echo $1 | sed 's/,/ /g'`
	fi
fi

mkdir $EMC_TMP > /dev/null 2>&1

PRINT_RPT=$EMC_TMP/print.rpt

for PRINT in $DEFAULT_CMDS
do
	if [ $PRINT = "host" ]
	then
		PRINT=$OS
	fi

	#	Firstly check for existance of files
	if [ ! -f $SCRIPTS/$FILE_DIR/files.$PRINT ]
	then
		printf "\nNo Files defined for Module $PRINT\n" >> $PRINT_RPT
	else
		print_definitions files
	fi

	if [ ! -f $SCRIPTS/$CMD_DIR/commands.$PRINT ]
	then
		printf "\nNo Commands defined for Module $PRINT\n" >> $PRINT_RPT
	else
		print_definitions commands 
	fi
done

more $PRINT_RPT

rm -rf $EMC_TMP

exit ${RC}
