#!/bin/sh

REMOTE_HOST="10.16.8.61"
ROMOTE_USER="root"
REMOTE_PASS="123456"

expect <<EOF
spawn scp /root/.ssh/id_rsa.pub  $REMOTE_USER@$REMOTE_HOST:/.ssh/authorized_keys
expect {
	"password:" { send "$REMOTE_PASS\n"; exp_continue; }
	"yes/no*"   { send "yes\n"; exp_continue; }
	eof { exit ; }
}
EOF

