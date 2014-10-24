#!/bin/sh

while read line; do
  scp ntp.conf root@$line:/etc/ntp.conf
#  ssh -n root@$line service ntpd start
  ssh -n root@$line service ntp start
#done < rhel4.ip
done < suse10.ip

exit 0
