#!/bin/sh

#while read line
#do
for p in $(cat $1)
do

ip=$(echo "$p"|cut -f1 -d":")
#passwd=$(cut -f2 -d":")
passwd=$2

expect <<EOF
spawn scp /root/.ssh/id_rsa.pub root@$ip:/root/.ssh/authorized_keys
	expect {
	"assword:" { send "$passwd\n"; exp_continue; }
	"yes/no*"   { send "yes\n"; exp_continue; }
	eof { exit ; }
	}
EOF

done
#done </root/iplist

exit 0
