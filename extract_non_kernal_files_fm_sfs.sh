#!/bin/sh
extract_non_kernal_files_fm_sfs(){
  select_pup_img() ISO_IMG
  ISO_IMG=$1

  echo "Mounting $(basename $ISO_IMG)..."

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
    #exit
    return 1 #In bash non zero return values are failures.  
  fi

  echo "Copying puppy non-kernel files...."

  echo "Searching for non-kernel modules..."

  mkdir -p $curdir/kernel-modules/lib

  for file1 in $(find /mnt/wktaz -type f -name "*.sfs")
  do

  mount -t squashfs $file1 /mnt/wksfs

  if [ $? -eq 0 ]; then

    if [ -d /mnt/wksfs/lib/modules ]; then
      echo "Copying kernel modules from $(basename $file1) to rootfs..."
sdfgfsdgf pepp   
	 
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
