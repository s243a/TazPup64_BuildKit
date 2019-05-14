#!/bin/sh
#
# Network/PPP configuration CGI interface
#
# Copyright (C) 2015 SliTaz GNU/Linux - BSD License
#
# Common functions from libtazpanel
# Modified by mistfire for TazPuppy

. lib/libtazpanel
get_config


set_secrets()
{
	grep -qs "^$1	" /etc/ppp/pap-secrets ||
	echo "$1	*	$2" >> /etc/ppp/pap-secrets
	grep -qs "^$1	" /etc/ppp/chap-secrets ||
	echo "$1	*	$2" >> /etc/ppp/chap-secrets
}

generate_gsm_conf()
{

echo 'DEVICE="'$(GET gprs3gdev)'"
NUMBER="'$(GET gprs3gnum)'"
APN="'$(GET gprs3gapn)'"
PIN="'$(GET gprs3gpin)'"
USERNAME="'$(GET gprs3guser)'"
PASSWORD="'$(GET gprs3gpwd)'"
AUTH="'$(GET gprs3gauth)'"' > /etc/gprs.conf

. /etc/gprs.conf

echo "ABORT 'BUSY'
ABORT 'NO CARRIER'
ABORT 'VOICE'
ABORT 'NO DIALTONE'
ABORT 'NO DIAL TONE'
ABORT 'NO ANSWER'
ABORT 'DELAYED'
REPORT CONNECT
TIMEOUT 6
'' 'ATQ0'
'OK-AT-OK' 'ATZ'
TIMEOUT 3
'OK' 'ATI'
'OK' 'ATZ'
'OK' 'ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0'" > /etc/ppp/scripts/gsm.chat

if [ "$PIN" != "" ]; then
 echo "'OK' 'AT+CPIN=\"$PIN\"'" >> /etc/ppp/scripts/gsm.chat
fi

echo "'OK' 'AT+CGDCONT=1,\"IP\",\"$APN\"'
'OK' 'ATDT$NUMBER'
TIMEOUT 30
CONNECT ''
" >> /etc/ppp/scripts/gsm.chat

cat > /etc/ppp/options-gsm << EOT
debug
$DEVICE
460800
modem
crtscts
lock
passive
defaultroute
noipdefault
usepeerdns
hide-password
persist
holdoff 10
maxfail 0
asyncmap 0
EOT

echo "file /etc/ppp/options-gsm" > /etc/ppp/peers/gsm

if [ "$USERNAME" == "" ]; then
 echo "noauth" >> /etc/ppp/peers/gsm
else
 echo "auth" >> /etc/ppp/peers/gsm
  
 echo "name \"$USERNAME\"" >> /etc/ppp/peers/gsm
 
	if [ "$PASSWORD" != "" ]; then
	 echo "password \"$PASSWORD\"" >> /etc/ppp/peers/gsm
	fi

	if [ "$AUTH" == "PAP" ]; then
	 echo "require-pap" >> /etc/ppp/peers/gsm
	elif [ "$AUTH" == "CHAP" ]; then
	 echo "require-chap" >> /etc/ppp/peers/gsm
	elif [ "$AUTH" == "EAP" ]; then
	 echo "require-eap" >> /etc/ppp/peers/gsm
	elif [ "$AUTH" == "MSCHAP" ]; then
	 echo "require-mschap" >> /etc/ppp/peers/gsm
	fi

fi
	
echo  "connect \"/usr/sbin/chat -v -t15 -f /etc/ppp/scripts/gsm.chat\"" >> /etc/ppp/peers/gsm

if [ "$USERNAME" ] \
 && ! grep -q -s "^\"$USERNAME\".\*.\"$PASSWORD\"" /etc/ppp/pap-secrets; then
	sed -i -e "/^\"$USERNAME\"\t/d" /etc/ppp/pap-secrets
	echo "\"$USERNAME\"	*	\"$PASSWORD\"" >> /etc/ppp/pap-secrets
	chmod 600 /etc/ppp/pap-secrets
fi #130812 end

if [ "$USERNAME" ] \
 && ! grep -q -s "^\"$USERNAME\".\*.\"$PASSWORD\"" /etc/ppp/chap-secrets; then
	sed -i -e "/^\"$USERNAME\"\t/d" /etc/ppp/chap-secrets
	echo "\"$USERNAME\"	*	\"$PASSWORD\"" >> /etc/ppp/chap-secrets
	chmod 600 /etc/ppp/chap-secrets
fi #130812 end
	
}

create_gsm_conf()
{
	local provider="${1:-myGSMprovider}"
	set_secrets "$provider" "$provider"
	
	[ -s /etc/ppp/scripts/gsm.chat ] ||
	cat > /etc/ppp/scripts/gsm.chat <<EOT
ABORT 'BUSY'
ABORT 'NO CARRIER'
ABORT 'VOICE'
ABORT 'NO DIALTONE'
ABORT 'NO DIAL TONE'
ABORT 'NO ANSWER'
ABORT 'DELAYED'
REPORT CONNECT
TIMEOUT 6
'' 'ATQ0'
'OK-AT-OK' 'ATZ'
TIMEOUT 3
'OK' 'ATI'
'OK' 'ATZ'
'OK' 'ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0'
'OK' 'AT+CGDCONT=1,"IP","$provider"'
'OK' 'ATDT*99#'
TIMEOUT 30
CONNECT ''
EOT

	[ -s /etc/ppp/options-gsm ] ||
	cat > /etc/ppp/options-gsm << EOT
rfcomm0
460800
lock
crtscts
modem
passive
novj
defaultroute
noipdefault
usepeerdns
noauth
hide-password
persist
holdoff 10
maxfail 0
debug
EOT
	[ -s /etc/ppp/peers/gsm ] ||
	cat > /etc/ppp/peers/gsm << EOT
file /etc/ppp/options-gsm
user "$provider"
password "$provider"
connect "/usr/sbin/chat -v -t15 -f /etc/ppp/scripts/gsm.chat"
EOT
}

phone_names()
{
	rfcomm | awk '/connected/{print $2}' | while read mac; do
		grep -A2 $mac /etc/bluetooth/rfcomm.conf | \
			sed '/comment/!d;s/.* "\(.*\) modem";/ \1/'
	done
}

pstn_ppp()
{
	
if [ "$(GET user)" ]; then
set_secrets "$(GET user)" "$(GET pass)"

echo "TIMEOUT 3
ABORT '\nNO CARRIER\r'
ABORT '\nNO DIALTONE\r'
ABORT '\nBUSY\r'
ABORT '\nNO ANSWER\r'
ABORT '\nRINGING\r\n\rRINGING\r'
'' '\rAT'
'OK-+++\c-OK' ATH0
TIMEOUT 30		
OK ATDT$(GET phone)
CONNECT ''
ogin:--ogin: $(GET user)
assword: $(GET pass)" > /etc/ppp/scripts/dialup.chat
		
cat > /etc/ppp/options-dialup << EOT
debug
$(GET dial_modem)
$(GET pstn_baud)
modem
crtscts
lock
defaultroute
noipdefault
persist
asyncmap 20A0000
escape FF
kdebug 0
0.0.0.0:0.0.0.0
netmask 255.255.255.0
EOT

echo "file /etc/ppp/options-dialup
connect \"/usr/sbin/chat -v -t15 -f /etc/ppp/scripts/dialup.chat\"" > /etc/ppp/peers/dialup

pppd call dialup
		
fi	
}

pstn_wvdial()
{
	
echo '[Dialer Defaults]
Init1 = ATZ
Init2 = ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0
Modem Type = Analog Modem
ISDN = 0
Modem = '$(GET dial_modem)'
Baud = '$(GET pstn_baud)'
Abort on Busy = on
Carrier Check = on
Abort on No Dialtone = on

[Dialer DialUp1]
Phone = '$(GET phone)'
Username = '$(GET user)'
Password = '$(GET pass)'
' > /etc/wvdial.conf

wvdial DialUp1 &

sleep 1	
	
}

case "$1" in
	menu)
		TEXTDOMAIN_original=$TEXTDOMAIN
		export TEXTDOMAIN='ppp'

		groups | grep -q dialout && dialout="" || dialout=" data-root"
		case "$2" in
		*VPN*)
		[ "$(which pptp 2>/dev/null)$(which pptpd 2>/dev/null)" ] && cat <<EOT
<li><a data-icon="vpn" href="ppp.cgi#pptp"$dialout>$(_ 'PPTP')</a></li>
EOT
		[ "$(which pppssh 2>/dev/null)" ] && cat <<EOT
<li><a data-icon="vpn" href="ppp.cgi#pppssh"$dialout>$(_ 'PPP/SSH')</a></li>
EOT
		;;
	*)
		cat <<EOT
<li><a data-icon="modem" href="ppp.cgi"$dialout>$(_ 'PPP Modem')</a></li>
EOT
		esac
		export TEXTDOMAIN=$TEXTDOMAIN_original
		exit
esac


#
# Commands
#

case " $(GET) " in
*\ start_pstn\ *)

echo 'DEVICE="'$(GET dial_modem)'"
PHONE="'$(GET phone)'"
USERNAME="'$(GET user)'"
PASSWORD="'$(GET pass)'"
BAUDRATE="'$(GET pstn_baud)'"' > /etc/dialup.conf

 . /etc/dialup.conf
 
    if [ "$(which wvdial)" != "" ]; then
	 dpid="$(busybox ps x | grep "wvdial" | grep -v "grep" | awk '/DialUp1/{print $1}')"
	 
	 if [ "$dpid" != "" ]; then
	  kill $dpid 2>/dev/null
	 fi
	fi
	
	dpid="$(busybox ps x | grep "pppd" | grep -v "grep" | awk '/dialup/{print $1}')"
     if [ "$dpid" != "" ]; then
	  kill $dpid 2>/dev/null
	 fi

	if [ "$(which wvdial)" != "" ]; then
	 pstn_wvdial
	else
	 pstn_ppp
	 sleep 1
	fi	

;;
*\ start_gsm\ *)
    
    dpid="$(busybox ps x | grep "pppd" | grep -v "grep" | awk '/gsm/{print $1}')"
     
     if [ "$dpid" != "" ]; then
	  kill $dpid 2>/dev/null
	 fi

	generate_gsm_conf
	pppd call gsm
 ;;
*\ stop_pstn\ *)

    if [ "$(which wvdial)" != "" ]; then
	 dpid="$(busybox ps x | grep "wvdial" | grep -v "grep" | awk '/DialUp1/{print $1}')"
	 
	 if [ "$dpid" != "" ]; then
	  kill $dpid 2>/dev/null
	 fi
	fi
	
	 dpid="$(busybox ps x | grep "pppd" | grep -v "grep" | awk '/dialup/{print $1}')"
     if [ "$dpid" != "" ]; then
	  kill $dpid 2>/dev/null
	 fi
	;;
*\ stop_gsm\ *)
	
	unset DEVICE

	if [ -f /etc/gprs.conf ]; then
	 . /etc/gprs.conf 
	fi
	
	dpid="$(busybox ps x | grep "pppd" | grep -v "grep" | awk '/gsm/{print $1}')"
     
     if [ "$dpid" != "" ]; then
	  kill $dpid 2>/dev/null
	 fi

	/etc/ppp/scripts/ppp-off

;;	
*\ start_pppoe\ *)
	if [ "$(GET user)" ]; then
		set_secrets "$(GET user)" "$(GET pass)"
		grep -qs pppoe /etc/ppp/options || cat > /etc/ppp/options <<EOT
plugin rp-pppoe.so
noipdefault
defaultroute
mtu 1492
mru 1492
lock
EOT
		sed -i 's/^name /d' /etc/ppp/options
		echo "name $(GET user)" >> /etc/ppp/options
		( . /etc/network.conf ; pppd $INTERFACE & )
	fi ;;
*\ stop_pppoe\ *)
	killall pppd ;;
*\ setpppssh\ *)
	cat > /etc/ppp/pppssh <<EOT
PEER="$(GET peer)"
SSHARG="$(GET ssharg)"
LOCALIP="$(GET localip)"
REMOTEIP="$(GET remoteip)"
LOCALPPP="$(GET localpppopt)"
REMOTEPPP="$(GET remotepppopt)"
ROUTES="$(GET routes)"
UDP="$(GET udp)"
EOT
	[ "$(GET pass)" ] && export DROPBEAR_PASSWORD="$(GET pass)"
	case " $(GET) " in
	*\ send_key\ *)
		( dropbearkey -y -f /etc/dropbear/dropbear_rsa_host_key ;
		  cat /etc/ssh/ssh_host_rsa_key.pub ) 2> /dev/null | \
		grep ^ssh | dbclient $(echo $(GET send_key) | sed \
		's/.*\([A-Za-z0-9_\.-]*\).*/\1/') "mkdir .ssh 2> /dev/null ; \
		while read key; do for i in authorized_keys authorized_keys2; do \
		grep -qs '\$key' .ssh/\$i || echo '\$key' >> .ssh/\$i ; done ; done ; \
		chmod 700 .ssh ; chmod 600 .ssh/authorized_keys*"
		;;
	*\ stop_pppssh\ *)
		ppp="$(sed '/pppd/!d;s/.*="\([^"]*\).*/\1/' /usr/bin/pppssh)"
		kill $(busybox ps x | grep "$ppp" | awk '/pty/{next}/dbclient/{print $1}')
		;;
	*\ start_pppssh\ *)
EOT
		pppssh	"$(GET ssharg) $(GET peer)" \
			"$(GET localip):$(GET remoteip) $(GET localpppopt)" \
			"$(GET remotepppopt)" "$(GET routes)" "$(GET udp)" &
		;;
	esac
	;;
esac

USERNAME="$(sed '/^name/!d;s/^[^ ]* *//' /etc/ppp/options)"
PASSWORD="$(awk -v key=$USERNAME "\$1==key{print \$3}" /etc/ppp/pap-secrets)"
ACCOUNT="$(sed '/^ACCOUNT=/!d;s/^.*=\([^ \t]*\).*/\1/' /etc/ppp/scripts/ppp-on)"
PASSPSTN="$(sed '/^PASSWORD=/!d;s/^.*=\([^ \t]*\).*/\1/' /etc/ppp/scripts/ppp-on)"
PHONE="$(sed '/^TELEPHONE=/!d;s/^.*=\([^ \t]*\).*/\1/' /etc/ppp/scripts/ppp-on)"
TITLE="$(_ 'TazPanel - Network') - $(_ 'PPP Connections')"
header
xhtml_header | sed 's/id="content"/id="content-sidebar"/'
cat << EOT
<div id="sidebar">
<section>
	<header>
		$(_ 'Documentation')
	</header>
		<a data-icon="web" href="http://ppp.samba.org/" target="_blank" rel="noopener">$(_ 'PPP web page')</a><p>
		<a data-icon="help" href="index.cgi?exec=pppd%20--help" target="_blank" rel="noopener">$(_ 'PPP help')</a><p>
		<a data-icon="help" href="index.cgi?exec=man%20pppd" target="_blank" rel="noopener">$(_ 'PPP Manual')</a><p>
		<a data-icon="web" href="https://en.wikipedia.org/wiki/Hayes_command_set" target="_blank" rel="noopener">$(_ 'Hayes codes')</a><p>
EOT
[ "$(which pptp 2>/dev/null)" ] && cat <<EOT
		<a data-icon="web" href="http://pptpclient.sourceforge.net/" target="_blank" rel="noopener">$(_n 'PPTP web page')</a><p>
		<a data-icon="help" href="index.cgi?exec=pptp" target="_blank" rel="noopener">$(_ 'PPTP Help')</a><p>
EOT
[ "$(which pptpd 2>/dev/null)" ] && cat <<EOT
		<a data-icon="web" href="http://poptop.sourceforge.net/" target="_blank" rel="noopener">$(_n 'PPTPD web page')</a><p>
		<a data-icon="help" href="index.cgi?exec=pptpd%20--help" target="_blank" rel="noopener">$(_ 'PPTPD Help')</a><p>
EOT
[ "$(which pppssh 2>/dev/null)" ] && cat <<EOT
		<a data-icon="web" href="http://doc.slitaz.org/en:guides:vpn" target="_blank" rel="noopener">$(_n 'VPN Wiki')</a><p>
		<a data-icon="help" href="index.cgi?exec=dbclient" target="_blank" rel="noopener">$(_ 'SSH Help')</a><p>
EOT
cat << EOT
	<footer>
	</footer>
</section>
<section>
	<header>
		$(_ 'Configuration')
	</header>
EOT

cat << EOT
		<a data-icon="conf" href="index.cgi?file=/etc/ppp/scripts/ppp-on" target="_blank" rel="noopener">$(_ 'PPP PSTN script')</a><p>
		<a data-icon="conf" href="index.cgi?file=/etc/ppp/scripts/ppp-on-dialer" target="_blank" rel="noopener">$(_ 'PPP PSTN chat')</a><p>
		<a data-icon="conf" href="index.cgi?file=/etc/ppp/options" target="_blank" rel="noopener">$(_ 'PPP PSTN options')</a><p>
		<a data-icon="conf" href="index.cgi?file=/etc/ppp/chap-secrets" target="_blank" rel="noopener">$(_ 'chap users')</a><p>
		<a data-icon="conf" href="index.cgi?file=/etc/ppp/pap-secrets" target="_blank" rel="noopener">$(_ 'pap users')</a><p>
EOT

for i in /etc/ppp/peers/* ; do
	[ -s "$i" ] && [ "$i" != "/etc/ppp/peers/gsm" ] && [ "$i" != "/etc/ppp/peers/dialup" ] && cat << EOT
		<a data-icon="conf" href="index.cgi?file=$i" target="_blank" rel="noopener">$(basename $i)</a><p>
EOT
done

[ "$(which pptpd 2>/dev/null)" ] && cat <<EOT
		<a data-icon="conf" href="index.cgi?file=/etc/pptpd.conf" target="_blank" rel="noopener">$(_ 'pptpd.conf')</a><p>
EOT

if [ ! -w /etc/network.conf ] ; then 
 start_disabled='disabled'; stop_disabled='disabled'
else
 start_disabled=''; stop_disabled=''
	if [ "$(busybox ps x | grep "pppd" | grep -v "grep" |  awk '/modem/{print $1}')" != "" ]; then
		start_disabled='disabled'
	else
		stop_disabled='disabled'
	fi
fi

if [ ! -w /etc/network.conf ] ; then 
 startoe_disabled='disabled'; stopoe_disabled='disabled'
else
 startoe_disabled=''; stopoe_disabled=''
	if [ "$(busybox ps x | grep "pppd" | grep -v "grep" |  awk '/eth/{print $1}')" != "" ]; then
		startoe_disabled='disabled'
	else
		stopoe_disabled='disabled'
	fi
fi

if [ ! -w /etc/network.conf ] ; then 
	startgsm_disabled='disabled'; stopgsm_disabled='disabled'
else
    startgsm_disabled=''; stopgsm_disabled=''
	if [ "$(busybox ps x | grep "pppd" | grep -v "grep" | awk '/gsm/{print $1}')" != "" ]; then
		startgsm_disabled='disabled'
		stopgsm_disabled=''
	else
	    startgsm_disabled=''
		stopgsm_disabled='disabled'
	fi
fi

if [ ! -w /etc/network.conf ] ; then 
 startpstn_disabled='disabled'; stoppstn_disabled='disabled'
else
 startpstn_disabled=''; stoppstn_disabled=''
    if [ "$(which wvdial)" != "" ]; then
		if [ "$(busybox ps x | grep "wvdial" | grep -v "grep" | awk '/DialUp1/{print $1}')" != "" ]; then
		 startpstn_disabled='disabled'
		 stoppstn_disabled=''
		else
		 startpstn_disabled=''
		 stoppstn_disabled='disabled'
		fi
	else
	  if [ "$(busybox ps x | grep "pppd" | grep -v "grep" | awk '/dialup/{print $1}')" != "" ]; then
		startpstn_disabled='disabled'
		stoppstn_disabled=''
	  else
	    startpstn_disabled=''
		stoppstn_disabled='disabled'
	  fi
	fi
fi

head="	<footer>
	</footer>
</section>
<section>
	<header>
		$(_ 'Install extra')
	</header>"
while read file pkg name ; do
	[ -z "$(which $file 2>/dev/null)" ] && echo $head && head="" &&
	echo "	<a href='pkgs.cgi?do=Install&amp;pkg=$pkg'>$name</a>"
done <<EOT
sdptool	bluez		GSM / Bluetooth
pppssh	dropbear	SSH / VPN
EOT
#pptp	pptpclient	PPTP client
#pptpd	poptop		PPTP server
cat << EOT
	<footer>
	</footer>
</section>
</div>

EOT

DETECTED=""

	if [ "$(which get_modem_alternate_device)" != "" ]; then
	 DETECTED="$(get_modem_alternate_device ALL | sed -e '/^$/ d' -e 's%^%/dev/%')"
	fi
	
	if [ -e /dev/gsmmodem ]; then
		if [ -L /dev/gsmmodem ]; then
		 DM="$(readlink /dev/gsmmodem)"
		 if [ "$DETECTED" == "" ]; then
		  DETECTED="/dev/gsmmodem"
		 else
		  if [ "$(echo "$DETECTED" | grep "/dev/gsmmodem")" == "" ]; then
		   DETECTED="$DETECTED /dev/gsmmodem"
		  fi
		 fi
		elif [ -b /dev/gsmmodem ]; then
		 if [ "$DETECTED" == "" ]; then
		  DETECTED="/dev/gsmmodem"
		 else
		  if [ "$(echo "$DETECTED" | grep "/dev/gsmmodem")" == "" ]; then
		   DETECTED="$DETECTED /dev/gsmmodem"
		  fi
		 fi
		fi
	fi
	
	for MAINDEV in $(ls /dev/ttyACM* /dev/ttyHS* /dev/ttyUSB* /dev/rfcomm* 2>/dev/null)
	do
	  if [ "$DETECTED" != "" ]; then
	   DETECTED="$MAINDEV"
	  else
	   if [ "$(echo "$DETECTED" | grep "$MAINDEV")" == "" ]; then
	    DETECTED="$DETECTED $MAINDEV"
	   fi
	  fi
	done
	
cat <<EOT
<a name="pppgprs3g"></a>
<section>
	<header>
		<span data-icon="modem">$(_ 'GSM/GPRS/3G modem') -
		$(_ 'Manage Cellular Internet connections')</span>
	</header>
EOT
	
if [ "$(which pppd)" != "" ] && [ "$DETECTED" != "" ]; then

if [ "$(which tazmodem)" == "" ]; then

	cat <<EOT
<form method="get">
	<input type="hidden" name="setpppgprs3g" />
	<table>
EOT

cat <<EOT
	<tr>
		<td>$(_ 'Modem')</td>
EOT

 if [ -f /etc/gprs.conf ]; then
	. /etc/gprs.conf
 fi

	echo '<td>
	<select name="gprs3gdev" required>'
	
	for devs in $DETECTED
	do
		if [ "$devs" == "$DEVICE" ]; then
		 xs=' selected="selected"'
		else
		 xs=""
		fi
	    echo '<option value="'$devs'"'$xs'>'$devs'</option>'
	done
	
	echo '</select>
	</td>
	</tr>'

echo '
	<tr>
		<td>'$(_ 'Access Point')'</td>
		<td><input type="text" name="gprs3gapn" size="40" value="'$APN'" required/></td>
	</tr>
 '
	
cat <<EOT
	<tr>
		<td>$(_ 'Access Number')</td>
EOT

    echo '<td>
    <select name="gprs3gnum" required>'
	
	for dials in "*99#" "#777" "*99***#" "*99***1#" "*99***2#" "*99***3#" "*99***4#"
	do
		if [ "$dials" == "$NUMBER" ]; then
		 xs=' selected="selected"'
		else
		 xs=""
		fi
	    echo '<option value="'$dials'"'$xs'>'$dials'</option>'
	done
	
	echo '</select>
	</td>
	</tr>'
	
	cat <<EOT
	<tr>
		<td>$(_ 'Authentication')</td>
EOT
	
	echo '<td>
    <select name="gprs3gauth" required>'
	
	for auths in "EAP" "CHAP" "MSCHAP" "PAP" "NONE"
	do
		if [ "$auths" == "$AUTH" ]; then
		 xs=' selected="selected"'
		else
		 xs=""
		fi
	    echo '<option value="'$auths'"'$xs'>'$auths'</option>'
	done
	
	echo '</select>
	</td>
	</tr>'

cat <<EOT
	<tr>
		<td>$(_ 'Username')</td>
		<td><input type="text" name="gprs3guser" size="40" value="$USERNAME" /></td>
	</tr>
	<tr>
		<td>$(_ 'Password')</td>
		<td><input type="password" name="gprs3gpwd" size="40" value="$PASSWORD" /></td>
	</tr>
	<tr>
		<td>$(_ 'Phone PIN')</td>
		<td><input type="password" name="gprs3pin" size="40" value="$PIN" /></td>
	</tr>
	</table>
	<footer><!--
		--><button type="submit" name="start_gsm" data-icon="start" $startgsm_disabled>$(_ 'Start'  )</button><!--
		--><button type="submit" name="stop_gsm"  data-icon="stop"  $stopgsm_disabled>$(_ 'Stop'   )</button><!--
	-->$(phone_names)</footer>
</form>

EOT

unset USERNAME PASSWORD NUMBER PIN

else
 echo "<br>&nbsp;&nbsp;Use TazModem to connect via GSM modem<br>&nbsp;"
fi

else
 
 if [ "$DETECTED" == "" ]; then
  echo "<br>&nbsp;&nbsp;No cellular modems found<br>&nbsp;"
 else
  echo "
  <br>&nbsp;&nbsp;Cellular modems found but it requires ppp to use it<br>
  &nbsp;&nbsp;<a href='pkgs.cgi?do=Install&amp;pkg=ppp'>Install ppp</a><br>&nbsp;"
 fi

fi

echo "</section>"

	if [ -e /dev/modem ]; then
		if [ -L /dev/modem ]; then
		 mDETECT="$(readlink /dev/modem)"
		elif [ -b /dev/modem ]; then
		 mDETECT="/dev/modem"
		fi
	fi

	for MAINDEV in $(ls /dev/ttyACM* /dev/ttyAGS* /dev/ttyHS* /dev/ttyUSB* /dev/ttyS* /dev/ttyLT* /dev/ttyI* /dev/rfcomm* 2>/dev/null)
	do
	  if [ "$mDETECT" != "" ]; then
	   mDETECT="$MAINDEV"
	  else
	   mDETECT="$mDETECT $MAINDEV"
	  fi
	done



cat << EOT
<a name="ppppstn"></a>
<section>
	<header>
		<span data-icon="modem">$(_ 'Dial-up modem') -
		$(_ 'Manage Dial-up Internet connections')</span>
	</header>
EOT

if [ "$mDETECT" != "" ]; then

if [ "$(which gnome-ppp)" == "" ]; then

cat << EOT
<form action="index.cgi" id="indexform"></form>
<form method="get">
	<input type="hidden" name="setppppstn" />
	<table>
EOT

cat <<EOT
	<tr>
		<td>$(_ 'Modem')</td>
EOT

 if [ -f /etc/dialup.conf ]; then
  . /etc/dialup.conf
 fi

	echo '<td>
	<select name="dial_modem" required>'
	
	for devs in $mDETECT
	do
		if [ "$devs" == "$DEVICE" ]; then
		 xs=' selected="selected"'
		else
		 xs=""
		fi
	    echo '<option value="'$devs'"'$xs'>'$devs'</option>'
	done
	
	echo '</select>
	</td>
	</tr>'




	cat <<EOT
	<tr>
		<td>$(_ 'Baud Rate')</td>
EOT
	
	echo '<td>
    <select name="pstn_baud" required>'
	
	for bauds in "7200" "9600" "14400" "28800" "38400" "57600" "115200" "230400" "460800"
	do
		if [ "$bauds" == "$BAUDRATE" ]; then
		 xs=' selected="selected"'
		else
		 xs=""
		fi
	    echo '<option value="'$bauds'"'$xs'>'$bauds'</option>'
	done
	
	echo '</select>
	</td>
	</tr>'

cat <<EOT
	<tr>
		<td>$(_ 'Phone number')</td>
		<td><input type="text" name="phone" size="40" value="$PHONE" required/></td>
	</tr>
	<tr>
		<td>$(_ 'Username')</td>
		<td><input type="text" name="user" size="40" value="$USERNAME" /></td>
	</tr>
	<tr>
		<td>$(_ 'Password')</td>
		<td><input type="password" name="pass" size="40" value="$PASSWORD" /></td>
	</tr>
	</table>
	<footer><!--
		--><button type="submit" name="start_pstn" data-icon="start" $startpstn_disabled>$(_ 'Start'  )</button><!--
		--><button type="submit" name="stop_pstn"  data-icon="stop"  $stoppstn_disabled >$(_ 'Stop'   )</button><!--
	--></footer>
</form>
EOT

unset PHONE USERNAME PASSWORD

else
 echo "<br>&nbsp;&nbsp;Use Gnome-PPP to connect via dial-up<br>&nbsp;"
fi

else
 echo "<br>&nbsp;&nbsp;No dialup modems found<br>&nbsp;"
fi

echo "</section>"

cat << EOT
<a name="pppoe"></a>
<section>
	<header>
		<span data-icon="eth">$(_ 'Cable Modem') -
		$(_ 'Manage PPPoE Internet connections')</span>
	</header>
<form method="get">
	<input type="hidden" name="setpppoe" />
	<table>
	<tr>
		<td>$(_ 'Username')</td>
		<td><input type="text" name="user" size="40" value="$USERNAME" /></td>
	</tr>
	<tr>
		<td>$(_ 'Password')</td>
		<td><input type="password" name="pass" size="40" value="$PASSWORD" /></td>
	</tr>
	</table>
	<footer><!--
		--><button type="submit" name="start_pppoe" data-icon="start" $startoe_disabled>$(_ 'Start'  )</button><!--
		--><button type="submit" name="stop_pppoe"  data-icon="stop"  $stopoe_disabled >$(_ 'Stop'   )</button><!--
	--></footer>
</form>
</section>
EOT

if [ "$(which pppssh 2>/dev/null)" ]; then
	[ -s /etc/ppp/pppssh ] && . /etc/ppp/pppssh
	ppp="$(sed '/pppd/!d;s/.*="\([^"]*\).*/\1/' /usr/bin/pppssh)"
	
   if [ ! -w /etc/network.conf ] ; then 
      startssh_disabled='disabled'; stopssh_disabled='disabled'
   else
	 if [ "$(busybox ps x | grep "$ppp" | awk '/dbclient/{print $1}')" ]; then
		startssh_disabled='disabled'
	 else
		stopssh_disabled='disabled'
	 fi
   fi
   	
	cat <<EOT
<a name="pppssh"></a>
<section>
	<header>
		<span data-icon="vpn">$(_ 'Virtual Private Network') -
		$(_ 'Manage private TCP/IP connections')</span>
	</header>
<form method="get">
	<input type="hidden" name="setpppssh" />
	<table>
	<tr>
		<td>$(_ 'Peer')</td>
		<td><input type="text" name="peer" size="50" value="${PEER:-user@elsewhere}" /></td>
	</tr>
	<tr>
		<td>$(_ 'SSH options')</td>
		<td><input type="text" name="ssharg" size="50" value="$SSHARG" /></td>
	</tr>
	<tr>
		<td>$(_ 'Password')</td>
		<td><input type="password" name="pass" size="50" title="Should be empty to use the SSH key; useful to send the SSH key only" /></td>
	</tr>
	<tr>
		<td>$(_ 'Local IP address')</td>
		<td><input type="text" name="localip" size="50" value="${LOCALIP:-192.168.254.1}" /></td>
	</tr>
	<tr>
		<td>$(_ 'Remote IP address')</td>
		<td><input type="text" name="remoteip" size="50" value="${REMOTEIP:-192.168.254.2}" /></td>
	</tr>
	<tr>
		<td>$(_ 'Local PPP options')</td>
		<td><input type="text" name="localpppopt" size="50" value="$LOCALPPP" /></td>
	</tr>
	<tr>
		<td>$(_ 'Remote PPP options')</td>
		<td><input type="text" name="remotepppopt" size="50" value="${REMOTEPPP:-proxyarp}" title="$(_ "You may need 'proxyarp' to use the new routes")" /></td>
	</tr>
	<tr>
		<td>$(_ 'Peer routes')</td>
		<td><input type="text" name="routes" size="50" value="${ROUTES:-192.168.10.0/24 192.168.20.0/28}" title="$(_ "Routes on peer network to import or 'default' to redirect the default route")"/></td>
	</tr>
	<tr>
		<td>$(_ 'UDP port')</td>
		<td><input type="text" name="udp" size="50" value="$UDP" title="$(_ "Optional UDP port for a real-time but unencrypted link")"/></td>
	</tr>
	</table>
	<footer><!--
		--><button type="submit" name="start_pppssh" data-icon="start" $startssh_disabled>$(_ 'Start'  )</button><!--
		--><button type="submit" name="stop_pppssh"  data-icon="stop"  $stopssh_disabled>$(_ 'Stop'   )</button><!--
		--><button type="submit" name="send_key"  data-icon="sync"  >$(_ 'Send SSH key'   )</button><!--
	--></footer>
</form>
</section>
EOT
fi

xhtml_footer
exit 0
