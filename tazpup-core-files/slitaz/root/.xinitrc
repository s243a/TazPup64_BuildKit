#!/bin/sh
# ~/.xinitrc: Executed by Slim/LXDM login manager to startx X session.
# You can use F1 with Slim to change your window manager or configure
# it permanently with your personal applications.conf file.
#
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
if [ -f "$XDG_CONFIG_HOME"/slitaz/applications.conf ]; then
    apps_conf="$XDG_CONFIG_HOME"/slitaz/applications.conf
elif [ -f "/etc/skel/.config/slitaz/applications.conf" ]; then
    apps_conf="/etc/skel/.config/slitaz/applications.conf"
elif [ -f "/etc/slitaz/applications.conf" ]
    apps_conf="/etc/slitaz/applications.conf"
fi
if [ -z "$apps_conf" ]; then
  WINDOW_MANAGER=slim
else
  . $apps_conf
fi
tazbox mkmenu

[ "$1" ] && WINDOW_MANAGER="$1"

EXEC="exec ck-launch-session dbus-launch --sh-syntax --exit-with-session"

LOG="/dev/null" ; X=$LOG ; ERR=$X

case "$WINDOW_MANAGER" in
	openbox|lxde*|icewm*|xfce4|compiz|karmen|dwm|fluxbox*|razor*|mate*)
		$EXEC ${WINDOW_MANAGER%-session}-session ;;
	enlightenment)
		$EXEC enlightenment_start ;;
	kde)	$EXEC startkde ;;
	lxqt)	$EXEC startlxqt ;;
	*)	$EXEC $WINDOW_MANAGER ;;
esac	2>>$ERR >>$X
