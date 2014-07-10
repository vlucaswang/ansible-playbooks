#!/usr/bin/awk -f
#-------------------------------------------------------------------------------
# Copyright (C) by EMC Corporation, 2002
# All rights reserved.
#-------------------------------------------------------------------------------

# Given an input field, convert to 10 characters

{
	PAD = "0000000000";
	MAX = length(PAD);

	clarifyId = PAD $1;
	len = length(clarifyId);

	#	return last MAX characters
	ans = substr(clarifyId, len-MAX+1);
	print ans;
}
