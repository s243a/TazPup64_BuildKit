#!/bin/bash
curdir=`realpath $(pwd)/../..` 
source $curdir/defaults
prefix=${prefix:-"/64"}
branch=${branch:-next64}
xinteractive=${xinteractive:-0}
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
for woof_pkg in "${WOOF_CE_PKGS_TO_INSTALL[@]}"; do
  install_woofCE_pkg "$woof_pkg"
done
