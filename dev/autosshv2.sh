#!/bin/sh

for p in $(cat /root/ansible/ipdata/dev.ip)
do

ip=$(echo "$p"|cut -f1 -d":")
passwd=$1

expect <<EOF
spawn scp /root/.ssh/id_rsa.pub root@$ip:/root/.ssh/authorized_keys
	expect {
	"assword:" { send "$passwd\n"; exp_continue; }
	"yes/no*" { send "yes\n"; exp_continue; }
	eof { exit; }
	}
EOF

done

exit 0
