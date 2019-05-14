curdir=`pwd`
s_rootfs="rootfs" 
alt_s_rootfs="/mnt/+mnt++root+Downloads+xslacko-slim-4.4r25.iso+puppy_xslacko_4.4.sfs"
if [ -d "$alt_s_rootfs=" ]; then
  retry=1 #Default action for an array
fi
prefix=""
action="mv"

chroot_remove_builtin=0
no_mount_rootfs=1

#After we remove packages we might install some replacement versions
#When distro not specified in path look for pkg dirs in dir containing distro name in this order
post_rm_pkg_dirs=( "pupngo" ) #Replaceing bash with pupngo's version can save a fair bit of space
#When arch not specified in path look for pkg arch dir containing distro name in this order
arches=( "i386" "no-arch" "i486" "i586" "i686" ) 


#Applications
#Let's remove these applications and maybe put them into an sfs
ALL=()
ALL_ArrNames=()

A_SystemCore=( "bash")
ALL+=( "${A_SystemCore[@]}" )
ALL_ArrNames+=( "A_SystemCore" )

curdir=`pwd`
rootfs="$s_rootfs"
prefix=""
xinteractive=1

Post_Remove_Install_Fm_Dir=( \
"i386/pupngo/bash-4.2" \
)

#source pkgs_arry

#Coppies a more recent version of remove_built_in
#and also a list of icu related files (to be removed) which aren't associated
#with any packages
pre_remove_patch="pre_remove_patch"
cp --remove-destination -arf $pre_remove_patch/* \
                                 $s_rootfs/ 2>/dev/null 
source trim_puppy_functions.sh




if [ no_mount_rootfs -eq 0 ]; then
  trap unmount_vfs EXIT
  trap unmount_vfs SIGKILL
  trap unmount_vfs SIGTERM


  echo "PUPMODE='2'" > $curdir/$rootfs$prefix/etc/rc.d/PUPSTATE
  mkdir -p $curdir/$rootfs/proc;
  mkdir -p $curdir/$rootfs/sys

  mount -o rbind /proc $curdir/$rootfs/proc
  mount -t sysfs none $curdir/$rootfs/sys
  if [ $xinteractive -eq 1 ]; then
    echo "Removing block device files..."
    #rm -rf $curdir/$rootfs/dev/*
    #mount bind -t devtmpfs none $curdir/$rootfs/dev
    mount -o rbind /dev $curdir/$rootfs/dev
    cp -f /etc/resolv.conf $curdir/$rootfs/etc/resolv.conf 
  fi
  
else
  trap close_file_descriptors EXIT
  trap close_file_descriptors SIGKILL
  trap close_file_descriptors SIGTERM
fi



dissect_rootfs




for pkg_dir in "${Post_Remove_Install_Fm_Dir[@]}"; do
  if [ "${pkg_dir:0:1}" = "." ]; then
    pkg_dir="$curdir/${pkg_dir:1:}"
  elif [ ! "${pkg_dir:0:1}" = "/" ]; then
        rel_path=${pkg_dir%/*}
        pkg_name=`basename "$pkg_dir"`
        #pkg_dir="$curdir/post_patch/$arch/pupngo/$pkg_dir/$pkg_dir"
        if [ -z "$rel_path" ]; then
          for pkg_arch in "${arches[@]}" "."; do
            for pkg_distro in "${post_rm_pkg_dirs[@]}" "."; do
              rel_path="$pkg_arch/$distro"
              a_pkg_dir="$curdir/post_patch/$pkg_arch/$pkg_distro/$pkg_name"
              if [ -d "a_pkg_dir" ] || [ -d `readlink "$a_pkg_dir"` ]; then
                 pkg_dir="$a_pkg_dir"
                 break 2;
              fi
                 
            done
          done 
        else
          echo "nothing to do"
          for test_rel_path in "$rel_path" "post_patch/$rel_path"; do
            pkg_dir="$curdir/$test_rel_path/$pkg_name"
            if [ -d "$pkg_dir" ]; then
              break
            fi
          done
        fi
  fi
  inst_builtin_fm_dir "$pkg_dir"
done

if [ "$no_mount_rootfs" -eq 0 ]; then
  if [ chroot_remove_builtin = 1 ];then
    chroot "$s_rootfs_prefixed" remove_builtin "${ALL[@]}"
  fi
  if [ "$(mount | grep "$curdir/$rootfs/dev")" != "" ]; then
   umount -l $curdir/$rootfs/dev
  fi	

  if [ "$(mount | grep "$curdir/$rootfs/sys")" != "" ]; then
   umount -l $curdir/$rootfs/sys
  fi	
  if [ "$(mount | grep "$curdir$rootfs/proc")" != "" ]; then
   umount -l $curdir/$rootfs/proc
  fi
fi
