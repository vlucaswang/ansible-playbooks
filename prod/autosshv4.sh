#!/bin/sh

PASSWD=$1

for IP in $(cat /root/ansible/ipdata/prod.ip)
do
sshpass -p '$PASSWD' ssh-copy-id root@$IP
done
