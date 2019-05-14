#!/bin/sh
#
# /etc/init.d/network.sh : Network initialization boot script
# /etc/network.conf      : Main SliTaz network configuration file
# /etc/wpa/wpa.conf      : Wi-Fi networks configuration file

. /etc/init.d/rc.functions

if [ -d /dev/shm ] && [ -w /dev/shm ]; then
wkdir="/dev/shm"
else
wkdir="/tmp"
fi

cleanup(){
rm -f $wkdir/network.lock 2>/dev/null
}

tabulate_interfaces(){
ALL_INTF=`ls -1 /sys/class/net | grep -v '^lo$' | tr '\n' ' '`
xETH=""
xWLAN=""

for IF1 in $ALL_INTF
do

xIF_DRIVER="`readlink /sys/class/net/$IF1/device/driver | rev | cut -f1 -d'/' | rev`" #ex: ath5k
[ "$xIF_DRIVER" = "ath5k_pci" ] && [ "`lsmod | grep '^ath5k '`" != "" ] && xIF_DRIVER='ath5k'

ePATTERN="${IF1}:"
if [ "`grep "$ePATTERN" /proc/net/wireless`" != "" ] || [ "$xIF_DRIVER" = "prism2_usb" ] || [ -d /sys/class/net/${IF1}/wireless ]; then
 if [ "$xWLAN" == "" ]; then
  xWLAN="$IF1"
 else
  xWLAN="$xWLAN $IF1"
 fi
else
 if [ "$xETH" == "" ]; then
  xETH="$IF1"
 else
  xETH="$xETH $IF1"
 fi
fi

done
}

random_interface(){

itf1="$1"

if [ ! -f /etc/net-random.cfg ]; then
 continue
fi

. /etc/net-random.cfg

if [ "$(echo "$RANDOM_MAC" | tr "[a-z]" "[A-Z]")" == "ON" ]; then

 xstate="$(cat /sys/class/net/$itf1/operstate 2>/dev/null)"

 if [ "$xstate" != "down" ]; then
  ifconfig $itf1 down
 fi

 macchanger -r $itf1 >/dev/null

fi
	
}

random_all_interfaces(){

if [ ! -f /etc/net-random.cfg ]; then
 continue
fi

. /etc/net-random.cfg

if [ "$(echo "$RANDOM_MAC" | tr "[a-z]" "[A-Z]")" == "ON" ]; then

oINTF="$(echo "$xETH" | tr ' ' '\n' | grep -v "^lo" | tr '\n' ' ')"

for itf1 in $oINTF
do
 xstate="$(cat /sys/class/net/$itf1/operstate 2>/dev/null)"
 if [ "$xstate" != "down" ]; then
  ifconfig $itf1 down
 fi
 macchanger -r $itf1 >/dev/null
done


fi
	
}

probe_eths(){

. "$CONF"
	
RNDIS="$(echo "$xETH" | tr ' ' '\n' | grep -v "eth" | tr '\n' ' ')"
oETH="$(echo "$xETH" | tr ' ' '\n' | grep "eth" | tr '\n' ' ')"

if [ "$RNDIS" != "" ]; then
 oLIST="$RNDIS"
else
 oLIST="$oETH"
fi

for eth1 in $oLIST
do
xstate="$(cat /sys/class/net/$eth1/operstate 2>/dev/null)"
cs="$(cat /sys/class/net/$eth1/carrier 2>/dev/null)"
if [ "$xstate" != "" ] && [ "$xstate" != "down" ] && [ "$cs" == "1" ]; then
	xIP="$(busybox ifconfig $eth1 | grep -Po "t addr:\K[\d.]+")"
	 if [ "$xIP" != "" ]; then
	  interface="$eth1"
	  break
	 fi
fi
done

}

update_interface(){
	
. "$CONF"
    
    interface=""	
	
	if [ "$WIFI" == "yes" ]; then
	   if [ -e /sys/class/net/$WIFI_INTERFACE ]; then
	    ostate="$(cat /sys/class/net/$WIFI_INTERFACE/operstate 2>/dev/null)"
	      if [ "$ostate" != "" ] && [ "$ostate" != "down" ]; then
	       interface="$WIFI_INTERFACE"
	      else
	       probe_eths
	      fi
	   else
	    probe_eths
	   fi
	else
	  probe_eths
	fi
	
	if [ "$interface" == "" ]; then
     interface="$INTERFACE"
    fi

	for i in $(find ${XDG_CONFIG_HOME:-$HOME/.config}/lxpanel -name panel 2>/dev/null); do
		fgrep -q netstatus "$i" || continue
		sed -i '/iface/s|=.*$|='$interface'|' "$i"
	done	
	
}

update_interface_root(){

. "$CONF"
    
    interface=""	
	
	if [ "$WIFI" == "yes" ]; then
	   if [ -e /sys/class/net/$WIFI_INTERFACE ]; then
	    sleep 5
	    ostate="$(cat /sys/class/net/$WIFI_INTERFACE/operstate 2>/dev/null)"
	      if [ "$ostate" != "" ] && [ "$ostate" != "down" ]; then
	       interface="$WIFI_INTERFACE"
	      else
	       probe_eths
	      fi
	   else
	    probe_eths
	   fi
	else
	  probe_eths
	fi
	
	if [ "$interface" == "" ]; then
     interface="$INTERFACE"
    fi
		
	if [ -f /etc/lxpanel/default/panels/panel ]; then
		sed -i "s/iface=.*/iface=$interface/" /etc/lxpanel/default/panels/panel
	fi
	
	for i in $(find $HOME/.config/lxpanel -name panel 2>/dev/null); do
		fgrep -q netstatus "$i" || continue
		sed -i '/iface/s|=.*$|='$interface'|' "$i"
	done	
	
}

# Actions executing on boot time (running network.sh without parameters)
default_cfg(){

INTF="$1"	
	
IF_DRIVER="`readlink /sys/class/net/$INTF/device/driver | rev | cut -f1 -d'/' | rev`" #ex: ath5k
[ "$IF_DRIVER" = "ath5k_pci" ] && [ "`lsmod | grep '^ath5k '`" != "" ] && IF_DRIVER='ath5k'

ePATTERN="${INTF}:"
if [ "`grep "$ePATTERN" /proc/net/wireless`" != "" ]; then
 IsWireless=1
elif [ "$IF_DRIVER" = "prism2_usb" ]; then
 IsWireless=1
elif [ -d /sys/class/net/${INTF}/wireless ]; then
 IsWireless=1
else
 IsWireless=0
fi

 if [ ! -d /etc/network-config ]; then
  mkdir /etc/network-config
 fi

 if [ $IsWireless -eq 0 ]; then
  cp /etc/wired-template.conf /etc/network-config/$INTF.conf
 elif [ $IsWireless -eq 1 ]; then
  cp /etc/wireless-template.conf /etc/network-config/$INTF.conf
 fi 		
}

set_metrics(){

INTF="$1"

if [ ! -e /etc/network-config/$INTF.conf ]; then
 default_cfg "$INTF"
fi

. /etc/network.conf
. /etc/network-config/$INTF.conf
	
if [ "$INTF" != "$INTERFACE" ] && [ "$METRICS" != "" ]; then

	GW=`route -n |  grep "$INTF" | awk '{if ($4=="UG")print $2}'`

	if [ "$GW" != "" ]; then
	 route delete default gw $GW dev $INTF > /dev/null
	fi

	route add default gateway $GW dev $INTF metric $METRICS > /dev/null
	
fi

}

boot() {
	# Set hostname
	action 'Setting hostname to: %s' "$(cat /etc/hostname)"
	/bin/hostname -F /etc/hostname
	status

	# Configure loopback interface
	action 'Configuring loopback...'
	/sbin/ifconfig lo 127.0.0.1 up
	/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 dev lo
	status

	[ -s /etc/sysctl.conf ] && sysctl -p /etc/sysctl.conf
}

# Freedesktop notification
notification() {
	busybox ps aux 2>/dev/null | grep -q [X]org || return
	[ -n "$DISPLAY" ] || return
	which notify-send >/dev/null || return

	icon=$(echo $1 | awk -vw=$WIFI '{printf("notification-network-%s%s\n",
		w=="yes"?"wireless":"wired", /start/?"":"-disconnected");}')

	# FIXME: this valid only for lxde-session
	local user="$(busybox ps aux 2>/dev/null | grep [l]xde-session | awk 'END{print $2}')"
	local rpid=''
	[ -s "$npid" ] && rpid="-r $(cat $npid)"
	su -c "notify-send $rpid -p -i $icon 'Network' \"$2\"" - $user | tr -c 0-9 '\n' | tail -n1 > $npid
}


# Change LXPanel Network applet interface
ch_netapplet() {
	for user in $(awk -F: '$6 ~ "/home/" {print $1}' /etc/passwd); do
		# need to be executed as user, due to different XDG variables
	    if [ -d /home/$user ]; then
		 su -l -c ". /etc/profile; $0 netapplet" - "$user"
	    fi
	done
	# restart if LXPanel running
	if [ -n "$DISPLAY" -a -n "$(which lxpanelctl)" ]; then
		lxpanelctl restart
	fi
}

# Use ethernet
eth() {
INTF="$1"

		notification start "$(_ 'Starting Ethernet interface %s...' "$INTF")"
		
		if [ "$(ifconfig | grep "$INTF")" == "" ]; then
		 ifconfig $INTF up
		fi
		
		ip addr flush dev $INTF
		sleep 5
}

# Start wpa_supplicant with prepared settings in wpa.conf
start_wpa_supplicant() {
	INTF="$2"
	echo "Starting wpa_supplicant for $1..."
	wpa_supplicant -B -W -c $WPA_CONF -D $WIFI_WPA_DRIVER -i $INTF
}

# Reconnect to the given network
reconnect_wifi_network() {
	if [ "$WIFI" == 'yes' ]; then
		# Wpa_supplicant will auto-connect to the first network
		# notwithstanding to priority when scan_ssid=1
		
		if [ -d /var/run/wpa_supplicant ]; then
		 echo "Waiting wpa_cli...."
		  wpa_cli -a "/etc/init.d/wpa_cli_static.sh" -B 2>/dev/null
        fi
		
		current_ssid="$(wpa_cli list_networks 2>/dev/null | fgrep '[CURRENT]' | cut -f2)"
		
		if [ "$current_ssid" != "$WIFI_ESSID" ]; then
			notification start "$(_ 'Connecting to %s...' "$WIFI_ESSID")"
			action 'Connecting to %s...' "$WIFI_ESSID"
			echo ""
			for i in $(seq 5); do
				index=$(wpa_cli list_networks 2>/dev/null | grep  "$WIFI_ESSID" | head -n 1 | cut -f 1)
					if [ "$index" == "" ]; then
					 echo -n '.' 
					 sleep 1
					else
					 break
					fi
			done
			wpa_cli select_network $index 2>/dev/null; status
		fi
	fi
}

# Remove selected network settings from wpa.conf
remove_network() {
	mv -f $WPA_CONF $WPA_CONF.old
	cat $WPA_CONF.old | tr '\n' '\a' | sed 's|[^#]\(network={\)|\n\1|g' | \
		fgrep -v "ssid=\"$1\"" | tr '\a' '\n' > $WPA_CONF
}

# For Wi-Fi. Users just have to enable it through WIFI="yes" and usually
# ESSID="any" will work and the interface is autodetected.

wifi() {

INTF="$1"

if [ ! -e /etc/network-config/$INTF.conf ]; then
 cp /etc/wireless-template.conf /etc/network-config/$INTF.conf
fi

. /etc/network-config/$INTF.conf

if [ "$INTERFACE_TYPE" != "wireless" ]; then
 cp /etc/wireless-template.conf /etc/network-config/$INTF.conf
fi

. /etc/network-config/$INTF.conf
	
	if [ "$WIFI" == 'yes' ]; then
	
		ifconfig $INTF down  2>/dev/null
		notification start "$(_ 'Starting Wi-Fi interface %s...' "$INTF")"
		action 'Configuring Wi-Fi interface %s...' "$WIFI_INTERFACE"
		ifconfig $INTF up 2>/dev/null
		
		if iwconfig $INTF | fgrep -q 'Tx-Power'; then
			iwconfig $INTF txpower on
		fi
		
		ip addr flush dev $INTF

		status

		IWCONFIG_ARGS=''
		[ -n "$WIFI_WPA_DRIVER" ] || WIFI_WPA_DRIVER='wext'
		[ -n "$WIFI_MODE" ]    && IWCONFIG_ARGS="$IWCONFIG_ARGS mode $WIFI_MODE"
		[ -n "$WIFI_CHANNEL" ] && IWCONFIG_ARGS="$IWCONFIG_ARGS channel $WIFI_CHANNEL"
		[ -n "$WIFI_AP" ]      && IWCONFIG_ARGS="$IWCONFIG_ARGS ap $WIFI_AP"

		# Use "any" network only when it is needed
		[ "$WIFI_ESSID" != 'any' ] && remove_network 'any'

		# Clean all / add / change stored networks settings
		if [ "$WIFI_BLANK_NETWORKS" == 'yes' ]; then
			echo "Creating new $WPA_CONF"
			cat /etc/wpa/wpa_empty.conf > $WPA_CONF
		else
			if fgrep -q "ssid=\"$WIFI_ESSID\"" $WPA_CONF; then
				echo "Change network settings in $WPA_CONF"
				# Remove given existing network (it's to be appended later)
				remove_network "$WIFI_ESSID"
			else
				echo "Append existing $WPA_CONF"
			fi
		fi

		# Each new network has a higher priority than the existing
		MAX_PRIORITY=$(sed -n 's|[\t ]*priority=\([0-9]*\)|\1|p' $WPA_CONF | sort -g | tail -n1)
		PRIORITY=$(( ${MAX_PRIORITY:-0} + 1 ))

		# Begin network description
		cat >> $WPA_CONF <<EOT
network={
	ssid="$WIFI_ESSID"
EOT

		# For networks with hidden SSID: write its BSSID
		[ -n "$WIFI_BSSID" ] && cat >> $WPA_CONF <<EOT
	bssid=$WIFI_BSSID
EOT
		# Allow probe requests (for all networks)
		cat >> $WPA_CONF <<EOT
	scan_ssid=1
EOT

		case x$(echo -n $WIFI_KEY_TYPE | tr a-z A-Z) in
			x|xNONE) # Open network
				cat >> $WPA_CONF <<EOT
	key_mgmt=NONE
	priority=$PRIORITY
}
EOT
				# start_wpa_supplicant NONE
				iwconfig $INTF essid "$WIFI_ESSID" $IWCONFIG_ARGS
				;;

			xWEP) # WEP security
				# Encryption key length:  64 bit  (5 ASCII or 10 HEX)
				# Encryption key length: 128 bit (13 ASCII or 26 HEX)
				# ASCII key in "quotes", HEX key without quotes
				case "${#WIFI_KEY}" in
					10|26) Q=''  ;;
					*)     Q='"' ;;
				esac
				cat >> $WPA_CONF <<EOT
	key_mgmt=NONE
	auth_alg=OPEN SHARED
	wep_key0=$Q$WIFI_KEY$Q
	priority=$PRIORITY
}
EOT
				start_wpa_supplicant WEP $INTF;;

			xWPA) # WPA/WPA2-PSK security
				cat >> $WPA_CONF <<EOT
	psk="$WIFI_KEY"
	key_mgmt=WPA-PSK
	priority=$PRIORITY
}
EOT
				start_wpa_supplicant WPA/WPA2-PSK $INTF;;

			xEAP) # 802.1x EAP security
				{
					cat <<EOT
	key_mgmt=WPA-EAP IEEE8021X
	eap=$WIFI_EAP_METHOD
EOT
					if [ "$WIFI_EAP_METHOD" == 'PWD' ]; then
						WIFI_PHASE2=''; WIFI_CA_CERT=''; WIFI_USER_CERT=''; WIFI_ANONYMOUS_IDENTITY=''
					fi
					[ -n "$WIFI_CA_CERT" ] && echo -e "\tca_cert=\"$WIFI_CA_CERT\""
					[ -n "$WIFI_CLIENT_CERT" ] && echo -e "\tclient_cert=\"$WIFI_CLIENT_CERT\""
					[ -n "$WIFI_IDENTITY" ] && echo -e "\tidentity=\"$WIFI_IDENTITY\""
					[ -n "$WIFI_ANONYMOUS_IDENTITY" ] && echo -e "\tanonymous_identity=\"$WIFI_ANONYMOUS_IDENTITY\""
					[ -n "$WIFI_KEY" ] && echo -e "\tpassword=\"$WIFI-KEY\""
					[ -n "$WIFI_PHASE2" ] && echo -e "\tphase2=\"auth=$WIFI_PHASE2\""
					echo }
				} >> $WPA_CONF
				start_wpa_supplicant '802.1x EAP' $INTF;;

			xANY)
				cat >> $WPA_CONF <<EOT
	key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE
	group=CCMP TKIP WEP104 WEP40
	pairwise=CCMP TKIP
	psk="$WIFI_KEY"
	password="$WIFI_KEY"
	priority=$PRIORITY
}
EOT
				start_wpa_supplicant 'any key type' $INTF;;

		esac
		#INTERFACE=$WIFI_INTERFACE
		
	fi
}


# WPA DHCP script
wpa() {
	wpa_cli -a "/etc/init.d/wpa_action.sh" -B
}

# For a dynamic IP with DHCP
dhcp() {

INTF="$1"

if [ ! -e /etc/network-config/$INTF.conf ]; then
 default_cfg "$INTF"
fi

. /etc/network-config/$INTF.conf
	
	if [ "$STATIC" != "yes" ]; then
		echo "Starting udhcpc client on: $INTF..."
		# Is wpa wireless && wpa_ctrl_open interface up?
		if [ -d /var/run/wpa_supplicant ]; then
			wpa
		else
			# fallback on udhcpc: wep, eth
		 netcar="$(cat /sys/class/net/$INTF/carrier 2>/dev/null)"
		  if [ "$netcar" != "" ] && [ "$netcar" == "1" ]; then
		    if [ "$INTERFACE_TYPE" == "wireless" ]; then
			 /sbin/udhcpc -b -T 1 -A 12 -i $INTF -p /var/run/udhcpc.$INTF.pid
			else
			 /sbin/udhcpc -n -q -T 1 -A 12 -i $INTF
			fi
		  fi
		fi
		
		if [ "$(cat /etc/resolv.conf | sed -e "s#\n##g" )" == "" ]; then
		 #No dns given. Use google and dns watch DNS server"
		 echo "nameserver 8.8.8.8" >> /etc/resolv.conf
		 echo "nameserver 8.8.4.4" >> /etc/resolv.conf
		 echo "nameserver 84.200.69.80" >> /etc/resolv.conf
		 echo "nameserver 84.200.70.40" >> /etc/resolv.conf
		fi	
		
	fi
}


# For a static IP
static_ip() {

INTF="$1"

if [ ! -e /etc/network-config/$INTF.conf ]; then
 default_cfg "$INTF"
fi

. /etc/network-config/$INTF.conf

	if [ "$STATIC" == 'yes' ]; then
	
		echo "Configuring static IP on $INTF: $IP..."
		
		BCAST=$(ipcalc -b "$IP" "$NETMASK" | cut -f 2 -d '=')
		
		ifconfig $INTF $IP netmask $NETMASK broadcast $BCAST up

		# Use ip to set gateways if iproute.conf exists
		if [ -f /etc/iproute.conf ]; then
			while read line; do
			   echo "Loading iproute configuration..."
				ip route add $line
			done < /etc/iproute.conf
		else

			GW=`route -n |  grep "$INTF" | awk '{if ($4=="UG")print $2}'`
			
			if [ "$GW" != "" ]; then
			 route delete default gw $GW dev $INTF > /dev/null
			fi
			
			route add default gateway $GATEWAY dev $INTF > /dev/null
		fi

		# wpa_supplicant waits for wpa_cli
		
		if [ -d /var/run/wpa_supplicant ]; then
		  echo "Waiting wpa_cli...."
		  wpa_cli -a "/etc/init.d/wpa_cli_static.sh" -B
        fi
		 
		# Multi-DNS server in $DNS_SERVER
		/bin/mv /etc/resolv.conf /tmp/resolv.conf.$$
		{
			printf 'nameserver %s\n' $DNS_SERVER			# Multiple allowed
			[ -n "$DOMAIN" ] && echo "search $DOMAIN"
		} >> /etc/resolv.conf
		
		if [ "$(cat /etc/resolv.conf | sed -e "s#\n##g")" == "" ]; then
		 #No dns given. Use google and dns watch DNS server"
		 echo "nameserver 8.8.8.8" >> /etc/resolv.conf
		 echo "nameserver 8.8.4.4" >> /etc/resolv.conf
		 echo "nameserver 84.200.69.80" >> /etc/resolv.conf
		 echo "nameserver 84.200.70.40" >> /etc/resolv.conf
		fi
		
		for HELPER in /etc/ipup.d/*; do
			[ -x $HELPER ] && $HELPER $INTF $DNS_SERVER
		done
	fi
}

# Stopping everything
stop() {
	
	notification stop "$(_ 'Stopping all interfaces')"
		
	#ifconfig $WIFI_INTERFACE down

	echo 'Killing all daemons'
	
	killall ethmon 2>/dev/null
	killall udhcpc 2>/dev/null
	killall dhcpcd 2>/dev/null
	ppp -d 2>/dev/null
	killall ppd 2>/dev/null
	killall pand 2>/dev/null
	killall wvdial 2>/dev/null
	wpa_cli terminate 2>/dev/null
	killall wpa_cli 2>/dev/null
	killall wpa_supplicant 2>/dev/null
  
    echo 'Stopping wired interfaces'
	for iface in $xETH; do
	  ip addr flush dev $iface
	  ifconfig $iface down
	done
  
    if [ "$xWLAN" != "" ]; then
    echo 'Stopping wireless interfaces'     
		for IF4 in $xWLAN
		do
		    if [ "`iwconfig | grep "^$IF4" | grep "ESSID"`" != "" ]; then
		      iwconfig $IF4 essid off #100309
		    fi
		    
		    ifconfig $IF4 down	
		    
			if iwconfig $IF4| fgrep -q 'Tx-Power'; then
				echo "Shutting down Wi-Fi card $IF4"
				iwconfig $IF4 txpower off
			fi
		done
    fi

}

stop_if(){
    INTF="$1"	
	
	notification stop "$(_ 'Stopping %s' '$INTF')"
	
	if iwconfig $INTF| fgrep -q 'Tx-Power'; then
	 wLAN=1
	else
 	 wLAN=0
	fi
		
	if [ $wLAN -ne 0 ]; then
	
		if [ "`iwconfig | grep "^$INTF" | grep "ESSID"`" != "" ]; then
		 iwconfig $INTF essid off #100309
		fi	

	     wpa_cli terminate 2>/dev/null
	     killall wpa_cli 2>/dev/null
	     killall wpa_supplicant 2>/dev/null
	fi
	
	ip addr flush dev $INTF
	ifconfig $INTF down
	
	if [ $wLAN -ne 0 ]; then
		echo "Shutting down Wi-Fi card: $INTF"
		iwconfig $INTF txpower off
	fi
	
}

start() {
	# stopping only unspecified interfaces
	interfaces="$(ifconfig | sed -e '/^[^ ]/!d' -e 's|^\([^ ]*\) .*|\1|' -e '/lo/d')"
	
	case $WIFI in
		# don't stop Wi-Fi Interface if Wi-Fi selected
		yes) interfaces="$(echo "$interfaces" | sed -e "/^$WIFI_INTERFACE$/d")";;
	esac
	
  
   if  [ "$DEV8" == "" ]; then
   	
	   for iface in $interfaces; do
		ifconfig $iface down
	   done

	   for iface2 in $xETH
	   do
		eth $iface2
		dhcp $iface2
		static_ip $iface2
		set_metrics $iface2
	   done

	   for iface2 in $xWLAN	
	   do
		wifi $iface2
		reconnect_wifi_network
		dhcp $iface2
		static_ip $iface2
		set_metrics $iface2
	   done
	   
   else
   
   	ifconfig $DEV8 down
   
	   if [ "$(echo $xWLAN | grep "$DEV8")" == "" ]; then
	   	eth $DEV8
		dhcp $DEV8
		static_ip $DEV8
		set_metrics $DEV8
	   else
	    wifi $DEV8
		reconnect_wifi_network
		dhcp $DEV8
		static_ip $DEV8
		set_metrics $DEV8
	   fi
     
   fi

	# change default LXPanel panel iface
	#if [ -f /etc/lxpanel/default/panels/panel ]; then
	#	sed -i "s/iface=.*/iface=$INTERFACE/" /etc/lxpanel/default/panels/panel
	#fi
	
}


tabulate_interfaces

if [ "$2" == "" ]; then
  CONF="/etc/network.conf"
else
  if [ ! -e $2 ]; then
  CONF="/etc/network.conf"
  else
  CONF="$2"
  fi
fi

DEV8="$3"

[ "$1" != 'netapplet' ] && echo "Loading network settings from $CONF"

. "$CONF"

if [ ! -d /etc/network-config ]; then
 mkdir /etc/network-config
fi

if [ "$DEV8" != "" ]; then
	if [ "$(echo "$xETH" | grep "$DEV8")" == "" ] && [ "$(echo "$xWLAN" | grep "$DEV8")" == "" ]; then
	 echo "Invalid interface"
	 exit
	fi
fi

# Change LXPanel Network applet settings

if [ "$1" == 'netapplet' ]; then
	update_interface
	exit 0
fi

WPA_CONF='/etc/wpa/wpa.conf'

[ ! -e "$WPA_CONF" ] && cp /etc/wpa/wpa_empty.conf $WPA_CONF 2>/dev/null


npid='/tmp/notify_pid'

# Migrate existing settings to a new format file

. /usr/share/slitaz/network.conf_migration

# Looking for arguments:

if [ "$(whoami)" != "root" ]; then
 echo "Run this program as root"
 exit
fi

trap cleanup EXIT
trap cleanup SIGKILL
trap cleanup SIGTERM

case "$1" in
	'')
		touch $wkdir/network.lock
		boot
		
		if [ "$(which macchanger)" != "" ]; then
		 random_all_interfaces
		fi
		
		start
		sleep 3
		update_interface_root
		ch_netapplet
		
		if [ "$(pidof dhcpd)" == "" ]; then
		 if [ "$(pidof ethmon)" == "" ]; then
		   if [ "$DEV8" != "" ]; then
		    xDC=$(busybox ps | grep "udhcpc" | grep "i $DEV8" | grep -v "grep")
		   else
		    xDC=$(busybox ps | grep "udhcpc" | grep "i eth" | grep -v "grep")
		   fi
		 
		   if [ "$xDC" == "" ]; then
		    ethmon &
		   fi
		 fi
		fi
		
		rm -f $wkdir/network.lock
		
		;;
	start)
		
		rm -f touch $wkdir/network-stop.lock 2>/dev/null
	
	    touch $wkdir/network.lock
	    
	    if [ "$(which macchanger)" != "" ]; then
	     if [ "$DEV8" != "" ]; then
	      random_interface $DEV8
		 else
		  random_all_interfaces
		 fi
		fi
	    
		start
		sleep 3
		update_interface_root
		ch_netapplet
		
		if [ "$(pidof dhcpd)" == "" ]; then
		 if [ "$(pidof ethmon)" == "" ]; then
		   if [ "$DEV8" != "" ]; then
		    xDC=$(busybox ps | grep "udhcpc" | grep "i $DEV8" | grep -v "grep")
		   else
		    xDC=$(busybox ps | grep "udhcpc" | grep "i eth" | grep -v "grep")
		   fi
		 
		   if [ "$xDC" == "" ]; then
		    ethmon &
		   fi
		 fi
		fi
		
		rm -f $wkdir/network.lock
		
		;;
	stop)
	
	    touch $wkdir/network.lock
	
        if [ "$DEV8" == "" ]; then	
		stop
		else
		stop_if $DEV8
		fi
		
	    if [ "$(which macchanger)" != "" ]; then
	     if [ "$DEV8" != "" ]; then
	      random_interface $DEV8
		 else
		  random_all_interfaces
		 fi
		fi
		
		sleep 3
		update_interface_root
		ch_netapplet
		rm -f $wkdir/network.lock
		touch $wkdir/network-stop.lock
		
	;;
	restart)
	
		touch $wkdir/network.lock
	
		if [ "$DEV8" == "" ]; then	
		 stop
		else
		 stop_if $DEV8
		fi
		
		sleep 3
		rm -f touch $wkdir/network-stop.lock 2>/dev/null
		
	    if [ "$(which macchanger)" != "" ]; then
	     if [ "$DEV8" != "" ]; then
	      random_interface $DEV8
		 else
		  random_all_interfaces
		 fi
		fi
		
		start
		sleep 3		
		update_interface_root
		ch_netapplet
		
		if [ "$(pidof dhcpd)" == "" ]; then
		 if [ "$(pidof ethmon)" == "" ]; then
		   if [ "$DEV8" != "" ]; then
		    xDC=$(busybox ps | grep "udhcpc" | grep "i $DEV8" | grep -v "grep")
		   else
		    xDC=$(busybox ps | grep "udhcpc" | grep "i eth" | grep -v "grep")
		   fi
		 
		   if [ "$xDC" == "" ]; then
		    ethmon &
		   fi
		 fi
		fi
		
		rm -f $wkdir/network.lock
		
		;;
	*)
		cat <<EOT

$(boldify 'Usage:') /etc/init.d/$(basename $0) [start|stop|restart]

Default configuration file is $(boldify '/etc/network.conf')
The interface settings was in /etc/network-config
You can specify another configuration file in the second argument:
/etc/init.d/$(basename $0) [start|stop|restart] file.conf

EOT
		;;
esac

[ -f "$npid" ] && rm "$npid"
