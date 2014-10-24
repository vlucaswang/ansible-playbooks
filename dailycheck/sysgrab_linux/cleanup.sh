#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2011 by EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
#
#############################################################
#
#	Clean up all files at completion of transmission
#	back to the EMCLink Collector.
#
#	Return codes
#	RC=0	Success
#	RC=1	failure
#	Others	Depending on rm return codes
#############################################################

#	Init return code
RC=0

#	Check if this is the grabscript root directory
if [ -x emcgrab.sh -a -f emcgrab.main -a -d tools ]
then
	printf "Deleting files\n"

#	This even deletes the current script
	rm -rf *

#	Use rm's return code for ours
	RC=$?
else
	printf "Not in grabscript root directory\n"
	RC=1
fi

exit $RC
