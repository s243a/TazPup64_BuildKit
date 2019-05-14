#!/bin/sh
#
# /etc/init.d/local.sh: Local startup commands
#
# All commands here will be executed at boot time.
#

if [ -f /etc/rc.d/rc.local ] && [ -x /etc/rc.d/rc.local ] ; then
/etc/rc.d/rc.local 
fi
