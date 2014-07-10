#!/bin/sh

#while read line
#do
for p in $(cat /root/ansible/ipdata/prod.ip)
do

IP=$(echo "$p"|cut -f1 -d":")
#PASSWD=$(cut -f2 -d":")
PASSWD=$1

expect -c "
spawn ssh-copy-id root@$IP
	expect {
		\"*yes/no*\" {send \"yes\r\"; exp_continue}
		\"*assword*\" {send \"$PASSWD\r\";}
	}
"

done
#done </root/iplist

#exit 0
