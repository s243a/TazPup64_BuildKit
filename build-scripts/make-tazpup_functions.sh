#unmount_vfs(){
# umount -l $curdir/slitaz-rootfs/dev 2>/dev/null
# umount -l $curdir/slitaz-rootfs/sys 2>/dev/null
# umount -l $curdir/slitaz-rootfs/proc 2>/dev/null
# if [ ! -z "$prefix" ]; then
#   umount -l $curdir/slitaz-rootfs$prefix/dev 2>/dev/null
#   umount -l $curdir/slitaz-rootfs$prefix/sys 2>/dev/null
#   umount -l $curdir/slitaz-rootfs$prefix/proc 2>/dev/null
# fi
# umount /mnt/wktaz 2>/dev/null
# umount /mnt/wksfs 2>/dev/null
# 
#}
unmount_rootfs_binds(){
	if [ "$(mount | grep "$curdir/slitaz-rootfs/dev")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/dev
    fi	

    if [ "$(mount | grep "$curdir/slitaz-rootfs/sys")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/sys
    fi	
    if [ "$(mount | grep "$curdir/slitaz-rootfs/proc")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/proc
    fi
    if [ ! -z "$prefix" ] && [ ! -f $curdir/slitaz-rootfs$prefix ]; then
       if [ "$(mount | grep "$curdir/slitaz-rootfs/dev")" != "" ]; then
          umount -l $curdir/slitaz-rootfs$prefix/dev
       fi	

      if [ "$(mount | grep "$curdir/slitaz-rootfs/sys")" != "" ]; then
        umount -l $curdir/slitaz-rootfs$prefix/sys
      fi	
      if [ "$(mount | grep "$curdir/slitaz-rootfs/proc")" != "" ]; then
        umount -l $curdir/slitaz-rootfs$prefix/proc
      fi
    fi
}
unmount_vfs(){
 unmount_rootfs_binds
 umount /mnt/wktaz 2>/dev/null
 umount /mnt/wksfs 2>/dev/null
 exec 11>&-
 exec 12>&- #Used in: install_pkgs_fm_dir
}  

unmount_vfs(){
 unmount_rootfs_binds
 umount /mnt/wktaz 2>/dev/null
 umount /mnt/wksfs 2>/dev/null
 
}    
clean_up(){
		
  if [ -d $curdir/slitaz-rootfs ]; then

    if [ "$(mount | grep "$curdir/slitaz-rootfs/dev")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/dev
    fi	

    if [ "$(mount | grep "$curdir/slitaz-rootfs/sys")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/sys
    fi	
    if [ "$(mount | grep "$curdir/slitaz-rootfs/proc")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/proc
    fi

    echo "Deleting slitaz-rootfs..."
    rm -rf $curdir/slitaz-rootfs
  fi

  if [ -d $curdir/tazpup-preiso ]; then
    echo "Deleting tazpup-preiso..."
    rm -rf $curdir/tazpup-preiso
  fi

  if [ -d $curdir/kernel-modules ]; then
    echo "Deleting kernel-modules..."
    rm -rf $curdir/kernel-modules
  fi

  if [ -d $curdir/slitaz-dload ]; then
    echo "Deleting slitaz-dload..."
    rm -rf $curdir/slitaz-dload
  fi

  if [ -d $curdir/tazpup-core-files/slitaz-packages-fs ]; then
    echo "Deleting slitaz-packages-fs..."
    rm -rf $curdir/tazpup-core-files/slitaz-packages-fs
  fi

  if [ -f $curdir/slitaz-rolling-core.iso ]; then
    echo "Deleting slitaz-rolling-core.iso..."
    rm -f $curdir/slitaz-rolling-core.iso
  fi

  rm -f $curdir/tazpup-core-files/installed-isolated.md5
  rm -f $curdir/tazpup-core-files/installed-isolated.info

  rm -f $curdir/package-deps.txt
  rm -f $curdir/package-listed

  if [ -f $curdir/custom-tazpup.iso ]; then
    echo "Deleting custom-tazpup.iso..."
    rm -f $curdir/custom-tazpup.iso
  fi

  if [ -f $curdir/custom-tazpup.iso.md5 ]; then
    echo "Deleting custom-tazpup.iso.md5..."
    rm -f $curdir/custom-tazpup.iso.md5
  fi

  if [ -d $curdir/slitaz-livecd-wkg ]; then
    rm -rf $curdir/slitaz-livecd-wkg
  fi

	
}
clean_up_some(){
		
  if [ -d $curdir/slitaz-rootfs ]; then

    if [ "$(mount | grep "$curdir/slitaz-rootfs/dev")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/dev
    fi	

    if [ "$(mount | grep "$curdir/slitaz-rootfs/sys")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/sys
    fi	
    if [ "$(mount | grep "$curdir/slitaz-rootfs/proc")" != "" ]; then
      umount -l $curdir/slitaz-rootfs/proc
    fi

    echo "Deleting slitaz-rootfs..."
    rm -rf $curdir/slitaz-rootfs
  fi

  if [ -d $curdir/tazpup-preiso ]; then
    echo "Deleting tazpup-preiso..."
    rm -rf $curdir/tazpup-preiso
  fi

  if [ -d $curdir/kernel-modules ]; then
    echo "Deleting kernel-modules..."
    rm -rf $curdir/kernel-modules
  fi

  if [ -d $curdir/slitaz-dload ]; then
    echo "Deleting slitaz-dload..."
    rm -rf $curdir/slitaz-dload
  fi

  if [ -d $curdir/tazpup-core-files/slitaz-packages-fs ]; then
    echo "Deleting slitaz-packages-fs..."
    rm -rf $curdir/tazpup-core-files/slitaz-packages-fs
  fi

  rm -f $curdir/tazpup-core-files/installed-isolated.md5
  rm -f $curdir/tazpup-core-files/installed-isolated.info

  rm -f $curdir/package-deps.txt
  rm -f $curdir/package-listed

  if [ -f $curdir/custom-tazpup.iso ]; then
    echo "Deleting custom-tazpup.iso..."
    rm -f $curdir/custom-tazpup.iso
  fi

  if [ -f $curdir/custom-tazpup.iso.md5 ]; then
    echo "Deleting custom-tazpup.iso.md5..."
    rm -f $curdir/custom-tazpup.iso.md5
  fi

  if [ -d $curdir/slitaz-livecd-wkg ]; then
    rm -rf $curdir/slitaz-livecd-wkg
  fi

	
}


sandbox_pkg(){

  cmd="$1"
  pkg="$2"
  bname="$(basename $pkg)"

  if [ ! -d $curdir/tazpup-core-files/slitaz-sandbox ]; then
    mkdir -p $curdir/tazpup-core-files/slitaz-sandbox 2> /dev/null
  fi

  cp -f $pkg $curdir/tazpup-core-files/slitaz-packages-fs/$bname

  mount -t aufs -o udba=reval,diropq=w,dirs=$curdir/tazpup-core-files/slitaz-packages-fs=rw:$curdir/slitaz-rootfs=ro unionfs $curdir/tazpup-core-files/slitaz-sandbox

  if [ "$cmd" == "install" ]; then
    xcmd="tazpkg install /$bname --forced"
  elif [ "$cmd" == "remove" ]; then
   xcmd="tazpkg remove $pkg"
  fi

  chroot $curdir/tazpup-core-files/slitaz-sandbox/ $xcmd
  umount -l $curdir/tazpup-core-files/slitaz-sandbox

  rm -f $curdir/tazpup-core-files/slitaz-packages-fs/$bname
	
}
install_pkg(){

  pkg="$1"
  opt_in="$2"
  options=${opt_in:-'--local'} #In some cases might want to use options like --forced --newconf --nodeps of --local
  echo "installing $1"
  echo "options=$options" 
  bname="$(basename $pkg)"

  #Direct errors to null because it should already exist in destination folder. 	
  cp $pkg $curdir/slitaz-rootfs$prefix/pkgs/$bname 2> /dev/null #We'll copy everything into $curdir/slitaz-rootfs/pkgs before installig anything. 

  echo "#!/bin/sh
cd $prefix/pkgs
tazpkg $options install $bname --root=$prefix
" > $curdir/slitaz-rootfs$prefix/pkgs/start.sh #$curdir/slitaz-rootfs/start.sh

  chmod +x $curdir/slitaz-rootfs$prefix/pkgs/start.sh
  chroot $curdir/slitaz-rootfs/ $prefix/pkgs/start.sh #Consider chrooting into the prefix folder once enough packages are installed
  #read -p "Press enter to continue" #added by s243a
  rm -f $curdir/slitaz-rootfs$prefix/pkgs/$bname
  rm -f $curdir/slitaz-rootfs$prefix/pkgs/start.sh		
  post_inst_fixes $pkg
}
determine_mode_than_install_packages(){ 
  source_folder_or_file=${1:-slitaz-packages}
  if [ ! "${source_folder:0:1}" == "/" ]; then
    source_folder=$curdir/$source_folder
  fi
  
  if [ "$xmode" == "local" ]; then
    install_local_pkg $source_folder_or_file
  else
   install_online_pkg $source_folder_or_file
  fi
}
get_folder_description(){
	
  case `dirname $1` in
    slitaz-packages)
      folder_description="slitaz package"; ;; #These were orginally called core packages
    pet-packages)  
      folder_description="pet package"; ;; #Recommend using the converted alien's folder instead
    slitaz-dependencies)
      folder_description="slitaz dependency"; ;;  #This folder isn't typically instended for direct installation
    slitaz-base)
      folder_description="slitaz base package"; ;;  #This folder is typically used in place of the live slitaz CD 
    slitaz-post-patch-packages) 
      folder_description="slitaz post patch packages"; ;;  #Normally we don't need this folder
    slitaz-preinst-pkg)
      folder_description="slitaz pre-install package"; ;;  #Normally we don't need this folder 
    *)
      folder_description="package"; ;;  #Normally we don't need this folder   
  esac     
}
do_folder_missing_action(){
  case `dirname $1` in
    slitaz-packages)
      pkg_type="slitaz package"; ;; #These were orginally called core packages
    pet-packages)
      pkg_type="pet package"; ;; #Recommend using the converted alien's folder instead
    slitaz-dependencies)
      echo 'the folder slitaz-dependencies is empty'; ;;
    slitaz-base)
       echo 'the folder slitaz-base is empty'; ;;   
    slitaz-post-patch-packages)  
       echo 'the folder slitaz-post-patch-packages is empty'; ;;   
    slitaz-preinst-pkg)
       echo 'the folder slitaz-preinst-pkg is empty'; ;;   
    *)
       echo 'the folder $1 is empty'; ;;    
  esac   	
}
install_local_pkgs(){ #s243a: added "s" to the function name
	
  if [ $# -eq 0 ]; then
    set "$slitaz_packages_dir" "$special_packages_dir"
  fi	
	
  for aDir in "$@"; do

    if [ ! "${aDir:0:1}" == "/" ]; then
      fullpath_aDir=$curdir/$aDir
    else
	  fullpath_aDir=$aDir
	fi #TODO consider adding a case if the path starts with a "."
	#assigns folder_description
	get_folder_description #This is use din the echo statment to say what packages we are installing (or are missing)
    if [ $(find $fullpath_aDir -type f -name "*.tazpkg" | wc -l) -eq 0 ]; then
      echo "$folder_description is missing."
	  continue
	  #read -p "Press enter to continue" #TODO add some exit or paus e logic
	fi 
    for pkg in $(find $fullpath_aDir -type f -name "*.tazpkg" | sort -r)
	do
      echo "Processing $folder_description: $(basename $pkg)"
      install_pkg "$pkg"
      post_inst_fixes $pkg
    done
  done
	
}
get_install_pkg(){

  pkg="$1"

  echo "#!/bin/sh
cd $prefix/pkgs
tazpkg get-install $pkg
" > $curdir/slitaz-rootfs$prefix/pkgs/start.sh #$curdir/slitaz-rootfs/start.sh

  chmod +x $curdir/slitaz-rootfs$prefix/pkgs/start.sh
  #read -p "Press enter to continue" 
  chroot $curdir/slitaz-rootfs $prefix/pkgs/start.sh 
  rm -f $curdir/slitaz-rootfs$prefix/pkgs/start.sh		
  post_inst_fixes $pkg
}

install_online_pkg(){
  if [ ! -f  $curdir/package-cloud.txt ]; then
    echo "Package list is missing."
    exit
  else

	if [ $(find $curdir/special-packages -type f -name "*.tazpkg" | wc -l) -eq 0 ]; then
	  echo "Special tazpup package is missing."
	  exit
	fi

	for pkg in $(cat $curdir/package-cloud.txt | tr '\n' ' ')
	do
	  echo "Processing core package: $(basename $pkg)"
	  get_install_pkg "$pkg"
	done
	
	for pkg in $(find $curdir/special-packages -type f -name "*.tazpkg" | sort -r)
	do
	  echo "Processing special package: $(basename $pkg)"
	  install_pkg "$pkg"
      post_inst_fixes $pkg
	done
      
fi	
}


install_pet_pkg(){
# source $curdir/make-tazpup_functions.sh

  pkg="$1"
  bname="$(basename $pkg)"
	
  cp -a -u $pkg $curdir/slitaz-rootfs/$bname

  if [ $xforced -eq 1 ]; then
    line="tazpet /$bname --forced"
  else
    line="tazpet /$bname"
  fi

  echo "#!/bin/sh
$line
" > $curdir/slitaz-rootfs/start.sh #TODO add a check to first see if we are mounted and if not mount the requisit folders

  chmod +x $curdir/slitaz-rootfs/start.sh
  chroot $curdir/slitaz-rootfs/ /start.sh 
  rm -f $curdir/slitaz-rootfs/$bname
  rm -f $curdir/slitaz-rootfs/st# source $curdir/make-tazpup_functions.sh
art.sh		

}
add_locks_and_blockFiles(){
  if [ "$xmode" == "local" ]; then
    touch $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/locked-packages
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-local.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-skipdep.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-skipremovedep.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-dontbreak.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-skipupdate.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-editreceipt.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-autoconfirm.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-skiprefresh.lock
else
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-dontbreak.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-skipremovedep.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-skipupdate.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-editreceipt.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-autoconfirm.lock
    touch $curdir/slitaz-rootfs$prefix/tmp/tazpkg-skiprefresh.lock
    cp -f $curdir/tazpup-core-files/slitaz/var/lib/tazpkg/blocked-packages.list $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/blocked-packages.list 
    cp -f $curdir/tazpup-core-files/slitaz/var/lib/tazpkg/locked-packages $curdir/slitaz-rootfs$prefix /var/lib/tazpkg/locked-packages
fi
}

make_pupcore(){

  mkdir -p $curdir/slitaz-rootfs$prefix/usr/share/pupcore 2> /dev/null
  cp -f $curdir/tazpup-core-files/puppy/bin/ps $curdir/slitaz-rootfs$prefix/usr/share/pupcore/ps.bak
  cp -f $curdir/tazpup-core-files/puppy/sbin/init $curdir/slitaz-rootfs$prefix/usr/share/pupcore/init.bak
  cp -f $curdir/tazpup-core-files/puppy/sbin/losetup $curdir/slitaz-rootfs$prefix/usr/share/pupcore/losetup.bak

  cp -f $curdir/tazpup-core-files/slitaz/bin/gnome-alsamixer $curdir/slitaz-rootfs$prefix/usr/share/pupcore/gnome-alsamixer.bak
  cp -f $curdir/tazpup-core-files/slitaz/etc/inittab $curdir/slitaz-rootfs$prefix/usr/share/pupcore/inittab.bak
  cp -f $curdir/tazpup-core-files/slitaz/etc/init.d/daemon $curdir/slitaz-rootfs$prefix/usr/share/pupcore/daemon.bak
  cp -f $curdir/tazpup-core-files/slitaz/etc/init.d/bootopts.sh $curdir/slitaz-rootfs$prefix/usr/share/pupcore/bootopts.sh.bak
	
}

remove_some_slitaz(){

if [ -z $prefix ]; then	#TODO ad or case for when we want to enter this if block but the prefix exists
  rm -rf $curdir/slitaz-rootfs$prefix/lib/modules/*

  for pkg2 in $(ls -1 $curdir/slitaz-rootfs/var/lib/tazpkg/installed/ | grep -E "^linux" | tr '\n' ' ')
  do
    chroot $curdir/slitaz-rootfs$prefix tazpkg remove $pkg2
  done

  for pkg2 in $(ls -1 $curdir/slitaz-rootfs/var/lib/tazpkg/installed/ | grep -E "^firmware-" | tr '\n' ' ')
  do
    chroot $curdir/slitaz-rootfs$prefix tazpkg remove $pkg2
  done

  if [ -f $curdir/remove-builtin.txt ]; then
	for pkg2 in $(cat $curdir/remove-builtin.txt)
	do
	 chroot $curdir/slitaz-rootfs$prefix tazpkg remove $pkg2
	done
  fi
fi
rm -f $curdir/slitaz-rootfs/etc/dialogrc

}

extractfs() {
  one=$1
  #$prefix2=${one:-""} #If we have a prefix it is usually empty but in theory 
  if [ ! -d $curdir/slitaz-rootfs ]; then
    mkdir $curdir/slitaz-rootfs
  fi

  (busybox unlzma -c $1 || cat $1 ) 2>/dev/null | (cd $curdir/slitaz-rootfs; busybox cpio -idmu > /dev/null)

}

#extractfs_prefix is not used yet. It will be be used if one want to use a seperate iso for the build than the build system
extractfs_prefix() { #TODO use options to combine this with the above function
  #one=$1 #TODO allow prefix2 to be defined as an ninput argument
  #$prefix2=${one:-""} #If we have a prefix it is usually empty but in theory 
  if [ ! -d $curdir/slitaz-rootfs$prefix ]; then
    mkdir $curdir/slitaz-rootfs$prefix
  fi

  (busybox unlzma -c $1 || cat $1 ) 2>/dev/null | (cd $curdir/slitaz-rootfs$prefix2; busybox cpio -idmu > /dev/null)

}

select_local(){
  if [ -z "*IMG" ]; then	
    IMG="$(Xdialog --stdout --title "$LABEL1 Select Slitaz image file" --fselect $HOME 0 0)"

    if [ $? -ne 0 ]; then
      echo "Operation cancelled"
    exit
    fi

    if [ "$IMG" == "" ]; then
      echo "No image file selected"
      exit
    fi
  fi
}


download_iso(){
	
  wget -4 -t 2 -T 20 --waitretry=20 --spider -S "$WEBSITE/$LIVECD" 	

  if [ $? -ne 0 ]; then
    echo "Failed to reach $WEBSITE"
    exit
  fi

  wget "$WEBSITE/$LIVECD" -O $curdir/$LIVECD

  if [ $? -ne 0 ]; then
    echo "Downloading Slitaz live cd failed"
    rm -f $curdir/$LIVECD
    exit
  fi

  IMG="$curdir/$LIVECD"
}
select_build_mode(){
  if [ -z "$xmode" ]; then
    Xdialog --title "TazPuppy Builder" --ok-label "LOCAL" --cancel-label "ONLINE" --yesno "Select mode for building TazPuppy\n\nLOCAL - Build TazPuppy offline using collection of files and packages\nONLINE - Build TazPuppy using slitaz repo. Internet connection required\n\nNOTE: Both modes requires Puppy ISO file" 0 0
    retval3=$?# source $curdir/make-tazpup_functions.sh


    if [ $retval3 -eq 255 ]; then
      echo "Operation cancelled"
      exit
    fi

    if [ $retval3 -eq 0 ]; then
      LABEL1="Local Build:"
      xmode="local"
      select_local
    elif [ $retval3 -eq 1 ]; then
      LABEL1="Online Build:"
     xmode="online"
    fi
  fi
 }
 

select_interact_mode(){ 
  if [ -z "$xinteractive" ]; then  
    Xdialog --title "TazPuppy Builder" --ok-label "Yes" --cancel-label "No" --yesno "Allow the post install script packages to interact?" 0 0
    retval3=$?

    if [ $retval3 -eq 255 ]; then
      xinteractive=0
      exit
    fi

    if [ $retval3 -eq 0 ]; then
      xinteractive=1
      else
      xinteractive=0
    fi
  fi
}
select_force_custom(){
  if [ -z "$xforced" ]; then 
    Xdialog --title "TazPuppy Builder" --ok-label "Yes" --cancel-label "No" --yesno "Force install custom pet package?" 0 0
    retval3=$?

    if [ $retval3 -eq 0 ]; then
      xforced=1
    else
      xforced=0 
    fi
  fi
}
select_copy_tazpkg_in_build_env(){
  if [ -z "$cpytaz" ]; then
    Xdialog --title "TazPuppy Builder" \
            --ok-label "Yes" \
            --cancel-label "No" \
            --yesno \
"Copy tazpkg into the build system? This is not necessary if included in build ISO (i.e. SliTaz iso)" \
0 0

    retval3=$?

    if [ $retval3 -eq 0 ]; then
      cpytaz=1
    else
      cpytaz=0 
    fi
  fi	
}
select_copy_tazpkg_in_target_env(){
  if [ -z "$cpytaz_target" ]; then
    Xdialog --title "TazPuppy Builder" \
            --ok-label "Yes" \
            --cancel-label "No" \
            --yesno \
"Copy tazpkg into the target environment? This will overwrite tazpkg files if they are already installed in the target enviornment." \
0 0

    retval3=$?

    if [ $retval3 -eq 0 ]; then
      cpytaz_target=1
    else
      cpytaz_target=0 
    fi	
  fi 
}
post_inst_fixes_coreutils(){
  arg_1=$1
  pfk_local=${arg_1:-$prefix}
  if [ -f $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/coreutils ]; then
    #TODO perhaps we don't want to do this if df-Full already exists. 
    echo '#!/bin/sh
	exec df $@' > $curdir/slitaz-rootfs$prefix/usr/bin/df-FULL
	chmod +x $curdir/slitaz-rootfs$prefix/usr/bin/df-FULL
  fi
}
post_inst_fixes_gzip(){
     if [ -f $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/grep ]; then    
       rm -f  $curdir/slitaz-rootfs$prefix/bin/gzip
     fi	
}
post_inst_fixes_lzma(){
    if [ -f $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/lzma ]; then
      rm -f  $curdir/slitaz-rootfs$prefix/bin/lzma
      rm -f  $curdir/slitaz-rootfs$prefix/bin/unlzma
      rm -f  $curdir/slitaz-rootfs$prefix/bin/lzcat      
    fi
}
post_inst_fixes_xz(){
    if [ -f $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/xz ]; then
      rpost_inst_fixes_lzma
    fi
}
post_inst_fixes(){
  arg_1=$1
  #arg_2=$2
  pkg_local=${arg_1:-$pkg}
  pfk_local=${prefix:-$2}
  
  if [ -z "${pkg_local##coreutils}" ]; then
    post_inst_fixes_coreutils $pfk_local
  fi

  if [ -z "${pkg_local##gzip}" ]; then
    post_inst_fixes_gzip $pfk_local
  fi
  if [ -z "${pkg_local##lzma}" ]; then #Added by s243a
    post_inst_fixes_lzma $pfk_local
  fi
  if [ -z "${pkg_local##xz}" ]; then #Added by s243a
     post_inst_fixes_xz $pfk_local
  fi  
}
select_pup_img(){ 
  ISO_Var_Name=${1:-IMGPUP}  
  if [ -z "$1"]; then
    ISO_Path=$IMGPUP
  else
    ISO_Path=""
  fi
  if [ -z "$ISO_Path" ]; then
    ISO_Path="$(Xdialog --stdout --title "$LABEL1 Select Puppy image file" --fselect $HOME 0 0)"

    if [ $? -ne 0 ]; then
      echo "Operation cancelled"
      exit
    fi

    if [ "$ISO_Path=" == "" ]; then
      echo "No puppy image file selected. Press enter to continue or cntrl-c to exit"
      #exit #TODO Maybe prompt people if they want to exit
    fi
  fi
  eval "$ISO_Var_Name=$ISO_Path"
}


extract_kernal_modules(){
  if [ -z "$IMGPUP" ]; then	
	select_pup_img
  fi
  echo "Mounting $(basename $IMGPUP)..."

  mount -o ro $IMGPUP /mnt/wktaz
  #mount $IMGPUP /mnt/wktaz -o loop


  if [ $? -ne 0 ]; then
    echo "Mounting puppy image failed"
    exit
  fi

  rootfslist="$(find /mnt/wktaz -type f -name "*.sfs")"

  if [ "$rootfslist" == "" ]; then
    echo "Not a puppy disc image"
    umount /mnt/wktaz
    exit
  fi

  echo "Copying puppy kernel...."

  #cp -f /mnt/wktaz/vmlinuz $curdir/tazpup-preiso/ 
  cp -f /mnt/wktaz/vmlinuz $curdir/tazpup-livecd-files #Target changed from tazpup-preiso to tazpup-livecd-files so that we can delete tazpup-preiso withiout woring about deleating vmlinuz

  echo "Searching for kernel modules..."

  mkdir -p $curdir/kernel-modules/lib

  for file1 in $(find /mnt/wktaz -type f -name "*.sfs")
  do

  mount -t squashfs $file1 /mnt/wksfs

  if [ $? -eq 0 ]; then

    if [ -d /mnt/wksfs/lib/modules ]; then
      echo "Copying kernel modules from $(basename $file1) to rootfs..."
      cp -rf /mnt/wksfs/lib/modules $curdir/kernel-modules/lib/
      mkdir -p $curdir/kernel-modules/var/lib/tazpkg/installed/linux	
      touch $curdir/kernel-modules/var/lib/tazpkg/installed/linux/files.list 
	
echo 'PACKAGE="linux"
VERSION=""
CATEGORY="misc"
SHORT_DESC="Linux kernel (compiled for puppy linux)"
WEB_SITE="http://puppylinux.org/"
MAINTAINER="nobody@slitaz.org"
DEPENDS="linux-modules"
' > $curdir/kernel-modules/var/lib/tazpkg/installed/linux/receipt
	 
	 
	 mkdir -p $curdir/kernel-modules/var/lib/tazpkg/installed/linux-modules

echo 'PACKAGE="linux-modules"
VERSION=""
CATEGORY="misc"
SHORT_DESC="Linux kernel modules(compiled for puppy linux)"
WEB_SITE="http://puppylinux.org/"
MAINTAINER="nobody@slitaz.org"
DEPENDS=""
' > $curdir/kernel-modules/var/lib/tazpkg/installed/linux-modules/receipt	 
	 
      xcurdir="$(echo "$curdir" | sed "s#\/#\\\/#g")" 
	 
      find $curdir/kernel-modules/lib/ -type f -name "*" | sed -e "s#$xcurdir\/kernel-modules\/lib\/#\/lib\/#g" > $curdir/kernel-modules/var/lib/tazpkg/installed/linux-modules/files.list
	 
    fi
	
    if [ -d /mnt/wksfs/etc/modules ]; then
      cp -rf /mnt/wksfs/etc/modules $curdir/kernel-modules/etc/
    fi
		
    umount /mnt/wksfs
  fi

  done
  re_extract_kernal=0 #Added by s243a
  umount /mnt/wktaz	
}	
prepare_working_folders(){
  echo "Preparing working folders..."

  if [ ! -d $curdir/slitaz-livecd-wkg ]; then
    mkdir $curdir/slitaz-livecd-wkg
  fi

  if [ ! -d $curdir/tazpup-preiso ]; then
    mkdir $curdir/tazpup-preiso
  fi

  if [ ! -d /mnt/wktaz ]; then
    mkdir /mnt/wktaz
  fi

  if [ ! -d /mnt/wksfs ]; then
    mkdir /mnt/wksfs
  fi
}

select_re_extract_kernal_Modules(){
  if [ ! -f $curdir/slitaz-livecd-wkg/ ]; then
      re_extract_kernal=1
  fi	
  if [ -z "$re_extract_kernal" ]; then
    Xdialog --title "TazPuppy Builder" \
            --ok-label "Yes" \
            --cancel-label "No" \
            --yesno \
"Re-extract Kernal modules?" \
0 0

    retval3=$?

    if [ $retval3 -eq 0 ]; then
      re_extract_kernal=1
    else
      re_extract_kernal=0 
    fi	
  fi
  if [ $re_extract_kernal -eq 1 ]; then
    rm $curdir/kernel-modules
    mkdir -p $curdir/kernel-modules
    extract_kernal_modules
  fi
   
}
select_full_clearn(){
  if [ ! -z cpytaz_target ]; then
    Xdialog --title "TazPuppy Builder" \
            --ok-label "Yes" \
            --cancel-label "No" \
            --yesno \
"Clean All Folders?" \
0 0

    retval3=$?

    if [ $retval3 -eq 0 ]; then
      cpytaz_target=1
    else
      cpytaz_target=0 
    fi	
  fi 
}

clean_up_some(){
		
  if [ -d $curdir/slitaz-rootfs ]; then
    unmount_rootfs_binds
    echo "Deleting slitaz-rootfs..."
    rm -rf $curdir/slitaz-rootfs
  fi
  select_re_extract_kernal_Modules
  if [ $cpytaz_target -eq 0 ]; then
    if [ -d $curdir/tazpup-preiso ]; then
      echo "Deleting tazpup-preiso..."
      rm -rf $curdir/tazpup-preiso
    fi
    if [ -d $curdir/kernel-modules ]; then
      echo "Deleting kernel-modules..."
      rm -rf $curdir/kernel-modules
    fi
  fi
  if [ -f $curdir/custom-tazpup.iso.md5 ]; then
    echo "Deleting custom-tazpup.iso.md5..."
    rm -f $curdir/custom-tazpup.iso.md5
  fi  
  if [ -d $curdir/slitaz-dload ]; then
    echo "Deleting slitaz-dload..."
    rm -rf $curdir/slitaz-dload
  fi

  #These are used in the sandbox
  #if [ -d $curdir/tazpup-core-files/slitaz-packages-fs ]; then
  #  echo "Deleting slitaz-packages-fs..."
  #  rm -rf $curdir/tazpup-core-files/slitaz-packages-fs
  #fi

  if [ -f $curdir/slitaz-rolling-core.iso ]; then
    echo "Deleting slitaz-rolling-core.iso..."
    rm -f $curdir/slitaz-rolling-core.iso
  fi
  if [ -d $curdir/slitaz-livecd-wkg ]; then
    rm -rf $curdir/slitaz-livecd-wkg
  fi
  
  
  #rm -f $curdir/tazpup-core-files/installed-isolated.md5
  #rm -f $curdir/tazpup-core-files/installed-isolated.info

  #rm -f $curdir/package-deps.txt
  #rm -f $curdir/package-listed

  if [ -f $curdir/custom-tazpup.iso ]; then
    echo "Deleting custom-tazpup.iso..."
    rm -f $curdir/custom-tazpup.iso
  fi
	
}
#function moved to: $curdir/build-scripts/add_puppy_jwm_files.sh
#add_puppy_jwm_files(){
#	
#	#cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/ptheme/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null
#	
#	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	
#
#	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/ptheme/* \
#	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	
#
#	mkdir -p $curdir/tazpup-core-files/pkg-managers/petget/usr/local/petget/
#	cp --remove-destination -arf $curdir/tazpup-core-files/pkg-managers/petget/usr/local/petget/pinstall.sh \
#	                             $curdir/slitaz-rootfs$prefix/usr/local/petget/pinstall.sh 2>/dev/null
#}
clean_cache_and_logs(){
  #dont include to main sfs
  rm -rf $curdir/slitaz-rootfs$prefix/var/cache/tazpkg/* 2>/dev/null
  rm -rf $curdir/slitaz-rootfs$prefix/var/log/slitaz/* 2>/dev/null
  rm -rf $curdir/slitaz-rootfs$prefix/var/log/*.log 2>/dev/null
  rm -rf $curdir/slitaz-rootfs$prefix/var/tmp/* 2>/dev/null
  rm -rf $curdir/slitaz-rootfs$prefix/tmp/* 2>/dev/null
  rm -f $curdir/slitaz-rootfs$prefix/etc/rc.d/PUPSTATE
}
update_icon_caches(){
   #trap update_system_database_cleanup EXIT SIGKILL SIGTERM
   update_icon_caches_fd_path="/tmp/mk-tazpup_fns/update_icon_caches/fd"
   mkdir -p "$update_icon_caches_fd_path"
   exec 11<> "$update_icon_caches_fd_path"/fd_11
   while IFS=$'\0' read  -r -d $'\0' -u11 theme_index_path_prefixed ; do
     theme_index_path=`dirname "${theme_index_path_prefixed#$curdir/slitaz-rootfs$prefix}"`
     chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/gtk-update-icon-cache "$theme_index_path"
   done 11< <( find "$curdir/slitaz-rootfs$prefix/" -type f -name 'index.theme' -print0 ) #https://blog.famzah.net/2016/10/20/bash-process-null-terminated-results-piped-from-external-commands/
      exec 11>&-
}
update_system_databases(){
  echo "Updating system database..."
  chroot "$curdir/slitaz-rootfs$prefix/" update-ca-certificates
  chroot "$curdir/slitaz-rootfs$prefix/" tazpkg recharge
  chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/update-desktop-database /usr/share/applications
  chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/update-mime-database /usr/share/mime
  
  update_icon_caches #Replaces: chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/gtk-update-icon-cache /usr/share/icons/hicolor

  chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas
  chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/gdk-pixbuf-query-loaders --update-cache
  chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/gio-querymodules /usr/lib/gio/modules	
  chroot "$curdir/slitaz-rootfs$prefix/" /usr/bin/fc-cache -f
}
is_array(){ #Pass the name of the variable to this function (not the variable it's self)
  #https://stackoverflow.com/questions/14525296/bash-check-if-variable-is-array	
  #http://fvue.nl/wiki/Bash:_Detect_if_variable_is_an_array	
  #https://www.computerhope.com/unix/bash/declare.htm
  if [ $(declare -p $1 | grep -q '^declare \-a') ]; then
  #Variable is an array
   return 1 #This is opposite standard unix exit codes: https://shapeshed.com/unix-exit-codes/
  else
  #variable is not an array
   return 0 #This is opposite standard unix exit codes: #http://www.tldp.org/LDP/abs/html/exitcodes.html
  fi
}
default_applications(){
  case $1 in
  text_editors)
  ;;
  esac	
}
close_fd_12() { exec 12>&- ; }
install_pkgs_fm_dir(){ #Specify full path to directory as first input argument
   mkdir -p "/tmp/make-tazpup/functions/fd"
   exec 12<> "/tmp/make-tazpup/functions/fd/fd_12"
   while IFS=$'\0' read  -r -d $'\0' -u12 aPkg ; do
   if [ -L "$aPkg" ]; then
       aPkg=`readlink "$aPkg"` 
   fi
   if [ -f "$aPkg" ]; then
     install_pkg "$aPkg"
   fi
   done 12< <( find "$1" -wholename '*'"$branch/"'*.tazpkg' -print0 ) #https://blog.famzah.net/2016/10/20/bash-process-null-terminated-results-piped-from-external-commands/
   exec 12>&-
}
install_woofCE_pkg(){
	aPKG="$1"
	#"$curdir/slitaz-rootfs$prefix/"
	if [ ! -f "$curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/$aPkg" ]; then
      local aPkg=$1
      source_pkg_dir="$curdir/tazpup-core-files/packages/woof-CE-19-03-06"
      target_dir="$curdir/slitaz-rootfs$prefix"
      pinst_dir="$target_dir"/desktop_pkg_inst_scripts
      cp --remove-destination -arf "$source_pkg_dir/$aPkg"/* \
                                   "$target_dir"/ #2>/dev/null	
      if [ -f $source_pkg_dir/install.sh ]; then
        chroot "$curdir/slitaz-rootfs$prefix/" /pinstall.sh   
        #mkdir -p $curdir/slitaz-rootfs$prefix/ #Already done above
        mv "$target_dir/pinstall.sh" "$pinst_dir/$aPkg"_pinstall.sh
      fi
    fi
}

#pdiag-20171205|pdiag|20171205||Utility|44K||pdiag-20171205.pet||Consolidated diagnostic data collector||||

process_pet_specs(){
	local specs_txt=`cat "$1" | head --lines=1`
	#https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
	#http://www.linuxquestions.org/questions/programming-9/bash-shell-script-split-array-383848/#post3270796
	specs=(${specs_txt//|/ })
	process_pet_specs_FULL_NAME=specs[0]	
	process_pet_specs_PKG_NAME=[1]
	process_pet_specs_VERSION=specs[2]
	process_pet_CATEGORY=specs[4]
	process_pet_SIZE=specs[5]	
	process_pet_BRANCH=specs[6] #Repository Folder
	process_pet_FILE_NAME=specs[7] #File Namer
	process_pet_FILE_DEPENDS=specs[8]
	process_pet_FILE_SHORT_DESC=specs[9]
	process_pet_FILE_COMPILED WITHIN=specs[10]
	process_pet_FILE_COMPAT_DISTRO_VER=specs[11]	
	process_pet_REPO_NAME=specs[12]
}

pet_specs_to_tazpkg_installed(){
  local pkg_path=$1
  local pkg_name=`basename $pkg_path` #TODO: add option to use petspec instead for this
  local web_site=${2:-"http://puppylinux.org/"} #TODO: add option to use petspec instead for this
  local maintainer=${3:-"nobody@slitaz.org"} #TODO: add option to use petspec instead for this
  
  
  process_pet_specs $pkg_path
  echo 'PACKAGE="$process_pet_specs_PKG_NAME"
VERSION="$process_pet_specs_VERSION"
CATEGORY="$process_pet_CATEGORY"
SHORT_DESC="$process_pet_SHORT_DESC"
WEB_SITE="$web_site"
MAINTAINER="$maintainer"
DEPENDS="$process_pet_FILE_DEPENDS"
' > $curdir/litaz-rootfs$prefix/var/lib/tazpkg/installed/linux-modules/receipt #TODO add che for pkgmanager type and suport for toher package managers	 
	 
      xcurdir="$(echo "$curdir" | sed "s#\/#\\\/#g")" 
	 
      find $pkg_name -type -name "*" > $curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/$pkg_name/files.list-tmp
      cat "$curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/$pkg_name/files.list" | 
   touch "$curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/$pkg_name/files.list"
   while read  -r -d $'\n' $aFile_prefixed ; do
     if [ ! -d "$aFile" ]; then
       aFile=${aFile_prefixed#"$pkg_path"}
       echo $aFile > "$curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/$pkg_name/files.list"
     fi
   done <"$curdir/slitaz-rootfs$prefix/var/lib/tazpkg/installed/$pkg_name/files.list-tmp" 
}
install_pkgs_fm_dir(){ #Specify full path to directory as first input argument
   mkdir -p "/tmp/make-tazpup/functions/fd"
   exec 12<> "/tmp/make-tazpup/functions/fd/fd_12"
   while IFS=$'\0' read  -r -d $'\0' -u12 aPkg ; do
   if [ -L "$aPkg" ]; then
       aPkg=`readlink "$aPkg"` 
   fi
   if [ -f "$aPkg" ]; then
     install_pkg "$aPkg"
   fi
   done 12< <( find "$1" -wholename '*'"$branch/"'*.tazpkg' -print0 ) #https://blog.famzah.net/2016/10/20/bash-process-null-terminated-results-piped-from-external-commands/
   exec 12>&-
}
