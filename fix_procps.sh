#!/bin/sh
#
#Build TazPuppy either online or local

curdir=`pwd`
prefix="/64"
#Somd utilities in procps link to missing library libproc-3.2.8.so
while read -r line; do #https://unix.stackexchange.com/questions/85060/getting-relative-links-between-two-paths
  #https://stackoverflow.com/questions/9293887/reading-a-delimited-string-into-an-array-in-bash
  #https://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_10_02.html
  arr=($line)
  target_f=$curdir/slitaz-rootfs$prefix${arr[0]}
  source_f=${arr[1]}
  if [ -f $target_f ]; then
    
    fname=`bname $target_f`
    target_d=`dirname $target_f`
    mv $target_f $target_d/$fname-old
    cd $target_d
    pwd
    ln -s source_f fname
  fi
done <<EOM
/sbin/sysctl ../bin/busybox
/bin/ps busybox
/bin/kill busybox
/usr/bin/w ../bin/busybox
/usr/bin/pmap ../bin/busybox
/usr/bin/free ../bin/busybox
/usr/bin/uptime ../bin/busybox
/usr/bin/pkill ../bin/busybox
/usr/bin/pgrep ../bin/busybox
/usr/bin/top ../bin/busybox
/usr/bin/watch ../bin/busybox
EOM
