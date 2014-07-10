#!/bin/sh

PASSWD=123456

for IP in $(cat /root/iplist)
do
sshpass -p '$PASSWD' ssh-copy-id root@$IP
done
