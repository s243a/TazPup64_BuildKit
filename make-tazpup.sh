#!/bin/bash
#written by mistfire, modified by s243a
#Build TazPuppy either online or local
curdir=`pwd`
. $curdir/builder.cfg
#. $curdir/pkg-dirs
#LABEL1=""
. $curdir/defaults
xmode=${xmode:-""}
xinteractive=${xinteractive:-""}
branch=${branch:-"next64"}
arch=${arch:-"x86_64"}
prefix=${prefix:-"/64"}

if [ ! -f $curdir/builder.cfg ]; then
echo 'WEBSITE="http://mirror1.slitaz.org/iso/rolling"
LIVECD="slitaz-rolling-core.iso"' > $curdir/builder.cfg
fi

## Add function imports here
source $curdir/build-scripts/make-tazpup_functions.sh

trap unmount_vfs EXIT
trap unmount_vfs SIGKILL
trap unmount_vfs SIGTERM



if [ "$(whoami)" != "root" ]; then
  echo "Requires root access to do it"
  exit
fi

if [ "$(which Xdialog)" == "" ]; then
echo "Requires Xdialog. Install it first"
exit
fi

if [ ! -w $curdir ]; then
  echo "The working path is not writable"
  exit
fi

if [ ! -e $curdir/tazpup-core-files ]; then
  echo "Core files are missing"
  exit
fi

select_build_mode #Function located in make-tazpup_functions
select_interact_mode  #Function located in make-tazpup_functions
select_force_custom  #Function located in make-tazpup_functions
clean_up_some
select_pup_img


if [ "$xmode" == "online" ]; then
 
 if [ -f $curdir/$LIVECD ]; then
 echo "Deleting $LIVECD..."
 rm -rf $curdir/$LIVECD
 fi
 
 download_iso
 
fi

prepare_working_folders

#------------------------------Extract Tazimage section -----------------------
#TODO allow a puppy immage to be used instead of a SlITZ image
#TODO maybe we don't need a base image if we just copy the package manager tazpkg and then install enough packages

echo "Mounting $(basename $IMG)..." #This is the build-system image and may also be the base immage

mount -o ro $IMG /mnt/wktaz
#https://linuxize.com/post/how-to-mount-and-unmount-file-systems-in-linux/
#mount $IMG /mnt/wktaz -o loop

if [ $? -ne 0 ]; then
  echo "Mounting slitaz image failed"
  exit
fi

if [ -f /mnt/wktaz/rootfs.gz ] || [ -f /mnt/wktaz/rootfs1.gz ]; then
  echo "Copying rootfs gz..."
  src1="/mnt/wktaz/rootfs*.gz"
elif [ -f /mnt/wktaz/boot/rootfs.gz ] || [ -f /mnt/wktaz/boot/rootfs1.gz ]; then
  echo "Copying rootfs gz..."
  src1="/mnt/wktaz/boot/rootfs*.gz"
#elif   TODO add alternative option if iso isn't found
  
else
  echo "Not a slitaz disc image"
  umount /mnt/wktaz
  exit
fi

cp -f $src1 $curdir/slitaz-livecd-wkg/

umount /mnt/wktaz

cd $curdir/slitaz-livecd-wkg

rcount=$(ls -1 ./rootfs*.gz | wc -l)

if [ $rcount -eq 1 ]; then
 echo "Extracting rootfs gz..."
 extractfs $curdir/slitaz-livecd-wkg/rootfs.gz
 BaseImageExtracted=1
elif [ $rcount -gt 1 ]; then
	for rf1 in $(ls -1 ./rootfs*.gz | sort -r)
	do
	 echo "Extracting $(basename $rf1)..."
	 extractfs $rf16
	done
	 BaseImageExtracted=1
else
 echo "No rootfs found"
 # exit See notes above of maybe not needing a base image
# read -p "Press enter to continue"
 BaseImageExtracted=0
fi

if [ $BaseImageExtracted -eq 1 ]; then
  rm -rf $curdir/slitaz-livecd-wkg 

  remove_some_slitaz
  rm -rf $curdir/slitaz-rootfs/var/www/tazpanel/menu.d/network/*

  for file1 in $(find $curdir/slitaz-rootfs/usr/share/icons/ -type f -name "application-x-executable.png")
  do
	if [ -L $file1 ]; then
	fname=$(readlink $file1)
      if [ "$fname" != "" ]; then
		  if [ "$(basename $fname)" == "application-x-generic.png" ]; then
		  rm -f $file1
		  fi
      fi
    fi
  done

  for file1 in $(find $curdir/slitaz-rootfs/usr/share/icons/ -type f -name "application-x-generic.png")
  do
    mv -f $file1 $(dirname $file1)/application-x-executable.png
  done
fi #TODO add else option for using a puppy image instead
# End Tazimage Section --------------------------------------------------------------- 
#exit
make_pupcore #I think we always want to do this but will think more about it.
mkdir -p $curdir/slitaz-rootfs$prefix/usr/share/boot
mkdir -p $curdir/slitaz-rootfs$prefix/usr/bin

if [ $BaseImageExtracted -eq 1 ]; then
  select_copy_tazpkg_in_build_env
else
  cpytaz=1
fi
#TODO add some build architecture logic here: check that prefix makes sense. 
#cp --remove-destination -arf $curdir/tazpup-core-files/build/amd64/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null 
#cp -f $curdir/tazpup-core-files/build/no-arch/bin/$fullcmd $curdir/slitaz-rootfs$prefix/bin/$fullcmd
if [ $cpytaz -eq 1 ]; then
  #These next four statments have been replaced by a single statment (s243a)
  #The intent is to copy tazpkg into the build system. This isn't necissary if tazpkg is included in the base image.
  #cp -f $curdir/tazpup-core-files/slitaz/usr/bin/tazpkg $curdir/slitaz-rootfs$prefix/usr/bin/tazpkg
  #cp -f $curdir/tazpup-core-files/slitaz/usr/bin/active-networks $curdir/slitaz-rootfs$prefix/usr/bin/active-networks
  #mkdir -p $curdir/slitaz-rootfs$prefix/usr/libexec/tazpkg/
  #cp -f $curdir/tazpup-core-files/slitaz/usr/libexec/tazpkg/* $curdir/slitaz-rootfs$prefix/usr/libexec/tazpkg/
  cp --remove-destination -arf $curdir/tazpup-core-files/tazpkg/* $curdir/slitaz-rootfs/ 2>/dev/null

fi
  #Not sure whether or not the next two statments should be in the above iff block @s243a
  #I think these two scripts are custom and might be useful for the build system (to re-evaluate (s243a)
  cp -f $curdir/tazpup-core-files/slitaz/usr/bin/tazpet $curdir/slitaz-rootfs/usr/bin/tazpet
  cp -f $curdir/tazpup-core-files/slitaz/usr/bin/tazpet-box $curdir/slitaz-rootfs/usr/bin/tazpet-box

#exit

echo "SliTaZ Extracted"
#read -p "Press enter to continue"


if [ ! -d $curdir/slitaz-rootfs ]; then
 echo "Extract rootfs failed"
 exit
fi

rm -f $curdir/slitaz-rootfs$prefix/init

cd $curdir
mkdir -p $curdir/slitaz-rootfs$prefix/pkgs
#Copy The following directories into the workspace
#pkgs/slitaz-base pkgs/slitaz-dependencies pkgs/slitaz-packages pkgs/slitaz-preinst-pkg
#these directory names come from the array pkg_dirs_to_copy
for aDir in "${pkg_dirs_to_copy[@]}"; do # $pkgs/slitaz-base pkgs/slitaz-dependencies pkgs/slitaz-packages pkgs/slitaz-preinst-pkg; do
  if [ ! -d $aDir ]; then
    if [ ${aDir:0:1} = "/" ]; then
      $curdir$aDir
    else
      $curdir/$aDir
    fi
  fi
  cp --remove-destination -arf $aDir/* $curdir/slitaz-rootfs$prefix/pkgs #2>/dev/null
done 



cd $curdir
mount -o rbind /proc $curdir/slitaz-rootfs/proc #TODO also added mounts in $curdir/slitaz-rootfs$prefix
mount -t sysfs none $curdir/slitaz-rootfs/sys
if [ $xinteractive -eq 1 ]; then
 echo "Removing block device files..."
 #rm -rf $curdir/slitaz-rootfs/dev/*
 mv $curdir/slitaz-rootfs/dev-back $curdir/slitaz-rootfs/dev-back
 #mount bind -t devtmpfs none $curdir/slitaz-rootfs/dev
 mount -o rbind /dev $curdir/slitaz-rootfs/dev
 cp -f /etc/resolv.conf $curdir/slitaz-rootfs/etc/resolv.conf
fi





#exit

#install_pkg $curdir/slitaz-packages/readline-7.0-x86_64.tazpkg
#install_pkg $curdir/slitaz-packages/bash-4.4.p23-x86_64.tazpkg
#install_pkg $curdir/extract/busybox-1.27.2-x86_64.tazpkg
#cp -f $curdir/extract/busybox-1.27.2-x86_64.tazpkg.extracted/fs/bin/busybox $curdir/slitaz-rootfs/bin/busybox
while read aFile; do
   install_pkg $curdir/pkgs/slitaz-preinst-pkg/$aFile 
   post_inst_fixes $pkg
done <$slitaz_preinst_pkg_dir/files.txt
#TODO append file in directory to files.txt that aren't already on the list
#TODO remove from list any files that are not in the directory, unless flagged for remote download. 
#TODO consider using tazpkg in the prefix folder at this point. 

#TODO add some build architecture logic here: check that prefix makes sense. 
cp --remove-destination -arf $curdir/tazpup-core-files/build/amd64/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null  

if [ cpy_unknown -eq 1 ]; then
  cp --no-clobber -arf $curdir/tazpup-core-files/unknown/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null
fi 

  
echo "Fishished slitaz-preinst-pkg"
#read -p "Press enter to continue" #added by s243a

echo "Installing Base Slitaz packages..."
#TODO, add option to skip this if someone inserted a base CD. 
for pkg in $(find $slitaz_base_pkg_dir -type f -name "*.tazpkg" | sort -r)
do
    echo "Processing core package: $(basename $pkg)"
	install_pkg "$pkg"
done

#cp $curdir/slitaz-post-patch-packages/coreutils-multicall-8.30-x86_64.tazpkg $curdir/slitaz-rootfs$prefix/pkgs/coreutils-multicall-8.30-x86_64.tazpkg
#install_pkg $curdir/slitaz-post-patch-packages/coreutils-multicall-8.30-x86_64.tazpkg

#Comment out for now as I think this gets installed as a dependency

#For some reason 32bit libs are getting installed earlier and we need to overwrite them
install_pkg $curdir/pkgs/applications/dependencies/next64/gconf-3.2.6-x86_64.tazpkg --forced #TODO figure out if we can do this earlier

cp $curdir/pkgs/slitaz-post-patch-packages/eudev-3.2.7-x86_64.tazpkg $curdir/slitaz-rootfs$prefix/pkgs/eudev-3.2.7-x86_64.tazpkg
install_pkg $curdir/pkgs/slitaz-post-patch-packages/eudev-3.2.7-x86_64.tazpkg
#TODO add eudev and udev to the package block list

add_locks_and_blockFiles

echo "Processing Additional Slitaz packages..."

# Let's just be explicit in what we want:
if [ "$xmode" == "local" ]; then
 install_local_pkgs "$slitaz_packages_dir" "$special_packages_dir"
else
 echo "coud mode under re-construction"
 install_online_pkg
fi

#http://murga-linux.com/puppy/viewtopic.php?t=115306

#exit

#if [ -d $curdir/custom-packages ]; then
#	for pkg in $(find $curdir/custom-packages -type f -name "*.tazpkg")
#	do
#	echo "Processing custom package: $(basename $pkg)"
#	install_pkg "$pkg"
#	done
#fi


#if [ -d $curdir/pkgs/pet-packages ]; then
#	for pkg in $(find $curdir/pet-packages -type f -name "*.pet")
#	do
#	  echo "Processing pet package: $(basename $pkg)"
#	  install_pet_pkg "$pkg"
#	  donefor pkg in $(find $curdir/converted-aliens -type f -name "*.tazpkg" | sort -r)
#   done
#
#fi

for pkg in $(find $converted_aliens_pkg_dir -type f -name "*.tazpkg" | sort -r)
do
  echo "Processing converted aliens: $(basename $pkg)"
  install_pkg "$pkg"
done

#### Let's Give Some Choices For Applications ####

for Ap_Type in "console_editors" "terminal_emulators" "text_editors" "graphics" "games"; do
  Applications_TO_INSTALL="TO_INSTALL_$Ap_Type"
  is_array "$Applications_TO_INSTALL"
  if [ ! is_array_rtn ]; then
    if [ "${#Applications_TO_INSTALL}" -gt 0 ]; then
       Applications_TO_INSTALL=( ${Applications_TO_INSTALL//,/$IFS} )
    fi
  fi
  #if [ is_array_rtn -eq 1 ]; then
    #if [ ${#myvar} -gt 0 ]; then
    #  Applicatoins_TO_INSTALL=( "$TextEditors_TO_INSTALL" )
    #else
    #  set_Applications_TO_INSTALL 
    #  Applicatoins_TO_INSTALL="$set_Applications_TO_INSTALL_rtn"
    #fi
    for application in "${Applications_TO_INSTALL[@]}"; do
      
      app_path=$curdir/pkgs/applications/$Ap_Type/$application
      #if [ -d "$app_path/$branch" ]; then
        install_pkgs_fm_dir "$app_path" #see $curdir/build-scripts/make-tazpup_functions.sh
      #fi
      #install_pkg "$app_path"
    done
  #fi
done

for woof_pkg in "${WOOF_CE_PKGS_TO_INSTALL[@]}"; do
  install_woofCE_pkg "$woof_pkg"
done
echo "Applying patches..."

#Somd utilities in procps link to missing library libproc-3.2.8.so
while read -r line; do #https://unix.stackexchange.com/questions/85060/getting-relative-links-between-two-paths
  #https://stackoverflow.com/questions/9293887/reading-a-delimited-string-into-an-array-in-bash
  #https://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_10_02.html
  arr=($line)
  target_f=$curdir/slitaz-rootfs$prefix${arr[0]}
  source_f=${arr[1]}
  if [ -f $target_f ]; then
    
    fname=`basename $target_f`
    target_d=`dirname $target_f`
    mv $target_f $target_d/$fname-old
    cd $target_d
    pwd
    ln -s $source_f $fname
  fi
done <<EOM
/bin/uname busybox
/sbin/sysctl ../bin/busybox
/bin/ps busybox
/bin/kill busybox
/usr/bin/w ../../bin/busybox
/usr/bin/pmap ../../bin/busybox
/usr/bin/free ../../bin/busybox
/usr/bin/uptime ../../bin/busybox
/usr/bin/pkill ../../bin/busybox
/usr/bin/pgrep ../../bin/busybox
/usr/bin/top ../../bin/busybox
/usr/bin/watch ../../bin/busybox
EOM


#chroot "$curdir/slitaz-rootfs/" tazpkg setup-mirror http://mirror.slitaz.org/packages/next64/ 
echo "http://mirror.slitaz.org/packages/next64/">$curdir/slitaz-rootfs$prefix/var/lib/tazpkg/mirror 

cp --remove-destination -arf $curdir/tazpup-core-files/slitaz/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null
cp --remove-destination -arf $curdir/tazpup-core-files/puppy/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null
#TODO add some build architecture logic here: check that prefix makes sense. 
cp --remove-destination -arf $curdir/tazpup-core-files/build/amd64/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null 






make_pupcore

if [ -f $curdir/slitaz-rootfs$prefix/usr/sbin/hald ]; then
 mv -f $curdir/slitaz-rootfs$prefix/usr/sbin/hald $curdir/slitaz-rootfs$prefix/usr/bin/hald
 sed -i -e "s#\/usr\/sbin\/hald#\/usr\/bin\/hald#g" $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/hal/files.list
 sed -i -e "s#\/usr\/sbin\/hald#\/usr\/bin\/hald#g" $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/hal/md5sum
 sed -i -e "s#\/usr\/sbin\/hald#\/usr\/bin\/hald#g" $curdir/slitaz-rootfs$prefix/etc/init.d/hald
fi

if [ -f $curdir/slitaz-rootfs$prefix/usr/share/applications/defaults.list ]; then
 rm -f $curdir/slitaz-rootfs$prefix/usr/share/applications/defaults.list
fi

mkdir -p $curdir/slitaz-rootfs$prefix/etc/rc.d/
echo "PUPMODE='2'" > $curdir/slitaz-rootfs$prefix/etc/rc.d/PUPSTATE

if [ -f $curdir/slitaz-rootfs$prefix/usr/bin/coreutils ]; then
    echo '#!/bin/sh
	exec df $@' > $curdir/slitaz-rootfs$prefix/usr/bin/df-FULL
	chmod +x $curdir/slitaz-rootfs$prefix/usr/bin/df-FULL
fi

if [ -f $curdir/slitaz-rootfs$prefix/usr/bin/gzip ]; then
    rm -f  $curdir/slitaz-rootfs$prefix/bin/gzip
fi
if [ -f $curdir/slitaz-rootfs$prefix/usr/bin/lzma ]; then #Added by s243a
    rm -f  $curdir/slitaz-rootfs$prefix/bin/lzma
fi


if [ -d $curdir/slitaz-rootfs$prefix/usr/lib/grub/i386-slitaz ]; then
    ln -sr $curdir/slitaz-rootfs$prefix/usr/lib/grub/i386-slitaz $curdir/slitaz-rootfs$prefix/usr/lib/grub/i386-pc
    ln -sr $curdir/slitaz-rootfs$prefix/usr/lib/grub/i386-slitaz $curdir/slitaz-rootfs$prefix/usr/lib/grub/i386-t2
fi

if [ -d $curdir/slitaz-rootfs$prefix/usr/share/boot ]; then
    ln -sr $curdir/slitaz-rootfs$prefix/usr/share/boot $curdir/slitaz-rootfs$prefix/usr/share/syslinux

    for file1 in grldr.lzma grub.exe.lzma memdisk.lzma pxelinux.0.lzma
    do
     cp -f $curdir/slitaz-rootfs$prefix/usr/share/boot/$file1 $curdir/slitaz-rootfs$prefix/usr/share/boot/$file1.bak
     unlzma $curdir/slitaz-rootfs$prefix/usr/share/boot/$file1
     mv -f $curdir/slitaz-rootfs$prefix/usr/share/boot/$file1.bak $curdir/slitaz-rootfs$prefix/usr/share/boot/$file1
    done
fi




ln -rs $curdir/slitaz-rootfs$prefix/usr/bin/notify-send $curdir/slitaz-rootfs$prefix/usr/bin/notify

if [ ! -z $prefix ]; then #if $prefix is null then the target and build environment are the same.
  select_copy_tazpkg_in_target_env
  if [ $cpytaz_target -eq 1 ]; then 
      cp --remove-destination -arf $curdir/tazpup-core-files/tazpkg/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null
  fi
  #I think these two scripts are custom and might be useful for the build system (to re-evaluate (s243a)
  cp -f $curdir/tazpup-core-files/slitaz/usr/bin/tazpet $curdir/slitaz-rootfs$prefix/usr/bin/tazpet
  cp -f $curdir/tazpup-core-files/slitaz/usr/bin/tazpet-box $curdir/slitaz-rootfs$prefix/usr/bin/tazpet-box  
fi

#for aWoofCE_pkg in ; do
#  
#done 


#for fullcmd in mount umount ps
#do
#	if [ "$fullcmd" == "ps" ]; then
#	 cp -f $curdir/slitaz-rootfs$prefix/bin/ps $curdir/slitaz-rootfs$prefix/bin/ps-FULL
#	elif [ -f $curdir/slitaz-rootfs$prefix/bin/$fullcmd ]; then
#	 ln -rs $curdir/slitaz-rootfs$prefix/bin/$fullcmd $curdir/slitaz-rootfs$prefix/bin/$fullcmd-FULL
#	fi
#done
for fullcmd in mount umount ps
do     
	 cp -f $curdir/tazpup-core-files/build/no-arch/bin/$fullcmd $curdir/slitaz-rootfs$prefix/bin/$fullcmd
	 #cp -f $curdir/tazpup-core-files/build/amd64/bin/$fullcmd-FULL $curdir/slitaz-rootfs$prefix/bin/$fullcmd-FULL #This is redundant with the line below
done
#
cp --no-clobber rf $curdir/tazpup-core-files/build/no-arch/skel/* $curdir/slitaz-rootfs$prefix/etc/skel
cp -f $curdir/tazpup-core-files/build/no-arch/skel/.xinitrc $curdir/slitaz-rootfs$prefix/etc/skel/.xinitrc
cp --remove-destination rf $curdir/tazpup-core-files/build/no-arch/skel/* $curdir/slitaz-rootfs$prefix/etc/skel

cp --remove-destination -arf $curdir/tazpup-core-files/build/amd64/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null

#TODO seperate specific applications from /usr/local/aps (so that broken apps don't show up)
cp --no-clobber -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-skeleton/slacko6.9.9/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null

if [ ! -z $prefix ]; then
  umount -l $curdir/slitaz-rootfs/dev 2>/dev/null
  umount -l $curdir/slitaz-rootfs/sys	
  umount -l $curdir/slitaz-rootfs/proc	
  
  mount -o rbind /proc $curdir/slitaz-rootfs$prefix/proc #We might want to do these minds earlier
  mount -t sysfs none $curdir/slitaz-rootfs$prefix/sys
  if [ $xinteractive -eq 1 ]; then
    echo "Removing block device files..."
    rm -rf $curdir/slitaz-rootfs$prefix/dev/* #Maybe we want to rename rather than delete these
    #mount bind -t devtmpfs none $curdir/slitaz-rootfs/dev
    mount -o rbind /dev $curdir/slitaz-rootfs$prefix/dev
    cp -f /etc/resolv.conf $curdir/slitaz-rootfs$prefix/etc/resolv.conf
  fi
fi
set x-

#chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/gtk-update-icon-cache --ignore-theme-index /usr/share/lxpanel/images

if [ ! -z "$users" ]; then #TODO maybe add a menu option if users is not defined. 
  chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/add_users $users
fi
for pkg_dir_rel in pkgs/desktop/rox/next64 pkgs/desktop/tint2/next64 pkgs/desktop/jwm/next64; do
	pkg_dir="$curdir/$pkg_dir_rel"
	for aPkg in `ls -1 $pkg_dir`; do # $pkgs/slitaz-base pkgs/slitaz-dependencies pkgs/slitaz-packages pkgs/slitaz-preinst-pkg; do
       cp --remove-destination -arf $pkg_dir/$aPkg $curdir/slitaz-rootfs$prefix/pkgs/ #2>/dev/null
    done 
    for aPkg in `ls -1 $pkg_dir`; do 
      install_pkg $pkg_dir/$aPkg
      post_inst_fixes $aPkg
    done
done
if [ $install_WM_jwm -eq 1 ]; then #TODO verify whether or not we should do this before or after adding users
  #source source $curdir/build-scripts/add_puppy_jwm_files.sh
  source $curdir/build-scripts/add_puppy_jwm_files.sh
fi

#Im not sure how this impact pcmanfm
$curdir/build-scripts/util/clean_desktop_files.sh

for app_type in browsers chat connect package_managers spreadsheets; do
    
    for app_item in "TO_INSTALL_"$app_type; do
      default_ap_Path=$curdir/tazpup-core-files/desktop/defaults/apps/$app_type/$app_item/fs
      if [ -f "$default_ap_Path" ]; then
        cp --remove-destination -arf $default_ap_Path/* \
                 $curdir/slitaz-rootfs$prefix/ 2>/dev/null
                 
        if [ -f "$default_ap_Path/../pinst.sh" ]; then
          cp --remove-destination "$default_ap_Path/../pinst.sh" "$curdir/slitaz-rootfs$prefix/pinst.sh"
          chroot "$curdir/slitaz-rootfs$prefix/" /pinstall.sh 
          mv  "$curdir/slitaz-rootfs$prefix/pinst.sh" "default$app_type"'_'"$app_item"'_pinst.sh'
        fi
        break
      fi
    done
done
set x+
update_system_databases
#exit
#if [ cpy_lxde_pofile_info -eq 1 ]; then  
#  $curdir/slitaz-rootfs$prefix/etc/*
#fi

#cp $curdir/slitaz-rootfs$prefix/etc/xdg/lxsession $curdir/slitaz-rootfs/$usr_home/.config/lxsession #Shouldn't be necessary
#cp $curdir/slitaz-rootfs$prefix/etc/xdg/lxpanel ~/.config/lxpanel #Shouldn't be necessary
#cp $curdir/slitaz-rootfs$prefix/etc/xdg/templates ~/Templates #Shouldn't be necessary 
#update_system_databases
chroot "$curdir/slitaz-rootfs$prefix/" fixmenus

sed -i -e "s#"\
"<icon x=\"288\" y=\"32\" label=\"setup\">\/usr\/sbin\/wizardwizard<\/icon>##g" \
/root/Choices/ROX-Filer/globicons

sed -i -e "s#"\
"<icon x=\"32\" y=\"416\" label=\"connect\">\/usr\/local\/apps\/Connect<\/icon>#"\
"<icon x="32" y="416" label="connect">/usr/local/bin/defaultconnect</icon>#g" \
/root/Choices/ROX-Filer/PuppyPin

sed -i -e "s#"\
"<icon x=\"224\" y=\"32\" label=\"install\">\/usr\/sbin\/dotpup<\/icon>#"\
"<icon x=\"224\" y=\"32\" label=\"install\">\/usr\/local\/bin\/default_packagemanager<\/icon>#g" \
/root/Choices/ROX-Filer/PuppyPin

if [ -e $curdir/slitaz-rootfs$prefix/usr/sbin/iconvconfig ]; then
 chroot "$curdir/slitaz-rootfs$prefix/" /usr/sbin/iconvconfig
fi

#This is required for udiskd during shutdown. TODO recompile udiskd against libjson-c.so.4
cd $curdir$prefix/usr/lib
ln -s libjson-c.so libjson-c.so.2

umount -l $curdir/slitaz-rootfs/dev 2>/dev/null
umount -l $curdir/slitaz-rootfs/sys	
umount -l $curdir/slitaz-rootfs/proc	
if [ ! -z $prefix ]; then
  umount -l $curdir/slitaz-rootfs$prefix/dev 2>/dev/null
  umount -l $curdir/slitaz-rootfs$prefix/sys	
  umount -l $curdir/slitaz-rootfs$prefix/proc
fi
#exit

extract_kernal_modules

echo "Kernal Modlues extracted. Ready to make ISO"
read -p "Press enter to continue" #added by s243a

ls -1 $curdir/slitaz-rootfs/pkgs > $curdir/un_used_pkgs.txt
rm  $curdir/slitaz-rootfs/pkgs


if [ ! "$(ls -A $curdir/slitaz-rootfs/dev)" ]; then
  mv $curdir/slitaz-rootfs/dev-back $curdir/slitaz-rootfs/dev
else  
  rm -rf $curdir/slitaz-rootfs/dev-back
fi
#restore_dev_files


. $curdir/make_ISO_Fm_slitaz-rootfs #We're sourcing this because it is simpler than exporting all the variables. 
