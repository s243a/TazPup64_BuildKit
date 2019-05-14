#!/bin/bash
curdir=`realpath $(pwd)/../..` 
prefix="/64"
xinteractive=0
update_icon_caches_fd_path=/tmp/make-tazpup/functions/fd/ #11 for the file descriptor
update_system_database_cleanup(){
  if [ -f "$update_icon_caches_fd_path" ]; then
    exec 11>&-
  fi
  if [ $unmount_when_finished -eq 1 ]; then
    umount -l $curdir/slitaz-rootfs$prefix/dev 2>/dev/null
    umount -l $curdir/slitaz-rootfs$prefix/sys	
    umount -l $curdir/slitaz-rootfs$prefix/proc	
  fi
}
update_icon_caches(){
   trap update_system_database_cleanup EXIT SIGKILL SIGTERM
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

if mountpoint -q $curdir/slitaz-rootfs$prefix/proc; then 
  echo "/proc is a mount point"
  unmount_when_finished=1
elif mountpoint -q $curdir/slitaz-rootfs$prefix/sys; then 
  echo "/sys is a mount point"
  unmount_when_finished=1
elif mountpoint -q $curdir/slitaz-rootfs$prefix/dev; then 
  echo "/dev is a mount point"
  unmount_when_finished=1
else
  unmount_when_finished=0
fi
if [ ! -z $prefix ]; then
  
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

update_system_databases
