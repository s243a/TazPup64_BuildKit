#!/bin/bash
curdir=${curdir:-"`realpath $(pwd)/../..`"} 
source $curdir/defaults
prefix=${prefix:-"/64"}
branch=${branch:-next64}
xinteractive=${xinteractive:-0}
PKGS_TO_CLEAN_DESKTOP=( "$firefox-official" )

clean_desktop_files_in_pkg(){
  DLPKG_NAME=$1
  for ONEDOT in `grep $curdir/slitaz-rootfs$prefix'share/applications/.*\.desktop$' \
                 /var/lib/tazpkg/installed/${DLPKG_NAME}.list | tr '\n' ' '` #121119 exclude other strange .desktop files.
  do
 #https://specifications.freedesktop.org/desktop-entry-spec/latest/ar01s07.html
    sed -i 's| %u|| ; s| %U|| ; s| %f|| ; s| %F||' $ONEDOT 
  done
}

clean_desktop_files_in_pkgs(){
   ary_name=$1
   for dt_file in ${"$ary_name"[@]}; do
      clean_desktop_files_in_pkg dt_file
   done	
}
clean_desktop_files_in_pkgs PKGS_TO_CLEAN_DESKTOP
