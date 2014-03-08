#-------------------------------------------------------------------------------
# Copyright (C) by EMC Corporation, 2002
# All rights reserved.
#-------------------------------------------------------------------------------
#
# To take the current date and substract X days
# The date input is required as dd/mm/yy
# The output is returned as mm/dd/yyyy

BEGIN {
listmonths="January,February,March,April,May,June,July,August,"
listmonths=listmonths "September,October,November,December"
array1 = split (listmonths,calendar,"," )
}

{
curr_date = $1
minus_days = $2
value = split ( curr_date,date,"/" )

# Set date variables based on array

day = date[1]
month = date[2]
year = date[3]

# Set variables depending on how many days in month
# Used for index arguments

months_30 = "April June September November"
months_31 = "January March May July August October December"

days_remaining = minus_days - date[1]
day = date[1] - minus_days
days_in_month=1024

while (days_remaining >= 0)
{

if (day <= 0)

	{ 

	if (days_remaining >= days_in_month)
		{
		month = month - 1
		}

	else
		{
		month = month - 1
		}

	# Deduct one month from current value
	# If resulting integer is 0, then have to roll back year by 1

	if (month <= 0)

		{
		month = 12
		year = year - 1
		}
	else
		{
		year = year
		}


	name=calendar[month]

	a = index (months_30,name)

	if (a == 0)
		{ 
		b = index (months_31,name)

		if (b == 0)
			{
			# This is where we check for February
			# There may be an easier way to determine whether round
			# integer or not during division
			# This will not handle centuries, but the next one is 
			# 2100 - doubt this will be around then.

			c = (date[3] / 4)
			d = int(date[3] / 4)
			if (c != d)
				{
				days_in_month=28
				}
			else
				{
				days_in_month=29
				}
			}
		else

			{
			days_in_month=31
			}
		}
	else

		{
		days_in_month=30
		}

	# Set variable day to be days_in_month less the remainder of original calculation
	# A plus is used, being that day will be negative at this point in time.
	
	day = days_in_month + day

	}

else
	{
	month = month
	year = year
	}
	days_remaining = days_remaining - days_in_month

}
}

END { print month"/"day"/"year }


