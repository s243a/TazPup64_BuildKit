#!/bin/bash
#
# Hardware part of TazPanel - Devices, drivers, printing
#
# Copyright (C) 2011-2015 SliTaz GNU/Linux - BSD License
# modified by mistfire

. ./lib/libtazpanel
get_config
header
TITLE=$(_ 'Hardware')

set_bright(){

BR="$1"	
dev1="$2"

if [ $BR -gt 100 ]; then
 BR=100
fi

MAXBR=$(cat /sys/class/backlight/$dev1/max_brightness)
xNEWBR=`expr $MAXBR \* $BR`
NEWBR=`expr $xNEWBR / 100`

echo $NEWBR > "/sys/class/backlight/$dev1/brightness"

dvname=$(echo "$dev1" | sed -e "s# #---#g")

echo "[Desktop Entry]
Encoding=UTF-8
Type=Application
NoDisplay=true
Name=Screen Brightness ($dev1)
Exec=set-backlight $BR \"$dev1\"
" > /etc/xdg/autostart/SSB_$dev1.desktop

chmod 777 /etc/xdg/autostart/SSB_$dvname.desktop
	
}

lib() {
module=lib/$1
shift
[ -s $module ] && . $module "$@"
}

disk_info() {
fdisk -l | fgrep Disk | while read a b c; do
d=${b##*/}
t="HD"
[ "$(cat /sys/block/${d%:}/queue/rotational)" -eq "0" ] && t="SSD"
d="/sys/block/${d%:}/device"
[ -d $d ] && echo "$a $b $c, $t $(cat $d/vendor) $(cat $d/model)"
smartctl -a ${b%:} | sed '/^Model/,/^Firmware/!d'
done 2> /dev/null | sed 's/  */ /g'
}

lsusb_vd() {
if lsusb --help 2>&1 | grep -qi busybox ; then
for i in $(ls /sys/class/usb_device/*/device) ; do
grep -qs ${1%:*} $i/idVendor || continue
grep -qs ${1#*:} $i/idProduct || continue
( cd $i ; for j in * ; do
[ -f $j -a -r $j ] || continue
case "$j" in
descriptors|remove) continue
esac
awk -vn=$j '{printf "%-20s %s\n",n,$0;n=""}' <$j
done  )
break
done
else
lsusb -vd $1 | syntax_highlighter lsusb
fi
}

lsusb_table() {
cat <<EOT
<table class="wide zebra">
<thead>
<tr>
<td>$(_ 'Bus')</td>
<td>$(_ 'Device')</td>
<td>$(_ 'ID')</td>
<td>$(_ 'Name')</td>
</tr>
</thead>
<tbody>
EOT
lsusb | while read x b y d z id name ; do
echo "<tr><td>$b</td><td>${d%:}</td><td><a href=\"?lsusb=$id"
p=$(printf "class/usb_device/usbdev%d.%d" $b ${d%:})
grep -qs 0 /sys/$p/device/authorized && id="<del>$id</del>"
echo "\">$id</td><td>${name:-$(sed 's/ .*//' /sys/$p/device/manufacturer) $(cat /sys/$p/device/product)}</td></tr>"
done
echo "</tbody></table>"
}

lspci_table() {
cat <<EOT
<table class="wide zebra">
<thead><tr>
<td>$(_ 'Slot')</td>
<td>$(_ 'Device')</td>
<td>$(_ 'Name')</td>
</tr></thead>
<tbody>
EOT
lspci | while read a b c id ; do
if [ $b != "Class" ] || [ ! -s /usr/share/misc/pci.ids.gz ]; then
echo "X$a $b $c $id"
continue
fi
echo -n "$a "
zcat /usr/share/misc/pci.ids.gz | \
awk -va=${c:0:2} -vb=${c:2:2} -vh=${id:0:4} -vl=${id:5:4} '{
if ($1 == "C" && $2 == a) class=substr($0,5)
if (class != "" && $1 == b) { class=substr($0,5); exit }
if (substr($0,1,4) == h) m=substr($0,7)
else if (m == "") next
else if (substr($0,2,4) == l) { name=m substr($0,7); m="" }
else if ($1 == h && $2 == l) { name=m substr($0,14); m="" }
} END { print "[" a b "] " class ": [" h "/" l "] " name }'
done | sed 's| |</td><td>|;
s|: |</td><td>|;
s|^X\([^<]*\)|<a href="?lspci=\1">\1</a>|;
s|^.*$|<tr><td>\0</td></tr>|'
echo "</tbody></table>"
}

case " $(GET) " in
*\ print\ *)
xhtml_header
echo "<h2>TODO</h2>"
;;
*\ tazx\ *)
xhtml_header
cat <<EOT
<pre>$(tazx auto console)</pre>
EOT
;;
*\ detect\ *)
xhtml_header "$(_ 'Detect hardware')"
cat <<EOT
<p>$(_ 'Detect PCI and USB hardware')</p>
EOT
tazhw detect-pci | htmlize
tazhw detect-usb | htmlize | filter_taztools_msgs
;;
*\ modules\ *|*\ modinfo\ *)
xhtml_header "$(_ 'Kernel modules')"
search="$(GET search)"
cat <<EOT
<p>$(_ 'Manage, search or get information about the Linux kernel modules')</p>
<form class="search">
<input type="hidden" name="modules"/>
<input type="search" name="search" value="$search" placeholder="$(_ 'Modules search')" results="5" autosave="modsearch" autocomplete="on"/>
<button type="submit">$(_n 'Search')</button>
</form>
EOT
get_modinfo="$(GET modinfo)"
if [ -n "$get_modinfo" ]; then
cat <<EOT
<section>
<header>$(_ 'Detailed information for module: %s' $get_modinfo)</header>
<div class="scroll">
EOT
modinfo $get_modinfo | awk 'BEGIN{print "<table class=\"wide zebra\">"}
{
printf("<tr><td><b>%s</b></td>", $1)
$1=""; printf("<td>%s</td></tr>", $0)
}
END{print "</table></div></section>"}'
fi
if [ -n "$(GET modprobe)" ]; then
echo "<pre>$(modprobe -v $(GET modprobe))</pre>"
fi
if [ -n "$(GET rmmod)" ]; then
echo "Removing"
rmmod -w $(GET rmmod)
fi
if [ -n "$search" ]; then
cat <<EOT
<section>
<header>$(_ 'Matching result(s) for: %s' $search)</header>
<pre class="scroll">
EOT
busybox modprobe -l | grep "$search" | while read line
do
name=$(basename $line)
mod=${name%.ko.xz}
echo "<span data-icon=\"\">$(_ 'Module:')</span> <a href='?modinfo=$mod'>$mod</a>"
done
echo '</pre></section>'
fi
cat <<EOT
<section>
<table class="zebra">
<thead>
<tr>
<td>$(_ 'Module')</td>
<td>$(_ 'Description')</td>
<td>$(_ 'Size')</td>
<td>$(_ 'Used')</td>
<td>$(_ 'by')</td>
</tr>
<thead>
<tbody>
EOT
lsmod | tail -n+2 | awk '{
gsub(",", " ", $4);
printf("<tr><td><a href=\"?modinfo=%s\">%s</a></td><td>", $1, $1);
system("modinfo -d " $1);
printf("</td><td>%s</td><td>%s</td><td>%s</td></tr>", $2, $3, $4);
}'
cat <<EOT
</thead>
</table>
</section>
EOT
;;
*\ lsusb\ *)
xhtml_header
vidpid="$(GET lsusb)"
cat <<EOT
<h2>$(_ 'Information for USB Device %s' $vidpid)</h2>
<p>$(_ 'Detailed information about specified device.')</p>
<section>$(lsusb_table)</section>
EOT
[ "$vidpid" != 'lsusb' ] && cat <<EOT
<section>
<pre style="white-space: pre-wrap">$(lsusb_vd $vidpid)</pre>
</section>
EOT
;;
*\ lspci\ *)
xhtml_header
slot="$(GET lspci)"
cat <<EOT
<h2>$(_ 'Information for PCI Device %s' $slot)</h2>
<p>$(_ 'Detailed information about specified device.')</p>
<section>$(lspci_table)</section>
EOT
[ "$slot" != 'lspci' ] && cat <<EOT
<section>
<pre style="white-space: pre-wrap">$(lspci -vs $slot | syntax_highlighter lspci)</pre>
</section>
EOT
;;
*)
[ -n "$(GET devcount)" ] &&
#echo -n $(GET brightness) > /sys/class/backlight/$(GET dev)/brightness
dvc=$(GET devcount)

if [ "$dvc" != "0" ]; then
	for dv in $(seq 1 $dvc)
	do
	 kdev="dev$dv"
	 kbr="brightness$dv"
	 set_bright $(GET $kbr) $(GET $kdev)
	done
fi

xhtml_header "$(_ 'Drivers and Devices')"
cat <<EOT
<p>$(_ 'Manage your computer hardware')</p>
<form><!--
--><button name="modules" data-icon="">$(_ 'Kernel modules')</button><!--
--><button name="detect"  data-icon="" data-root>$(_ 'Detect PCI/USB')</button><!--
--><button name="tazx"    data-icon=""   data-root>$(_ 'Auto-install Xorg video driver')</button><!--
--></form>
EOT
if [ -n "$(ls /proc/acpi/battery/*/info 2>/dev/null)" ]; then
cat <<EOT
<section>
<header>$(_ 'Battery')</header>
<div>
<table class="wide">
EOT
for dev in $(ls /proc/acpi/battery); do
grep ^present /proc/acpi/battery/$dev/info | grep -q yes || continue
design=$(sed '/design capacity:/!d;       s/[^0-9]*\([0-9]*\).*/\1/' < /proc/acpi/battery/$dev/info)
remain=$(sed '/remaining capacity/!d;     s/[^0-9]*\([0-9]*\).*/\1/' < /proc/acpi/battery/$dev/state)
rate=$(sed '/present rate/!d;           s/[^0-9]*\([0-9]*\).*/\1/' < /proc/acpi/battery/$dev/state)
full=$(sed '/last full capacity/!d;     s/[^0-9]*\([0-9]*\).*/\1/' < /proc/acpi/battery/$dev/info)
warning=$(sed '/design capacity warning/!d;s/[^0-9]*\([0-9]*\).*/\1/' < /proc/acpi/battery/$dev/info)
low=$(sed '/design capacity low/!d;    s/[^0-9]*\([0-9]*\).*/\1/' < /proc/acpi/battery/$dev/info)
state=$(sed '/charging state/!d;         s/\([^:]*:[ ]\+\)\([a-z]\+\)/\2/' < /proc/acpi/battery/$dev/state)
rempct=$(( $remain * 100 / $full ))
cat <<EOT
<tr>
<td><span data-icon="">$(_ 'Battery')</span>
$(grep "^battery type" $dev/info | sed 's/.*: *//')
$(grep "^design capacity:" $dev/info | sed 's/.*: *//') </td>
<td>$(_ 'health') $(( (100*$full)/$design))%</td>
<td class="meter"><meter min="0" max="$full" value="$remain" low="$low"
high="$warning" optimum="$full"></meter>
<span>
EOT
case "$state" in
"discharging")

if [ $rate -ne 0 ]; then
 remtime=$(( $remain * 60 / $rate ))
 remtimef=$(printf "%d:%02d" $(($remtime/60)) $(($remtime%60)))
fi

_ 'Discharging %d%% - %s' $rempct $remtimef;;

"charging")

if [ $rate -ne 0 ]; then
 remtime=$(( ($full - $remain) * 60 / $rate ))
 remtimef=$(printf "%d:%02d" $(($remtime/60)) $(($remtime%60)))	
fi

_ 'Charging %d%% - %s' $rempct $remtimef;;

"charged")
_ 'Charged 100%%';;
esac
cat <<EOT
</span>
</td>
</tr>
EOT
done
cat <<EOT
</table>
</div>
</section>
EOT
fi
if [ -n "$(ls /sys/class/thermal/*/temp 2>/dev/null)" ]; then
echo "<section><p><header>$(_ 'Temperatures')</span></header></p>"

cnt=1

echo "<table>"

for temp in $(ls /sys/class/thermal/*/temp); do

z1=$(dirname $temp)
zname=$(basename $z1)

atemp=$(expr $(cat $temp) / 1000)


echo '
<tr>
<td>'$zname':</td>
<td class="meter"><meter min="0" max="100" value="'$atemp'" low="35" high="60" optimum="30"></meter><span>'$atemp'°C</span></td>
</tr>
'

#echo "$zname: $atemp°C &nbsp;"

cnt=$(expr $cnt + 1)

done
echo '</table>
</br>
</section>'
fi

if [ -n "$(ls /sys/class/backlight/*/brightness 2>/dev/null)" ]; then
echo '<section>'

echo '<form>'

echo '<header>'$(_ 'Brightness')'</header><br>&nbsp;'

cnt=1

echo "<table>"

for dev in $(ls /sys/class/backlight/*/brightness)
do

    name=$(echo $dev | sed 's|.*/backlight/\([^/]*\).*|\1|')

	if [ "$(cat "/sys/class/backlight/$name/type")" == "firmware" ] || [ "$(cat "/sys/class/backlight/$name/type")" == "raw" ]; then
		
	   max_br1=$(cat "/sys/class/backlight/$name/max_brightness")
	   nbr=$(cat "/sys/class/backlight/$name/brightness")
	   sbr=$(expr $max_br1 / $nbr)
	   current_br=$(expr 100 / $sbr)
		
		STR='
		 <tr>
		 <td align="left"><input type="hidden" name="dev'$cnt'" value="'$name'"/>'$name':</td>
		 <td><input name="brightness'$cnt'" type="range" min="0" max="100" value="'$current_br'" data-root></td>
		 </tr>'

	   echo "$STR"
	   
       cnt=$(expr $cnt + 1)
	fi

done

echo '</table>
<br>&nbsp;<br>'
echo '&nbsp;<button data-icon="" onclick="submit();" data-root> '$(_ 'Apply')'</button>'
echo '<input type="hidden" name="devcount" value="'$(expr $cnt - 1)'"/>'
echo '</form>'
echo '</br>&nbsp;</section>'
fi

cat <<EOT
<section>
<form action="#mount" class="wide">
<header id="disk">$(_ 'Filesystem usage statistics')</header>
<div>
<pre>$(disk_info)</pre>
</div>
EOT
device=$(GET loopdev)
lib crypto $device
case "$device" in
/dev/*loop*)
set -- $(losetup | grep ^$device:)
[ -n "$3" ] && losetup -d $device
ro=""
[ -n "$(GET readonly)" ] && ro="-r"
file="$(GET backingfile)"
[ -n "$file" ] && losetup -o $(GET offset) $ro $device $file
esac
device=$(GET device)
lib crypto $device
case "$device" in
*[\;\`\&\|\$]*);;
mount\ *)
ro=""
[ -n "$(GET readonly)" ] && ro="-r"
mntdir="$(GET mountpoint)"
[ -d "$mntdir" ] || mkdir -p "$mntdir"
$device $ro "$mntdir";;
umount\ *|swapon\ *|swapoff\ *)
$device;;
esac
cat <<EOT
<table id="mount" class="zebra wide center">
EOT
df_thead
echo '<tbody>'
bootdevs="$(fdisk -l | sed '/\*/!d;/^\/dev/!d;s/ .*//' | xargs)"
for fs in $(blkid | sort | sed 's/:.*//'); do
set -- $(df -h | grep "^$fs ")
size=$2
used=$3
av=$4
grep "^$fs " /proc/mounts | grep -q "[, ]ro[, ]" &&
av="<del>$av</del>"
pct=$5
mp=$6
action="mount"
[ -n "$mp" ] && action="umount"
type=$(blkid $fs | sed '/ TYPE=/!d;s/.* TYPE="\([^"]*\).*/\1/')
[ -n "$type" ] || continue
[ "$type" == "swap" ] && action="swapon"
if grep -q "^$fs " /proc/swaps; then
action="swapoff"
set -- $(grep "^$fs " /proc/swaps)
size=$(blk2h $(($3*2)))
used=$(blk2h $(($4*2)))
av=$(blk2h $((2*($3-$4))))
pct=$(((100*$4)/$3))%
mp=swap
fi
[ -z "$size" ] &&
size="$(blk2h $(cat /sys/block/${fs##*/}/size /sys/block/*/${fs##*/}/size))"
disktype=""
case "$(cat /sys/block/${fs##*/}/removable 2>/dev/null ||
cat /sys/block/${fs:5:3}/removable 2>/dev/null)" in
1) disktype="";;
esac
case "$(cat /sys/block/${fs##*/}/ro 2>/dev/null ||
cat /sys/block/${fs:5:3}/ro 2>/dev/null)" in
1) disktype="";;
esac
dsk="${fs##*/}"
case " $bootdevs " in *\ $fs\ *) dsk="<i>$dsk</i>";; esac
radio="<input type=\"radio\" name=\"device\" value=\"$action $fs\" id=\"${fs##*/}\"/>"
[ "$REMOTE_USER" == "root" ] || radio=""
cat <<EOT
<tr>
<td>$radio<!--
--><label for="${fs##*/}" data-icon="$disktype">&thinsp;$dsk</label></td>
<td>$(blkid $fs | sed '/LABEL=/!d;s/.*LABEL="\([^"]*\).*/\1/')</td>
<td>$type</td>
<td>$size</td>
<td>$av</td>
EOT
if [ -n "$pct" ]; then
cat <<EOT
<td class="meter"><meter min="0" max="100" value="${pct%%%}" low="70"
high="90" optimum="10"></meter>
<span>$used - $pct</span>
</td>
EOT
else
cat <<EOT
<td> </td>
EOT
fi
cat <<EOT
<td>$mp</td>
<td>$(blkid $fs | sed '/UUID=/!d;s/.*UUID="\([^"]*\).*/\1/')</td>
</tr>
EOT
done
cat <<EOT
</tbody>
</table>
EOT
[ "$REMOTE_USER" == "root" ] && cat <<EOT
$(lib crypto input)
<footer>
<button type="submit">mount / umount</button> -
$(_ 'new mount point:') <input type="text" name="mountpoint" value="/media/usbdisk"/> -
<input type="checkbox" name="readonly" id="ro"><label for="ro">&thinsp;$(_ 'read-only')</label>
</footer>
EOT
cat <<EOT
</form>
</section>
EOT
cat <<EOT
<section>
<header>
$(_ 'Filesystems table')
$(edit_button /etc/fstab)
</header>
<table class="wide zebra center">
<thead>
<tr>
<td>$(_ 'Disk')</td>
<td>$(_ 'Mount point')</td>
<td>$(_ 'Type')</td>
<td>$(_ 'Options')</td>
<td>$(_ 'Freq')</td>
<td>$(_ 'Pass')</td>
</tr>
</thead>
<tbody>
EOT
grep -v '^#' /etc/fstab | awk '{
print "<tr><td>" $1 "</td><td>" $2 "</td><td>" $3 "</td><td>" $4
print "</td><td>" $5 "</td><td>" $6 "</td></tr>"
}
END{print "</tbody></table>"}'
cat <<EOT
</section>
EOT
cat <<EOT
<section>
<header>$(_ 'Loop devices')</header>
<form action="#loop" class="wide">
<div class="scroll">
<table id="loop" class="wide zebra scroll">
<thead>
<tr>
<td>$(_ 'Device')</td>
<td>$(_ 'Backing file')</td>
<td>$(_ 'Size')</td>
<td>$(_ 'Access')</td>
<td>$(_ 'Offset')</td>
</tr>
</thead>
<tbody>
EOT
for devloop in $(ls /dev/*loop[0-9]*); do
loop="${devloop##*/}"
dir=/sys/block/$loop
case "$(cat $dir/ro 2>/dev/null)" in
0) ro="$(_ "read/write")";;
1) ro="$(_ "read only")";;
*) ro="";;
esac
size=$(blk2h $(cat $dir/size))
[ "$size" == "0.0K" ] && size="" && ro=""
set -- $(losetup $devloop)
set -- "${3:-$(cat $dir/loop/backing_file)}" "${2:-$(cat $dir/loop/offset)}" ${ro// /&nbsp;}
cat <<EOT
<tr><td><input type="radio" name="loopdev" value="$devloop" id="$loop"/><!--
--><label for="$loop" data-icon="">$loop</label></td>
<td>$1</td><td>$size</td><td align="center">$3</td><td align="right">$2</td>
</tr>
EOT
done
cat <<EOT
</tbody>
</table>
</div>
$(lib crypto input)
<footer>
<button type="submit" data-icon="">$(_ 'Setup')</button> -
$(_ 'new backing file:') <input type="text" name="backingfile"/> -
$(_ 'offset in bytes:') <input type="text" name="offset" value="0" size="8"/> -
<input type="checkbox" name="readonly" id="ro"/><label for="ro">$(_ 'read only')</label>
</footer>
</form>
</section>
EOT
mem_total=$(free -m | awk '$1 ~ "M" {print $2}')
mem_used=$((100 * $(free -m | awk '$1 ~ "+" {print $3}') / mem_total))
mem_buff=$((100 * $(free -m | awk '$1 ~ "M" {print $6}') / mem_total))
mem_free=$((100 - mem_used - mem_buff))
cat <<EOT
<section>
<header>$(_ 'System memory')</header>
<div class="sysmem"><!--
--><span class="sysmem_used" style="width: ${mem_used}%" title="$(_ 'Used')"><span>${mem_used}%</span></span><!--
EOT
[ $mem_buff != 0 ] && cat <<EOT
--><span class="sysmem_buff" style="width: ${mem_buff}%" title="$(_ 'Buffers')"><span>${mem_buff}%</span></span><!--
EOT
cat <<EOT
--><span class="sysmem_free" style="width: ${mem_free}%" title="$(_ 'Free')"><span>${mem_free}%</span></span><!--
--></div>
<table class="wide zebra center">
<thead>
<tr>
<td>&nbsp;</td>
<td>total</td>
<td>used</td>
<td>free</td>
<td>shared</td>
<td>buffers</td>
</tr>
</thead>
<tbody>
EOT
free -m | awk '
$1 ~ "M" {print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td></tr>"}
$1 ~ "+" {print "<tr><td>"$1 $2"</td><td></td><td>"$3"</td><td>"$4"</td><td></td><td></td></tr>"}
$1 ~ "S" {print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td></td><td></td></tr>"}'
cat <<EOT
</tbody>
</table>
</section>
EOT
cat <<EOT
<section>
<header>lspci</header>
$(lspci_table)
</section>
<section>
<header>lsusb</header>
$(lsusb_table)
</section>
EOT
;;
esac
xhtml_footer
exit 0
