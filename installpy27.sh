#!/bin/sh

for i in `cat $1`
do
ssh root@$i "\
rpm -Uvh http://10.128.128.103/testrepo/4/RedHat/RPMS/glibc-kernheaders-2.4-9.1.103.EL.i386.rpm;\
rpm -Uvh http://10.128.128.103/testrepo/4/RedHat/RPMS/glibc-headers-2.3.4-2.43.i386.rpm;\
rpm -Uvh http://10.128.128.103/testrepo/4/RedHat/RPMS/glibc-devel-2.3.4-2.43.i386.rpm;\
rpm -Uvh http://10.128.128.103/testrepo/4/RedHat/RPMS/gcc-3.4.6-11.i386.rpm;\
rpm -Uvh http://10.128.128.103/testrepo/4/RedHat/RPMS/libstdc++-devel-3.4.6-11.i386.rpm;\
rpm -Uvh http://10.128.128.103/testrepo/4/RedHat/RPMS/gcc-c++-3.4.6-11.i386.rpm;\
tar zxf Python-2.7.6.tgz;\
cd Python-2.7.6;
./configure --prefix=/usr/local/;
make && make altinstall"
done

exit 0
