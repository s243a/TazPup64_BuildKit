#!/bin/sh
#
# Network configuration CGI interface
#
# Copyright (C) 2012-2015 SliTaz GNU/Linux - BSD License
#
# Modified by mistfire for TazPuppy

. ./lib/libtazpanel
get_config
header
TITLE=$(_ 'Network')
ip_forward=/proc/sys/net/ipv4/ip_forward

if [ ! -d /etc/network-config ]; then
 mkdir /etc/network-config
fi

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

start_wifi() {
sed -i -e 's|^WIFI=.*|WIFI="yes"|' /etc/network.conf
. /etc/network.conf
. /etc/network-config/$WIFI_INTERFACE.conf
ifconfig $WIFI_INTERFACE up
iwconfig $WIFI_INTERFACE txpower auto
/etc/init.d/network.sh restart "" $WIFI_INTERFACE | log

for i in $(seq 5); do
[ -n "$(iwconfig 2>/dev/null | fgrep Link)" ] && break
sleep 1
done
}

stop_wifi() {
. /etc/network.conf
/etc/init.d/network.sh stop "" $WIFI_INTERFACE | log
sleep 1
}

set_wlan_interface(){
INTF="$1"
sed -i -e 's|^WIFI_INTERFACE=.*|WIFI_INTERFACE="'$INTF'"|' /etc/network.conf
. /etc/network.conf	
}

start_eth() {

for eth10 in $xETH
do
/etc/init.d/network.sh start "" $eth10 | log
sleep 1
done

}

stop_eth() {

for eth10 in $xETH
do
 /etc/init.d/network.sh stop "" $eth10 | log
done

}


parse_wpa_conf() {
awk '
BEGIN { print "networks = ["; begin_list = 1; network = 0; }
{
if ($0 == "network={") {
if (begin_list == 0) print ",";
begin_list = 0;
printf "{"; begin_obj = 1;
network = 1; next;
}
if (network == 1) {
if ($0 ~ "=") {
if (begin_obj == 0) printf ", ";
begin_obj = 0;
split($0, a, "="); variable = a[1];
value = gensub(variable "=", "", "");
value = gensub("\\\\", "\\\\",    "g", value);
value = gensub("&",    "\\&amp;", "g", value);
value = gensub("<",    "\\&lt;",  "g", value);
value = gensub(">",    "\\&gt;",  "g", value);
value = gensub("\"",   "\\\"",    "g", value);
if (substr(value, 1, 2) == "\\\"")
value = substr(value, 3, length(value) - 4);
printf "%s:\"%s\"", variable, value;
}
}
if (network == 1 && $0 ~ "}") { printf "}"; network = 0; next; }
}
END {print "\n];"}
' /etc/wpa/wpa.conf | sed 's|\t||g;'
}

wait_up() {
for i in $(seq 5); do
if [ -z "$(cat /sys/class/net/*/operstate 2>/dev/null | fgrep up)"] || [ -z "$(cat /sys/class/net/*/operstate 2>/dev/null | fgrep unknown)"]; then
 sleep 1
fi
done
}

wait_down() {
for i in $(seq 5); do
if [ -z "$(cat /sys/class/net/*/operstate 2>/dev/null | fgrep down)"]; then
 sleep 1
fi
done
}

select_if() {
echo '<select name="interface">'
for i in $(ls /sys/class/net); do
grep -qs 1 /sys/class/net/$i/carrier &&
echo "<option>$i"
done
echo '</select>'
}

case " $(GET) " in
*\ start\ *)
/etc/init.d/network.sh start | log
wait_up
;;
*\ stop\ *)
/etc/init.d/network.sh stop | log
#wait_down
;;
*\ restart\ *)
/etc/init.d/network.sh restart | log
wait_up;;
*\ apply_wlan\ *)
 
	case "$(GET staticip)" in
     on) STATIC='yes';;
     *)  STATIC='no';;
	esac

	ITF="$(GET iface)"
	
	sed -i -e "s|^WIFI_INTERFACE=.*|WIFI_INTERFACE=\"$ITF\"|" /etc/network.conf
	. /etc/network.conf

	sed -i \
	-e "s|^STATIC=.*|STATIC=\"$STATIC\"|" \
	-e "s|^IP=.*|IP=\"$(GET ip)\"|" \
	-e "s|^NETMASK=.*|NETMASK=\"$(GET netmask)\"|" \
	-e "s|^GATEWAY=.*|GATEWAY=\"$(GET gateway)\"|" \
	-e "s|^DNS_SERVER=.*|DNS_SERVER=\"$(GET dns)\"|" \
	-e "s|^METRICS=.*|METRICS=\"$(GET metrics)\"|" \
	/etc/network-config/$ITF.conf
	
	. /etc/network-config/$ITF.conf

    start_wifi;;


*\ apply_eth\ *)

	case "$(GET staticip)" in
     on) STATIC='yes';;
     *)  STATIC='no';;
	esac

	ITF="$(GET iface)"
	sed -i \
	-e "s|^INTERFACE=.*|INTERFACE=\"$ITF\"|" \
	/etc/network.conf
	. /etc/network.conf

	sed -i \
	-e "s|^STATIC=.*|STATIC=\"$STATIC\"|" \
	-e "s|^IP=.*|IP=\"$(GET ip)\"|" \
	-e "s|^NETMASK=.*|NETMASK=\"$(GET netmask)\"|" \
	-e "s|^GATEWAY=.*|GATEWAY=\"$(GET gateway)\"|" \
	-e "s|^DNS_SERVER=.*|DNS_SERVER=\"$(GET dns)\"|" \
	-e "s|^METRICS=.*|METRICS=\"$(GET metrics)\"|" \
	/etc/network-config/${ITF}.conf
	. /etc/network-config/${ITF}.conf

	/etc/init.d/network.sh stop "" $ITF | log
	sleep 2
	/etc/init.d/network.sh start "" $ITF | log

wait_up;;

*\ start_wifi\ *)
start_wifi;;
*\ start_eth\ *)
start_eth;;
*\ stop_eth\ *)
stop_eth;;
*\ dowakeup\ *)
mac="$(GET macwakup)"
unset pass
[ "$(GET macpass)" ] && pass="-p $(GET macpass)"
if [ "$mac" ]; then
ether-wake $(GET iface) $mac $pass
else
ether-wake -b $(GET iface) $pass
fi
;;
*\ hostname\ *)
hostname="$(GET hostname)"
echo $(_ 'Changed hostname: %s' "$hostname") | log
echo "$hostname"> /etc/hostname;;
*\ rmarp\ *)
arp -d $(urldecode "$(GET entry)");;
*\ addarp\ *)
arp -i $(GET interface) -s $(GET ip) $(GET mac);;
*\ proxyarp\ *)
arp -i $(GET interface) -Ds $(GET ip) $(GET interface) pub;;
*\ toggleipforward\ *)
echo $((1 - $(cat $ip_forward))) > $ip_forward;;
*\ delvlan\ *)
vconfig rem $(GET vlan);;
*\ addvlan\ *)
grep -q '^8021q ' /proc/modules || modprobe 8021q
vlan=$(GET if).$(GET id)
prio=$(GET priority)
[ -e /proc/net/vlan/$vlan ] || vconfig add ${vlan/./ }
for i in $(seq 0 7); do
vconfig set_ingress_map $vlan $i ${prio:-$i}
vconfig set_egress_map $vlan $i ${prio:-$i}
done;;
esac

case " $(POST) " in
*\ connect_wifi\ *)

. /etc/network.conf

/etc/init.d/network.sh stop | log
password="$(POST password)"
password="$(echo -n "$password" | sed 's|\\|\\\\|g; s|&|\\\&|g' | sed "s|'|'\"'\"'|g")"
sed -i \
-e "s|^WIFI_ESSID=.*|WIFI_ESSID=\"$(POST essid)\"|" \
-e "s|^WIFI_BSSID=.*|WIFI_BSSID=\"$(POST bssid)\"|" \
-e "s|^WIFI_KEY_TYPE=.*|WIFI_KEY_TYPE=\"$(POST keyType)\"|" \
-e "s|^WIFI_KEY=.*|WIFI_KEY='$password'|" \
-e "s|^WIFI_EAP_METHOD=.*|WIFI_EAP_METHOD=\"$(POST eap)\"|" \
-e "s|^WIFI_CA_CERT=.*|WIFI_CA_CERT=\"$(POST caCert)\"|" \
-e "s|^WIFI_CLIENT_CERT=.*|WIFI_CLIENT_CERT=\"$(POST clientCert)\"|" \
-e "s|^WIFI_IDENTITY=.*|WIFI_IDENTITY=\"$(POST identity)\"|" \
-e "s|^WIFI_ANONYMOUS_IDENTITY=.*|WIFI_ANONYMOUS_IDENTITY=\"$(POST anonymousIdentity)\"|" \
-e "s|^WIFI_PHASE2=.*|WIFI_PHASE2=\"$(POST phase2)\"|" \
/etc/network-config/$WIFI_INTERFACE.conf
. /etc/network.conf
. /etc/network-config/$WIFI_INTERFACE.conf
start_wifi
;;
*\ apply_proxy\ *)
sed -i \
-e "s|^HTTP_ENABLE=.*|HTTP_ENABLE=\"$(POST http_enabled)\"|" \
-e "s|^HTTP_PROXY_ADDRESS=.*|HTTP_PROXY_ADDRESS=\"$(POST http_proxy)\"|" \
-e "s|^HTTP_PROXY_PORT=.*|HTTP_PROXY_PORT=\"$(POST http_port)\"|" \
-e "s|^HTTP_USERNAME=.*|HTTP_USERNAME=\"$(POST http_user)\"|" \
-e "s|^HTTP_PASSWORD=.*|HTTP_PASSWORD=\"$(POST http_pass)\"|" \
-e "s|^HTTPS_ENABLE=.*|HTTPS_ENABLE=\"$(POST https_enabled)\"|" \
-e "s|^HTTPS_PROXY_ADDRESS=.*|HTTPS_PROXY_ADDRESS=\"$(POST https_proxy)\"|" \
-e "s|^HTTPS_PROXY_PORT=.*|HTTPS_PROXY_PORT=\"$(POST https_port)\"|" \
-e "s|^HTTPS_USERNAME=.*|HTTPS_USERNAME=\"$(POST https_user)\"|" \
-e "s|^HTTPS_PASSWORD=.*|HTTPS_PASSWORD=\"$(POST https_pass)\"|" \
-e "s|^FTP_ENABLE=.*|FTP_ENABLE=\"$(POST ftp_enabled)\"|" \
-e "s|^FTP_PROXY_ADDRESS=.*|FTP_PROXY_ADDRESS=\"$(POST ftp_proxy)\"|" \
-e "s|^FTP_PROXY_PORT=.*|FTP_PROXY_PORT=\"$(POST ftp_port)\"|" \
-e "s|^FTP_USERNAME=.*|FTP_USERNAME=\"$(POST ftp_user)\"|" \
-e "s|^FTP_PASSWORD=.*|FTP_PASSWORD=\"$(POST ftp_pass)\"|" \
/etc/proxy.conf

;;
esac

. /etc/network.conf

case " $(GET) " in
*\ scan\ *)
scan=$(GET scan); back=$(GET back)
xhtml_header
loading_msg "$(_ 'Scanning open ports...')"
cat <<EOT
<section>
<header>
$(_ 'Port scanning for %s' $scan)
$(back_button "$back" "$(_ 'Network')" "")
</header>
<pre>$(pscan -b $scan)</pre>
</section>
EOT

;;
*\ proxy\ *)

xhtml_header "$(_ 'Proxy Servers')"

. /etc/proxy.conf

case "$HTTP_ENABLE" in
on) http_use='checked';;
*)   http_use='';;
esac

case "$HTTPS_ENABLE" in
on) https_use='checked';;
*)   https_use='';;
esac

case "$FTP_ENABLE" in
on) ftp_use='checked';;
*)   ftp_use='';;
esac

cat <<EOT
<form action="network.cgi?proxy" method="post">
	<section>
		<header>
			<span>$(_ 'HTTP Proxy')</span>
		</header>
		<input type="checkbox" name="http_enabled" id="http_enabled" $http_use/>Enabled
		<table>
			<tr>
			<td>$(_ 'Proxy Address')</td>
			<td><input type="text" name="http_proxy" size="40" value="$HTTP_PROXY_ADDRESS"/></td>
		</tr>
		<tr>
			<td>$(_ 'Port Number')</td>
			<td><input type="number" name="http_port" size="40" value="$HTTP_PROXY_PORT"/></td>
		</tr>
		<tr>
			<td>$(_ 'Username')</td>
			<td><input type="text" name="http_user" size="40" value="$HTTP_USERNAME" /></td>
		</tr>
		<tr>
			<td>$(_ 'Password')</td>
			<td><input type="password" name="http_pass" size="40" value="$HTTP_PASSWORD" /></td>
		</tr>
		</table>
	</section>
	
	<section>
		<header>
			<span>$(_ 'HTTPS Proxy')</span>
		</header>
		<input type="checkbox" name="https_enabled" id="https_enabled" $https_use/>Enabled
		<table>
			<tr>
			<td>$(_ 'Proxy Address')</td>
			<td><input type="text" name="https_proxy" size="40" value="$HTTPS_PROXY_ADDRESS"/></td>
		</tr>
		<tr>
			<td>$(_ 'Port Number')</td>
			<td><input type="number" name="https_port" size="40" value="$HTTPS_PROXY_PORT" /></td>
		</tr>
		<tr>
			<td>$(_ 'Username')</td>
			<td><input type="text" name="https_user" size="40" value="$HTTPS_USERNAME" /></td>
		</tr>
		<tr>
			<td>$(_ 'Password')</td>
			<td><input type="password" name="https_pass" size="40" value="$HTTPS_PASSWORD" /></td>
		</tr>
		</table>
	</section>

	<section>
		<header>
			<span>$(_ 'FTP Proxy')</span>
		</header>
		<input type="checkbox" name="ftp_enabled" id="ftp_enabled" $ftp_use/>Enabled
		<table>
			<tr>
			<td>$(_ 'Proxy Address')</td>
			<td><input type="text" name="ftp_proxy" size="40" value="$FTP_PROXY_ADDRESS"/></td>
		</tr>
		<tr>
			<td>$(_ 'Port Number')</td>
			<td><input type="number" name="ftp_port" size="40" value="$FTP_PROXY_PORT" /></td>
		</tr>
		<tr>
			<td>$(_ 'Username')</td>
			<td><input type="text" name="ftp_user" size="40" value="$FTP_USERNAME" /></td>
		</tr>
		<tr>
			<td>$(_ 'Password')</td>
			<td><input type="password" name="ftp_pass" size="40" value="$FTP_PASSWORD" /></td>
		</tr>
		</table>
	</section>
	<br>
	<footer>
		 <button type="submit" name="apply_proxy" data-icon="start" >$(_ 'Apply')</button>
	</footer>
</form>
EOT

;;
*\ eth\ *)

xhtml_header "$(_ 'Ethernet connection')"
PAR1="size=\"20\" required"; PAR="$PAR1 pattern=\"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\""

stop_disabled=''; start_disabled=''

act1=0

if [ "$xETH" == "" ]; then

echo "<br><br><center>No network adapters found</center><br><br>"

else

for lan2 in $xETH
do
if [ "$(cat /sys/class/net/$lan2/operstate 2>/dev/null | grep "down")" != "" ]; then
  echo "" > /dev/null
else
  act1=`expr $act1 + 1`  
fi
done

echo $at1
  
  if [ $act1 -ne 0 ]; then 
   start_disabled='disabled'
  else
   stop_disabled='disabled'
  fi
  
if [ ! -w /etc/network.conf ]; then
 stop_disabled='disabled'; start_disabled='disabled'
fi

[ -s /etc/ethers ] || echo "#01:02:03:04:05:06 mystation"> /etc/ethers

if [ ! -e /sys/class/net/$INTERFACE ] || [ "$INTERFACE" == "" ]; then

TGL=""

for lan2 in $xETH
do
 if [ "$lan2" != "" ] && [ "$TGL" == "" ]; then
 TGL="$lan2"
  sed -i  -e "s|^INTERFACE=.*|INTERFACE=\"$lan2\"|"  /etc/network.conf 
  break
 fi
done

. /etc/network.conf 

fi

if [ ! -e /etc/network-config/$INTERFACE.conf ]; then
 cp -f /etc/wired-template.conf /etc/network-config/$INTERFACE.conf 
fi

. /etc/network-config/$INTERFACE.conf

case "$STATIC" in
yes) use_static='checked';;
*)   use_static='';;
esac

if [ -w /etc/network.conf ]; then

cat <<EOT

<p>$(_ "Here you can configure a wired connection using DHCP to \
automatically get a random IP or configure a static/fixed IP")</p>
<br>
Wired Networking
<button form="conf" type="submit" name="start_eth" data-icon="" $start_disabled>$(_ 'Start')</button>
<button form="conf" type="submit" name="stop_eth"      data-icon=""  $stop_disabled >$(_ 'Stop')</button>
<br>

<section>
<header>$(_ 'Configuration')</header>
<form action="index.cgi" id="indexform"></form>
<form id="conf">
<input type="hidden" name="eth"/>
<div>
<table>
<tr><td>$(_ 'Default interface')</td>
<td><select name="iface" value="$INTERFACE" type="submit" style="width:100%">
$(cd /sys/class/net; ls -1 | grep -v 'lo' | awk -viface="$INTERFACE" '{
sel = ($0 == iface) ? " selected":""
printf "<option value=\"%s\"%s>%s", $0, sel, $0
}')
</select></td>
</tr>
<tr><td>$(_ 'Static IP')</td>
<td><label><input type="checkbox" name="staticip" id="staticip" $use_static/>
$(_ 'Use static IP')</td>
</tr>
<tr id="st1"><td>$(_ 'IP address')</td>
<td><input type="text" name="ip"      value="$IP"         $PAR/></td>
</tr>
<tr id="st2"><td>$(_ 'Netmask')</td>
<td><input type="text" name="netmask" value="$NETMASK"    $PAR/></td>
</tr>
<tr id="st3"><td>$(_ 'Gateway')</td>
<td><input type="text" name="gateway" value="$GATEWAY"    $PAR/></td>
</tr>
<tr id="st4"><td>$(_ 'DNS server')</td>
<td><input type="text" name="dns"     value="$DNS_SERVER" $PAR/></td>
</tr>
<tr id="st5"><td>$(_ 'Metrics')</td>
<td><input type="number" name="metrics"  value="$METRICS" $PAR/></td>
</tr>
<tr><td>$(_ 'Wake up')</td>
<td><label><input type="checkbox" name="wakeup" id="wakeup" />
$(_ 'Wake up machines by network')</td>
</tr>
<tr id="wk1"><td>$(_ 'MAC address to wake up')</td>
<td><input type="text" name="macwakup" title="$(_ 'Leave empty for a general wakeup')" $PAR/><!--
--><button form="indexform" name="file" value="/etc/ethers" data-icon="">$(_ 'List')</button>
</td>
</tr>
<tr id="wk2"><td>$(_ 'MAC/IP address password')</td>
<td><input type="text" name="macpass" title="$(_ 'Optional')" $PAR/><!--
--><button form="indexform" name="exec" value="ether-wake --help" data-icon="">$(_ 'Help')</button>
</td>
</tr>
</table>
<button form="conf" type="submit" name="apply_eth" data-icon="">Apply</button>
<button id="wk3" form="conf" type="submit" name="dowakeup"  data-icon="" $stop_disabled >$(_ 'Wake up')</button>
</div>
</form>
<footer>
<!--
--></footer>
</section>
<script type="text/javascript">
function check_change() {
enabled = document.getElementById('staticip').checked;
for (i = 1; i < 5; i++) {
document.getElementById('st' + i).style.display = enabled ? '' : 'none';
}
enabled = document.getElementById('wakeup').checked;
for (i = 1; i < 4; i++) {
document.getElementById('wk' + i).style.display = enabled ? '' : 'none';
}
}
document.getElementById('staticip').onchange = check_change;
document.getElementById('wakeup').onchange = check_change;
check_change();
</script>
EOT

fi

for lan1 in $xETH
do
 cat <<EOT
<section>
<header>
$(_ 'Configuration file %s' $lan1 ; edit_button /etc/network-config/$lan1.conf)
</header>
EOT

cat <<EOT
<div>$(_ "These values are the ethernet settings in the main /etc/network-config/$lan1.conf configuration file")</div>
<pre>$(awk '{if($1 !~ "WIFI" && $1 !~ "#" && $1 != ""){print $0}}' /etc/network-config/$lan1.conf | syntax_highlighter conf)</pre>
</section>
EOT

done

fi

;;
*\ wifi_list\ *)
HIDDEN="$(_ '(hidden)')"

SCANNED_WIFI=""

if [ -d /sys/class/net/$WIFI_INTERFACE/wireless ]; then
ifconfig $WIFI_INTERFACE up
for i in $(iwlist $WIFI_INTERFACE scan | sed '/Cell /!d;s/.*Cell \([^ ]*\).*/Cell.\1/')
do
SCAN=$(iwlist $WIFI_INTERFACE scan last | sed "/$i/,/Cell/!d" | sed '$d')
BSSID=$(echo "$SCAN" | sed -n 's|.*Address: \([^ ]*\).*|\1|p')
CHANNEL=$(echo "$SCAN" | sed -n 's|.*Channel[:=]\([^ ]*\).*|\1|p')
QUALITY=$(echo "$SCAN" | sed -n 's|.*Quality[:=]\([^ ]*\).*|\1|p')
QUALITY_ICON="lvl$(( 5*${QUALITY:-0} ))"		# lvl0 .. lvl4, lvl5
case $QUALITY_ICON in
lvl0) QUALITY_ICON='';;
lvl1) QUALITY_ICON='';;
lvl2) QUALITY_ICON='';;
lvl3) QUALITY_ICON='';;
lvl4|lvl5) QUALITY_ICON='';;
esac
LEVEL=$(echo "$SCAN" | sed -n 's|.*Signal level[:=]\([^ ]*\).*|\1|p; s|-|−|')
ENCRYPTION=$(echo "$SCAN" | sed -n 's|.*Encryption key[:=]\([^ ]*\).*|\1|p')		# on/off
ESSID=$(echo "$SCAN" | sed -n 's|.*ESSID:"\([^"]*\).*|\1|p')
AUTH="$(echo "$SCAN" | sed -n 's|.*Authentication Suites[^:]*: *\(.*\)|\1|p')"
if [ -n "$(echo -n $AUTH | fgrep PSK)" ]; then
WIFI_KEY_TYPE='WPA'
elif [ -n "$(echo -n $AUTH | fgrep 802.1x)" ]; then
WIFI_KEY_TYPE='EAP'
else
WIFI_KEY_TYPE='NONE'
fi
if [ "$ENCRYPTION" == 'on' ]; then
ENC_SIMPLE=$(echo "$SCAN" | sed -n '/.*WPA.*/ s|.*\(WPA[^ ]*\).*|\1|p')
ENC_SIMPLE=$(echo $ENC_SIMPLE | sed 's| |/|')
ENC_ICON='' # high
if [ -z "$ENC_SIMPLE" ]; then
WIFI_KEY_TYPE='WEP'
ENC_SIMPLE='WEP'; ENC_ICON='' # middle
fi
else
WIFI_KEY_TYPE='NONE'
ENC_SIMPLE="$(_ 'None')"; ENC_ICON='' # low
fi
if  ifconfig $WIFI_INTERFACE | fgrep -q inet && \
iwconfig $WIFI_INTERFACE | fgrep -q "ESSID:\"$ESSID\""; then
status="$(_ 'Connected')"
else
status='---'
fi

CFG1="loadcfg('$ESSID', '$BSSID', '$WIFI_KEY_TYPE')"

SCANNED_WIFI=$SCANNED_WIFI'
<tr>
<td><a data-icon="" onclick="'$CFG1'">'${ESSID:-$HIDDEN}'</a></td>
<td><span data-icon="'$QUALITY_ICON'" title="Quality: '$QUALITY'">'$LEVEL' dBm</span></td>
<td>'$CHANNEL'</td>
<td><span data-icon="'$ENC_ICON'">'$ENC_SIMPLE'</span></td>
<td>'$status'</td>
</tr>
'

done
fi

if [ "$SCANNED_WIFI" != "" ]; then

cat <<EOT
<table class="wide center zebra">
<thead>
<tr>
<td>$(_ 'Name')</td>
<td>$(_ 'Signal level')</td>
<td>$(_ 'Channel')</td>
<td>$(_ 'Encryption')</td>
<td>$(_ 'Status')</td>
</tr>
</thead>
<tbody>
$SCANNED_WIFI
</tbody>
</table>
EOT

else

 echo '<div style="text-align: center;">No wifi networks found</span></div>'

fi

exit 0
;;
*\ netconfig\ *)
cat <<EOT
<section>
<header>
$(_ 'Configuration file'; edit_button /etc/network.conf)
</header>
<div>$(_ "These values are the ethernet settings in the main /etc/network.conf configuration file")</div>
<pre>$(cat /etc/network.conf | syntax_highlighter conf)</pre>
</section>
EOT
;;
*\ wifi\ *)
xhtml_header "$(_ 'Wireless connection')"

. /etc/network.conf

if [ "$xWLAN" != "" ]; then

start_disabled=''; stop_disabled=''

if iwconfig 2>/dev/null | grep -q 'Tx-Power=off'; then
 stop_disabled='disabled'
else 
 start_disabled='disabled'
fi

if [ -w /etc/network.conf ]; then
cat <<EOT

<form method="GET">
<input type="hidden" name="wifi"/>
Wireless Networking
<button name="start_wifi" data-icon=""   $start_disabled>$(_ 'Start')</button>
<button name="stop_wifi"       data-icon=""    $stop_disabled >$(_ 'Stop')</button>
</form>
<button name="scan_wifi" onclick="scan_wifi_async();" data-icon="" $stop_disabled >$(_ 'Scan')</button>

EOT
fi


fi



if [ "$xWLAN" != "" ]; then

if [ -w /etc/network.conf ]; then

if [ ! -e /sys/class/net/$WIFI_INTERFACE ] || [ "$WIFI_INTERFACE" == "" ]; then

TGL=""

for wlan2 in $xWLAN
do
 if [ "$wlan2" != "" ] && [ "$TGL" == "" ]; then
 TGL="$wlan2"
  sed -i  -e "s|^WIFI_INTERFACE=.*|WIFI_INTERFACE=\"$wlan2\"|"  /etc/network.conf 
  break
 fi
done

. /etc/network.conf 

fi

if [ ! -e /etc/network-config/$WIFI_INTERFACE.conf ]; then
 cp -f /etc/wireless-template.conf /etc/network-config/$WIFI_INTERFACE.conf 
fi


if [ -n "$start_disabled" ]; then
cat <<EOT
<section>
<header>Available WiFi Networks</header>
<section id="wifiList">
<div style="text-align: center;"><span data-icon="">$(_ 'Scanning wireless interface...')</span></div>
</section>
</section>

<script type="text/javascript">
function scan_wifi_async(){
document.getElementById("wifiList").innerHTML="<div style=\"text-align: center;\"><span data-icon=\"\">$(_ 'Scanning wireless interface...')<\/span><\/div>";
ajax('network.cgi?wifi_list', '1', 'wifiList');
$(parse_wpa_conf)
}
</script>

<script type="text/javascript">
ajax('network.cgi?wifi_list', '1', 'wifiList');
$(parse_wpa_conf)
</script>
EOT

WIFI_KEY_ESCAPED="$(echo -n "$WIFI_KEY" | sed 's|&|\&amp;|g; s|<|\&lt;|g; s|>|\&gt;|g; s|"|\&quot;|g')"
cat <<EOT
<section>
<header>$(_ 'Connection')</header>
<div>
<form method="POST" action="?wifi" id="connection">
<input type="hidden" name="connect_wifi"/>
<input type="hidden" name="bssid" id="bssid"/>
<table>
<tr><td>$(_ 'Network SSID')</td>
<td><input type="text" name="essid" value="$WIFI_ESSID" id="essid"/></td>
</tr>
<tr><td>$(_ 'Security')</td>
<td><select name="keyType" id="keyType">
<option value="NONE">$(_ 'None')</option>
<option value="WEP">WEP</option>
<option value="WPA">WPA/WPA2 PSK</option>
<option value="EAP">802.1x EAP</option>
</select>
</td>
</tr>
<tr class="eap">
<td><div>$(_ 'EAP method')</div></td>
<td><div><select name="eap" id="eap">
<option value="PEAP">PEAP</option>
<option value="TLS">TLS</option>
<option value="TTLS">TTLS</option>
<option value="PWD">PWD</option>
</select>
</div></td>
</tr>
<tr class="eap1">
<td><div>$(_ 'Phase 2 authentication')</div></td>
<td><div><select name="phase2" id="phase2">
<option value="none">$(_ 'None')</option>
<option value="pap">PAP</option>
<option value="mschap">MSCHAP</option>
<option value="mschapv2">MSCHAPV2</option>
<option value="gtc">GTC</option>
</select>
</div></td>
</tr>
<tr class="eap1">
<td><div>$(_ 'CA certificate')</div></td>
<td><div><input type="text" name="caCert" id="caCert"></div></td>
</tr>
<tr class="eap1">
<td><div>$(_ 'User certificate')</div></td>
<td><div><input type="text" name="clientCert" id="clientCert"></div></td>
</tr>
<tr class="eap">
<td><div>$(_ 'Identity')</div></td>
<td><div><input type="text" name="identity" id="identity"></div></td>
</tr>
<tr class="eap1">
<td><div>$(_ 'Anonymous identity')</div></td>
<td><div><input type="text" name="anonymousIdentity" id="anonymousIdentity"></div></td>
</tr>
<tr class="wep wpa eap">
<td><div>$(_ 'Password')</div></td>
<td><div>
<input type="password" name="password" value="$WIFI_KEY_ESCAPED" id="password"/>
<span data-img="" title="$(_ 'Show password')"
onmousedown="document.getElementById('password').type='text'; return false"
onmouseup="document.getElementById('password').type='password'"
onmouseout="document.getElementById('password').type='password'"
></span>
</div></td>
</tr>
</table>
</form>
</div>
<footer>
<button form="connection" type="submit" name="wifi" data-icon="">$(_ 'Configure')</button>
<button data-icon="" onclick="shareWiFi(); popup('popup_qr', 'show');">$(_ 'Share')</button>
</footer>
</section>
<script type="text/javascript">
function wifiSettingsChange() {
document.getElementById('connection').className = 
document.getElementById('keyType').value.toLowerCase() + ' ' + 
document.getElementById('eap').value.toLowerCase();
}
document.getElementById('keyType').onchange = wifiSettingsChange;
document.getElementById('eap').onchange = wifiSettingsChange;
document.getElementById('keyType').value = "$WIFI_KEY_TYPE"; wifiSettingsChange();
function shareWiFi() {
// S=<SSID>; T={WPA|WEP|nopass}; P=<password>; H=<hidden?>
// Escape ":" and ";" -> "\:" and "\;"
// No harm for regular networks marked as hidden
var text = "WIFI:" + 
"S:" + document.getElementById('essid').value.replace(/:/g, "\\\\:").replace(/;/g, "\\\\;") + ";" +
"T:" + document.getElementById('keyType').value.replace("NONE", "nopass") + ";" +
"P:" + document.getElementById('password').value.replace(/:/g, "\\\\:").replace(/;/g, "\\\\;") + ";" +
"H:true;" +
";";
document.getElementById('qrimg').title = text;
qr.image({
image: document.getElementById('qrimg'),
value: text,
size: 10
});
}
</script>
<div id="shader" class="hidden" onclick="popup('popup_qr', 'close');"></div>
<table id="popup_qr" class="hidden" onclick="popup('popup_qr', 'close')">
<tr>
<td style="text-align: center;">
<div id="popup_qr_inner">
<img id="qrimg"/><br/>
$(_ 'Share Wi-Fi network with your friends')
</div>
</td>
</tr>
</table>
EOT
fi

. /etc/network-config/$WIFI_INTERFACE.conf

case "$STATIC" in
yes) use_static='checked';;
*)   use_static='';;
esac

cat <<EOT
<section>
<header>$(_ 'Configuration')</header>
<form id="conf" method="GET">
<input type="hidden" name="wifi"/>
<div>
<p>$(_ "Here you can configure a wireless connection using DHCP to \
automatically get a random IP or configure a static/fixed IP")</p>
<table>
<tr><td>$(_ 'Default wifi interface')</td>
<td><select name="iface" value="$WIFI_INTERFACE" type="submit" style="width:100%">
$(echo "$xWLAN" | tr ' ' '\n' | awk -viface="$WIFI_INTERFACE" '{
sel = ($0 == iface) ? " selected":""
printf "<option value=\"%s\"%s>%s", $0, sel, $0
}')
</select></td>
</tr>
<tr><td>$(_ 'Static IP')</td>
<td><label><input type="checkbox" name="staticip" id="staticip" $use_static/>
$(_ 'Use static IP')</td>
</tr>
<tr id="st1"><td>$(_ 'IP address')</td>
<td><input type="text" name="ip"      value="$IP"         $PAR/></td>
</tr>
<tr id="st2"><td>$(_ 'Netmask')</td>
<td><input type="text" name="netmask" value="$NETMASK"    $PAR/></td>
</tr>
<tr id="st3"><td>$(_ 'Gateway')</td>
<td><input type="text" name="gateway" value="$GATEWAY"    $PAR/></td>
</tr>
<tr id="st4"><td>$(_ 'DNS server')</td>
<td><input type="text" name="dns"     value="$DNS_SERVER" $PAR/></td>
</tr>
<tr id="st5"><td>$(_ 'Metrics')</td>
<td><input type="number" name="metrics"  value="$METRICS" $PAR/></td>
</tr>
</table>
<button form="conf" type="submit" name="apply_wlan" data-icon="">Apply</button>
</div>
</form>
<footer>

<!--
--></footer>
</section>
<script type="text/javascript">
function check_change() {
enabled = document.getElementById('staticip').checked;
for (i = 1; i < 5; i++) {
document.getElementById('st' + i).style.display = enabled ? '' : 'none';
}
}
document.getElementById('staticip').onchange = check_change;
check_change();
</script>
EOT

fi

for wl in $xWLAN
do

cat <<EOT
<section>
<header>
$(_ 'Configuration file %s' $wl; edit_button /etc/network-config/$wl.conf)
</header>
EOT

 cat <<EOT
<div>$(_ "These values are the wifi settings in the main /etc/network-config/%s.conf configuration file" "$wl")</div>
<div style="overflow-y:scroll; height:153px;"><pre>$(cat /etc/network-config/$wl.conf | sed 's|WIFI_KEY=.*|WIFI_KEY="********"|' | syntax_highlighter conf)</pre></div>
</section>
EOT

done

 cat <<EOT
<section>
<header>$(_ 'Output of iwconfig')</header>
<pre>$(iwconfig)</pre>
</section>
EOT

else
echo "<br><br><center><h4>No wireless adapters found</h4></center><br><br>"
fi


;;
*)

xhtml_header "$(_ 'Manage network connections and services')"

stop_disabled=''; start_disabled=''

act1=0

for lan2 in $ALL_INTF
do
if [ "$(cat /sys/class/net/$lan2/operstate 2>/dev/null | grep "down")" != "" ]; then
  echo "" > /dev/null
else
   act1=`expr $act1 + 1`
fi
done

  if [ $act1 -ne 0 ]; then 
   start_disabled="disabled"
  else
   stop_disabled="disabled"
  fi


if [ "$xWLAN" == "" ]; then
wl_disabled='disabled'
else
wl_disabled=''
fi
  
if [ "$xETH" == "" ]; then
eth_disabled='disabled'
else
eth_disabled=''
fi

if [ ! -w '/etc/network.conf' ]; then
start_disabled='disabled'; stop_disabled='disabled'
fi 

cat <<EOT
<form action="index.cgi" id="indexform"></form>
<form id="mainform">
Network Service
<!--
--><button name="start"   data-icon=""   $start_disabled>$(_ 'Start')</button><!--
--><button name="stop"    data-icon=""    $stop_disabled >$(_ 'Stop')</button><!--
--><button name="restart" data-icon="" $stop_disabled >$(_ 'Restart')</button>
</form>
<div class="float-right"><!--
-->$(_ 'Configuration:')<!--
--><button form="indexform" name="file" value="/etc/network.conf" data-icon="">network.conf</button><!--
--><button form="mainform" name="eth" data-icon="" $eth_disabled>Ethernet</button><!--
--><button form="mainform" name="wifi" data-icon="" $wl_disabled>Wireless</button>
</div>
<section>
<header>$(_ 'Network interfaces')</header>
$(list_network_interfaces)
<footer>
<input form="mainform" type="checkbox" name="opt" value="ipforward" $(
[ "$REMOTE_USER" != 'root' ] && echo ' disabled' ;
[ $(cat $ip_forward) -eq 1 ] && echo ' checked')/>
EOT
_ 'forward packets between interfaces'
[ "$REMOTE_USER" == 'root' ] && cat <<EOT
<button form="mainform" name="toggleipforward" data-icon="">$(_ 'Change')</button>
EOT
cat <<EOT
</footer>
</section>
<section>
<header id="hosts">$(_ 'Hosts'; edit_button /etc/hosts)</header>
<span data-icon="">$(r=$(getdb hosts | wc -l); 
_p '%d record in the hosts DB' \
'%d records in the hosts DB' "$r" \
"$r")</span>
<pre class="scroll">$(getdb hosts | fgrep -v 0.0.0.0)</pre>
<footer>
<form action="hosts.cgi">
<button data-icon="" data-root>$(_ 'Configure')</button>
$(_ 'Use hosts file as Ad blocker')
</form>
</footer>
</section>
<section>
<header>$(_ 'Hostname')</header>
<footer>
EOT
if [ -w '/etc/hostname' ]; then
cat <<EOT
<form>
<input type="text" name="hostname" value="$(hostname)"/><!--
--><button type="submit" data-icon="">$(_ 'Change')</button>
</form>
EOT
else
cat /etc/hostname
fi
cat <<EOT
</footer>
</section>
EOT
devs="$(for i in $(sed '/:/!d;s/:.*//' /proc/net/dev); do
[ -e /proc/net/vlan/$i ] && continue
[ -e /sys/class/net/$i/flags ] || continue
[ $(($(cat /sys/class/net/$i/flags) & 0x1080)) -eq 4096 ] &&
echo $i
done)"
if [ "$REMOTE_USER" == "root" -a -n "$devs" ]; then
cat <<EOT
<section>
<header id="vlan">$(_ 'VLAN')</header>
<footer>
<form>
EOT
vlans="$(ls /proc/net/vlan/ 2> /dev/null | sed '/config/d')"
if [ -n "$vlans" ]; then
cat <<EOT
<table class="wide zebra center">
<thead>
<tr>
<td>$(_ 'Interface')</td>
<td>id</td>
<td>$(_ 'priority')</td>
</tr>
</thead>
<tbody>
EOT
for i in $vlans ; do
cat <<EOT
<tr>
<td><input type="radio" name="vlan" value="$i"/>$i</td>
<td>$(sed '/VID/!d;s/.*VID: \([^ ]*\).*/\1/' /proc/net/vlan/$i)</td>
<td>$(sed '/EGRESS/!d;s/.*: 0:\([^: ]*\).*/\1/' /proc/net/vlan/$i)</td>
<td></td>
</tr>
EOT
done
cat <<EOT
</tbody>
</table>
<button type="submit" data-icon="" name="delvlan">$(_ 'Remove')</button> $(_ 'or')
EOT
fi
cat <<EOT
<button type="submit" data-icon="" name="addvlan">$(_ 'Add')</button>
$(_ 'on') <select name="if"> 
$(for i in $devs; do echo "<option>$i</option>"; done)
</select> id
<input type="text" name="id" value="1" size="4" title="1..4095" />
$(_ 'priority') <select name="prio">
$(for i in $(seq 0 7); do echo "<option>$i</option>"; done)
</select>
</form>
</footer>
</section>
EOT
fi
cat <<EOT
<section>
<header id="ifconfig">$(_ 'Output of ifconfig')</header>
<pre>$(ifconfig)</pre>
</section>
<section>
<header id="routing">$(_ 'Routing table')</header>
<pre>$(route -n)</pre>
</section>
<section>
<header id="dns">$(_ 'Domain name resolution'; edit_button /etc/resolv.conf)</header>
<pre>$(cat /etc/resolv.conf)</pre>
</section>
<section>
<header id="arp">$(_ 'ARP table')</header>
EOT
if [ "$REMOTE_USER" == "root" ]; then
echo "<table>"
arp -n | while read line ; do
cat <<EOT
<form>
<tr><td>
<input type="hidden" name="entry" value="$(urlencode "$(echo $line | \
sed 's/) .* on/ -i/;s/.*(//')")">
<button type="submit" data-icon="" name="rmarp"></button>
</td><td><pre>$line</pre></td></tr>
</form>
EOT
done
cat <<EOT
</table>
<footer>
<form>
IP <input type="text" name="ip" value="10.20.30.40" size="12" /> $(_ 'on') $(select_if)<!--
--><button type="submit" data-icon="" name="proxyarp">$(_ 'Proxy')</button>
$(_ 'or') <button type="submit" data-icon="" name="addarp">$(_ 'Add')</button>
MAC <input type="text" name="mac" value="11:22:33:44:55:66" size="16" />
</form>
EOT
else
echo "<pre>$(arp -n)</pre>"
fi
cat <<EOT
</footer>
</section>
<section>
<header id="connections">$(_ 'IP Connections')</header>
<pre>$(netstat -anp 2>/dev/null | sed -e '/UNIX domain sockets/,$d' \
-e 's#\([0-9]*\)/#<a href="boot.cgi?daemons=pid=\1">\1</a>/#')</pre>
</section>
EOT
[ "$REMOTE_USER" == "root" -a "$(which iptables-save)" ] && cat <<EOT
<section>
<header id="iptables">$(_ 'Firewall')
$(edit_button /etc/knockd.conf "$(_ 'Port knocker')")
</header>
<pre>$(iptables-save)</pre>
</section>
EOT
;;
esac
xhtml_footer
exit 0
