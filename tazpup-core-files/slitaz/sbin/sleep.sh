#!/bin/sh
# suspend.sh 28sep09 by shinobar
# 12feb10 pass poweroff
# 23apr12 fix was not suspend from acpi_poweroff.sh
#20140526 shinobar: avoid multiple run
# Modified by mistfire for TazPuppy

if [ "`whoami`" != "root" ]; then
exec sudo -A ${0} ${@} #110505
exit
fi

if [ ! -d /proc/acpi ] && [ ! -d /proc/apm ]; then
/usr/lib/gtkdialog/box_ok "Notice" error "acpi is not available on this computer"
exit 
fi

#avoid multiple run
LOCKFILE=/tmp/acpi_suspend-flg
if [ -f "$LOCKFILE" ]; then
  PID=$(cat "$LOCKFILE")
  ps| grep "^[ ]*$PID " && exit
fi
echo -n $$ > "$LOCKFILE"
sync
[ "$(cat "$LOCKFILE")" = $$ ] || exit 0 

# do not suspend at shutdown proccess
#111129 added suspend to acpi_poweroff.sh
PS=$(ps)
[ ! -f /tmp/suspend ] && echo "$PS"| grep -qE 'sh[ ].*poweroff' && rm -f "$LOCKFILE" && exit 0
rm -f /tmp/suspend

# do not suspend if usb media mounted
USBS=$(probedisk2|grep '|usb' | cut -d'|' -f1 )
for USB in $USBS
do
	mount | grep -q "^$USB" && rm -f "$LOCKFILE" && exit 0
done

# process before suspend
# sync for non-usb drives
sync
rmmod uhci_hcd
rmmod ehci_hcd
rmmod xhci_hcd
rmmod ohci_hcd

#suspend
echo -n mem > /sys/power/state

# process at recovery from suspend
#restartwm
modprobe uhci_hcd
modprobe ehci_hcd
modprobe xhci_hcd
modprobe ohci_hcd

#/etc/rc.d/rc.network restart

rm -f "$LOCKFILE"
