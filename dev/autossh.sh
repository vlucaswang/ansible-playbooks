#!/bin/bash

user=$1
pass=$2


for host in $(cat iplist)
do
expect -c "
spawn ssh-copy-id $1@$host
expect {
\"*yes/no*\" {send \"yes\r\"; exp_continue}
\"*password*\" {send \"$password\r\"; exp_continue}
\"*Password*\" {send \"$password\r\";}
}
"
done
