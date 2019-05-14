#!/bin/sh
#
# /etc/init.d/bootopts.sh : SliTaz boot options from the cmdline
#
# Earlier boot options are in rcS, ex: config= and modprobe=
# modified by mistfire

. /etc/init.d/rc.functions

# Get first usb disk
usb_device() {
	cd /sys/block
	for i in sd* sda ; do
		grep -qs 1 $i/removable && break
	done
	echo $i
}

# Parse /proc/cmdline for boot options.
echo 'Checking for SliTaz cmdline options...'

# Default user account without password (uid=1000). In live mode the option
# user=name can be used, but user must be added before home= to have home dir.
# This option is not handled by a loop and case like others and has no
# effect on an installed system.
if fgrep -q 'user=' /proc/cmdline; then
	USER=$(cat /proc/cmdline | sed 's/.*user=\([^ ]*\).*/\1/')
	# Avoid usage of an existing system user or root.
	if grep -q ^$USER /etc/passwd; then
		USER=tux
	fi
else
	USER=tux
fi

if ! grep -q '100[0-9]:100' /etc/passwd; then
	# Make sure we have users applications.conf
	if [ ! -f '/etc/skel/.config/slitaz/applications.conf' -a \
		-f '/etc/slitaz/applications.conf' ]; then
		mkdir -p /etc/skel/.config/slitaz
		cp /etc/slitaz/applications.conf /etc/skel/.config/slitaz
	fi

	action 'Configuring user and group: %s...' "$USER"
	#echo ""
	#echo -n ""
	adduser -D -s /bin/sh -g 'SliTaz User' -G users -h /home/$USER $USER 2>/dev/null
	passwd -d $USER 2>/dev/null
	for group in audio cdrom video tty plugdev disk lp scanner dialout camera operator tape
	do
		addgroup $USER $group 2>/dev/null
	done
	status

    if [ "$(which hald)" != "" ] && [ -e /etc/init.d/hald ]; then
		action 'Configuring %s...' "haldaemon"
		adduser -D -H haldaemon 2>/dev/null
			for group in audio cdrom video tty plugdev disk lp scanner dialout camera operator tape
			do
				addgroup haldaemon $group 2>/dev/null
			done
			addgroup haldaemon haldaemon 2>/dev/null
		status
	fi

	# Slim default user
	if [ -f /etc/slim.conf ]; then
		sed -i "s|default_user .*|default_user    $USER|" /etc/slim.conf
	fi
fi

# Make sure selected user has home
if [ ! -d /home/$USER ]; then
	cp -a /etc/skel /home/$USER
	chown -R $USER:users /home/$USER
fi

for opt in $(cat /proc/cmdline); do
	case $opt in
		eject)
			# Eject cdrom.
			eject /dev/cdrom ;;
		autologin)
			# Autologin option to skip first graphic login prompt.
			if [ -f /etc/slim.conf ]; then
				sed -i '/auto_login .*/d' /etc/slim.conf
				echo 'auto_login        yes' >> /etc/slim.conf
			fi ;;
		lang=*)
			# Check for a specified locale (lang=*).
			LANG=${opt#lang=}
			/sbin/tazlocale ${LANG%.UTF-8} ;;
		kmap=*)
			# Check for a specified keymap (kmap=*).
			KEYMAP=${opt#kmap=}
			action 'Setting system keymap to: %s...' "$KEYMAP"
			echo "$KEYMAP" > /etc/keymap.conf
			status ;;
		pkeys=*)
			# Check for a specified keymap (pkeys=*).
			KEYMAP=${opt#pkeys=}
			action 'Setting system keymap to: %s...' "$KEYMAP"
			echo "$KEYMAP" > /etc/keymap.conf
			status ;;	
		tz=*)
			# Check for a specified timezone (tz=*).
			TZ=${opt#tz=}
			action 'Setting timezone to: %s...' "$TZ"
			echo "$TZ" > /etc/TZ
			status ;;
		font=*)
			# Check for a specified console font (font=*).
			FONT=${opt#font=}
			action 'Setting console font to: %s...' "$FONT"
			for con in 1 2 3 4 5 6; do
				setfont $FONT -C /dev/tty$con
			done
			status ;;
		laptop)
			# Enable Kernel Laptop mode.
			echo '5' > /proc/sys/vm/laptop_mode ;;
		mount)
			# Mount all ext3 partitions found (opt: mount).

			# Get the list of partitions.
			DEVICES_LIST=$(fdisk -l | sed '/83 Linux/!d;s/ .*//')

			# Mount filesystems rw.
			for device in $DEVICES_LIST; do
				name=${device#/dev/}
				# Device can be already used by home=usb.
				if ! mount | grep ^$device >/dev/null; then
					echo "Mounting partition: $name on /mnt/$name"
					mkdir -p /mnt/$name
					mount $device /mnt/$name
				fi
			done ;;
		mount-packages)
			# Mount and install packages-XXX.iso (useful without Internet
			# connection).
			PKGSIGN="LABEL=\"packages-$(cat /etc/slitaz-release)\" TYPE=\"iso9660\""
			PKGDEV=$(blkid | grep "$PKGSIGN" | cut -d: -f1)
			[ -z "$PKGDEV" -a -L /dev/cdrom ] && \
				PKGDEV=$(blkid /dev/cdrom | grep "$PKGSIGN" | cut -d: -f1)
			if [ -n "$PKGDEV" ]; then
				action 'Mounting packages archive from %s...' "$PKGDEV"
				mkdir -p /packages; mount -t iso9660 -o ro $PKGDEV /packages
				status
				/packages/install.sh
			fi ;;
		wm=*)
			# Check for a Window Manager (for a flavor, default WM can be changed
			# with boot options or via /etc/slitaz/applications.conf).
			WM=${opt#wm=}
			case $WM in
				ob|openbox|openbox-session)
					WM=openbox-session ;;
				e17|enlightenment|enlightenment_start)
					WM=enlightenment ;;
				razorqt|razor-session)
					WM=razor-session ;;
				lxde|lxde-session)
					WM=lxde-session;;
				lxqt|lxqt-session)
					WM=lxqt-session;;		
				xfce|xfce4|xfce-session|xfce4-session)
					WM=xfce4-session ;;
				cinnamon|cinnamon-session)
					WM=cinnamon-session ;;
				mate|mate-session )
					WM=mate-session ;;	
				gnome|gnome-session )
					WM=gnome-session ;;				
			esac
			sed -i s/"WINDOW_MANAGER=.*"/"WINDOW_MANAGER=\"$WM\""/ \
				/etc/slitaz/applications.conf ;;
		*)
			continue ;;
	esac
done
