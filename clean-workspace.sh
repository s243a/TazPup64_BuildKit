#!/bin/sh

curdir=`pwd`

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

if [ -d $curdir/slitaz-build-data/slitaz-packages-fs ]; then
echo "Deleting slitaz-packages-fs..."
rm -rf $curdir/slitaz-build-data/slitaz-packages-fs
fi

if [ -f $curdir/slitaz-rolling-core.iso ]; then
echo "Deleting slitaz-rolling-core.iso..."
rm -f $curdir/slitaz-rolling-core.iso
fi

rm -f $curdir/slitaz-build-data/installed-isolated.md5
rm -f $curdir/slitaz-build-data/installed-isolated.info

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

