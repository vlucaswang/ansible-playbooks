#-------------------------------------------------------------------------------
# Copyright (C) by EMC Corporation, 2002
# All rights reserved.
#-------------------------------------------------------------------------------

BEGIN { err_code = 0 }
{
# 
# Perform quick sanity to ignore loopback and broadcast addresses
#
if ($1 ~ /127.0.0.1/ || $1 ~ /255.255.255.255/)
	{
	# Illegal adddress - reserved for loopback and broadcast	
	err_code=1
	exit
	}

if ($1 ~ /[a-zA-Z]/)
	{
	# Numerical values only
	err_code=3
	exit
	}

#
# Create an Array which we can use for testing correct number
# of fields.   This will trap use of hostnames.
#
array = split ( $1,value,"." )

if (array == 4) 

	{
	# Continuing process if 4 fields are detected based on '.'
	# seperator
	x=1
	while ( x <= array ) 

		{

		# Check to see whether any octets exceed maximum
		# permitted value of 255
	
		if (value[x] > 255) 
			{
			# An octet detected greater than 255		
			err_code=2
			exit
			}

		x++
		}
	}

else 

	{
	# Entry did not agree with standard 'dot' notation
	err_code=3
	}
}

END {print err_code} 

