#!/bin/sh
main_desktop_defaults_and_files(){
  curdir=${curdir:-$(realpath "${pwd}/../..)"}
  rootfs_folder_name=${rootfs_folder_name:-"slitaz-rootfs"}
  if [ "rootfs_folder_name=:0:1" = "/" ]; then
      l_root_fs="${rootfs_folder_name:1}"
  fi
  if [ ! -z "prefix"]; then
      local l_prefix=$prefix #TODO add checks to fix errors in prefix format (should start with slash)
  else [ -z "$prefix" ]; then
     if [ -d "$curdir/$rootfs_folder_name/64" ]; then
       l_prefix="/64" #Maybe also add a second check for a /32 prefix (and possibly others)
     else
       l_prefix=""
     fi
  fi
  if [ ! -z "$1" ]; then
    while [ $# -gt 0 ]
      case "$1" in
      *=*)
        app_type="${1%=*}"
        app_options_str="${1#"$app_type="}"
        app_options=( "${app_options_str//,/$IFS}" )
  else
      copy_defaults
  fu
}
copy_defaults(){
    #local l_aps=()
    
    local fs_path=$l_curdir/tazpup-core-files/desktop/defaults/fs
    local app_path=$l_curdir/tazpup-core-files/desktop/defaults/fs 
    
    
    
    local fd_path="/tmp/desktop_defaults_and_files"
    mkdir -p "$fd_path"
    exec 12<> "$fd_path/fd_12"
    while IFS=$'\0' read  -r -d $'\0' -u12 prefixed_link ; do
        prefixed_file_path=`readlink "$prefixed_link"`
        prefixed_link_target_path=${prefixed_link#"$l_fs"}
        
        case "$prefixed_file_path" in
        "$l_fs"*)
            fm_file_path=${prefixed_file_path#$fs_path}
            cp --remove-destination -arf \
                     "$prefixed_file_path" 
                     
         ;;
        "$l_app_path)
    done 12< <( find "$l_fs" -type l -name '*' -print0 ) #https://blog.famzah.net/2016/10/20/bash-process-null-terminated-results-piped-from-external-commands/
    exec 12>&-
}
