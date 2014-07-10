#!/bin/sh

# need php, expect

#
# Install ansible 2.6.1 for AIX 5.3
#

REMOTE_HOST="10.16.8.61"
REMOTE_USER="root"
REMOTE_PASS="123456"

#
# Step 1:  put ssh tools for aix 5.3
#
echo "Upload, please wait....."
cd package
ftp -n <<EOF
open $REMOTE_HOST
user $REMOTE_USER $REMOTE_PASS
bin
cd /tmp
mkdir ansible
cd ansible
prompt
mput *
mkdir aixpack
cd aixpack
lcd ../aixpack
mput *
close
bye
EOF
cd ..

#
#  Step 2: install ssh for AIX
# ( linux ansible server need expact for telnet )
# 

php -q telnet.php $REMOTE_HOST $REMOTE_USER $REMOTE_PASS
sleep 1

#
# Step 3: put SSH auth_public_key
#

expect <<EOF
spawn scp /root/.ssh/id_rsa.pub  $REMOTE_USER@$REMOTE_HOST:/.ssh/authorized_keys
expect {
	"password:" { send "$REMOTE_PASS\n"; exp_continue; }
	"yes/no*"   { send "yes\n"; exp_continue; }
	eof { exit ; }
}
EOF


#
# Step 4: install ansible runtime support soft packages
#
php -q rpm.php $REMOTE_HOST $REMOTE_USER $REMOTE_PASS


# step 5, test
echo "
[test]
$REMOTE_HOST
">hosts

ansible -i hosts all -m ping
