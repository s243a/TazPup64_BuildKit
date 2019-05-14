unmount_vfs(){
 umount -l $curdir/$rootfs/dev 2>/dev/null
 umount -l $curdir/$rootfs/sys 2>/dev/null
 umount -l $curdir/$rootfs/proc 2>/dev/null
 #umount /mnt/wktaz 2>/dev/null
 #umount /mnt/wksfs 2>/dev/null
 close_file_descriptors
 
}  
close_file_descriptors(){
  exec 10>&-
}
delete_petspec_fm_file(){

  local field_val=$1
  local pkg_rootfs=${2:-"$s_rootfs"}
  local spec_list_name=${3:-"woof-installed-packages"}
  local field=${4:-1} #The first field is the default  
  #TODO if prk_rootfs="/" or "" give warning
  AWK_PRG="BEGIN{FS=\"|\"}
  {
    if ( \$$field != \"$field_val\" ) {
     print 
    }
  }"
  #TODO we probably need logic to expand wildards
  local file_spec_list=( "$pkg_rootfs/root/.packages/$spec_list_name" ) 

  for spec_list in "${file_spec_list[@]}"; do
    spec_name=`basename "$spec_list"`
    cat "$spec_list" | awk "$AWK_PRG"  >> "/tmp/trim_puppy/$spec_name"
    echo "about to"
    echo "rm \"$spec_list\"
    mv  \"/tmp/trim_puppy/$spec_name\" \"$spec_list\"
    "
    read -p "Press enter to continue"
    set -x    
    rm "$spec_list"
    mv  "/tmp/trim_puppy/$spec_name" "$spec_list"
    set +x    
    read -p "Press enter to continue"
  done

}

inst_builtin_fm_dir(){
  local source_dir=$1
  local dest_root=${2:-"$curdir/$s_rootfs"} #TODO make the default more robust with regards to slashes
  if [ "$dest_root" = "/" ]; then
     echo "warning about to install package into system rootfs"
     read -p "Press enter to continue"
  fi
  
  local pkg_name=${3:-`basename $1`} #TODO add logic for different location of files.list
  
  source_file_list_prefixed="$source_dir/root/.packages/builtin_files/$pkg_name" 
  dest_file_list_prefixed="$dest_root/root/.packages/builtin_files/$pkg_name"
  local spec_list_name=${4:-"woof-installed-packages"}
  local file_spec_list_path="$dest_root/root/.packages/$spec_list_name"
  echo "about to:" 
  echo "  cp --remove-destination -arf $source_dir/* 
                                 $dest_root/ 2>/dev/null"
  read -p "Press enter to continue"
  cp --remove-destination -arf $source_dir/* \
                                 $dest_root/ 2>/dev/null
  if [ ! -f "$source_file_list_prefixed" ]; then
     cd "$source_dir"
     mkdir -p `dirname "$dest_file_list_prefixed"`
     find . -mindepth 1 -name '*' > "$dest_file_list_prefixed"
  fi
  if [ ! -f "$source_dir/pet.specs" ]; then
     cd "source_dir"
     
     
     dir2pet "$pkg_name" 
  fi  
  
  #match_cnt=$( grep -cF "$spec" "$inst_pkg_specs_target" )
  #if [ $match_cnt -eq 0 ]; then
  #  spec >> "$inst_pkg_specs_target"
  #fi
  if [ -f "$source_dir/pet.specs" ]; then
    #All args here except the first are default
    echo "about to:" 
    echo "  delete_petspec_fm_file \"$pkg_name\" \"$dest_root\" \"$spec_list_name\" \"1\""
    read -p "Press enter to continue"
    delete_petspec_fm_file "$pkg_name" "$dest_root" "$spec_list_name" "1" 
    cat "$source_dir/pet.specs" >> "$file_spec_list_path"
  fi
}
copy_pet_specs(){
  AWK_PRG="BEGIN{FS=\"|\"}
  {
    if ( \$2 == \"$app\" ) {
     print 
    }
  }"
  file_spec_list=( "$rootfs_full/root/.packages/"*"-installed-packages" )
  #cat "${file_spec_list[@]}" | awk -F'|' "$AWK_PRG" #'{print $2;}'
  spec=$( cat "${file_spec_list[@]}" | awk "$AWK_PRG"  >> "$inst_pkg_specs_target" ) 
  match_cnt=$( grep -cF "$spec" "$inst_pkg_specs_target" )
  if [ $match_cnt -eq 0 ]; then
    spec >> "$inst_pkg_specs_target"
  fi
}
copy_built_in(){
  set -x
  app=$1
  rel_paths=( "root/.packages/builtin_files/$app" "var/lib/tazpkg/installed/$app/files.list" ) 
  for a_rel_path in "${rel_paths[@]}"; do
    if [ $retry -eq 1 ]; then    
      rootfs_arry=( "$curdir/$s_rootfs$prefix/" "$alt_s_rootfs" )
    else
      rootfs_arry=( "$curdir/$s_rootfs$prefix/" )
    fi
    for a_rootfs in "${rootfs_arry[@]}"; do
      rootfs_full="$a_rootfs"
      a_rel_path="$a_rootfs$a_rel_path"
      if [ -f "$a_rel_path" ]; then
        #file_list="$curdir/$s_rootfs/root/.packages/builtin_files/$app"
        file_list="$a_rel_path"
        break
      fi
    done
  done
  
  #if [ ! -f "$file_list" ] && [ $retry -eq 1 ]; then
  #  file_list="$alt_s_rootfs/root/.packages/builtin_files/$app"
  #  using_alt_list=1
  #else
  #  using_alt_list=0
  #fi
  if [ "${target:0:1}" = "/" ]; then
    target_root="$target"       
  else
    target_root="$curdir/$target"     
  fi   
  target_file_list="$target_root/root/.packages/builtin_files/$app"  
  echo "file_list=$file_list"
  mkdir -p /tmp/trim_puppy
  exec 10<> /tmp/trim_puppy/fd_10
  subdir="/"
  mkdir -p /tmp/trim_puppy/
  rm "/tmp/trim_puppy/$app"
  touch "/tmp/trim_puppy/$app"
  
  #mkdir -p 
  inst_pkg_specs_target="$target_root/root/.packages/"$arr_name"-installed-packages"
  mkdir -p `dirname "$inst_pkg_specs_target"`
  copy_pet_specs
  
  source_taz_pkg_dir="$rootfs_full/var/lib/tazpkg/installed/$app/"
  dest_taz_pkg_dir="$target_root/var/lib/tazpkg/"$app"/installed/"
  mkdir -p dest_taz_pkg_dir
  
  if [ -d "$source_taz_pkg_dir" ]; then 
    cp --remove-destination -arf  "$source_taz_pkg_dir"/* "$dest_taz_pkg_dir"
  fi
  
  while IFS=$'\n' read  -r -d $'\n' -u10 line ; do
       line=`echo "$line" | tr -d '[:space:]'`
       if [ ! "${line:0:1}" = "/" ]; then
           line=$subdir$line
       fi
       echo $line>>"/tmp/trim_puppy/$app"
       if [ "${target:0:1}" = "/" ]; then
         target_prefixed="$target$line"
         #target_root="$target" #Defined above      
       else
         #target_root="$curdir/$target" #Defined above
         target_prefixed="$curdir/$target$line"       
       fi  

       if [ "${s_rootfs:0:1}" = "/" ]; then
         source_prefixed="$s_rootfs$line" 
         cd "$s_rootfs" #this is necessary for the cpio command below     
       else
         source_prefixed="$curdir/$s_rootfs$line"     
         cd "$curdir/$s_rootfs"  #this is necessary for the cpio command below
       fi  

    if [ -d "$source_prefixed" ]; then
       subdir="$line" 
       echo ".$line" | cpio -pd "$target_root"
       subdir=${subdir%/}/
    else
       target_dir=`dirname $target_prefixed`
       if [ ! -d "$target_dir" ]; then
        source_dir=`dirname $line`
        echo ".$source_dir" | cpio -pd "$target_root"      
       fi
       if [ ! -f "$source_prefixed" ] && [ $retry -eq 1 ]; then
           source_prefixed="$alt_s_rootfs$line" 
           cp -a -u "$source_prefixed" "$target_prefixed"
       elif [ ! "$arr_action" = "mv" ]; then
         cp -a -u "$source_prefixed" "$target_prefixed"
       else
         mv -uf "$source_prefixed" "$target_prefixed"
         if [ -f "$source_prefixed" ]; then
           rm "$source_prefixed"
         fi
       fi
    fi
    
  done 10< <( cat "$file_list" )
  exec 10>&-
  set +x
  if [ ! "$arr_action" = "mv" ]; then
    mkdir -p `dirname "$target_file_list"`
    cp -a -u "$file_list" "$target_file_list"
  else
    mv -uf "$file_list" "$target_file_list"
    sed -i "\%|${app}|%d" "$curdir/$s_rootfs/root/.packages/"*"-installed-packages"
    if [ -f "$file_list" ]; then
      rm "$file_list"
    fi
  fi
}
dissect_rootfs(){
  #arr_names=${1:-ALL_ArrNames}
  arry_names_name=${1:-ALL_ArrNames}
  for arr_name in $(eval 'echo "${'$arry_names_name'[@]}"'); do
    eval "arr=( \"\${"$arr_name"[@]}\" )" 
    eval "arr_action=\$"$arr_name"_action"
    arr_action=${arr_action:-"$action"}
    #Move is faster but perhaps copy is safer
    arr_action=${arr_action:-cp} 
    set -x
    eval 'target="$'$arr_name'_target"'
    target=${target:-"$curdir/$arr_name"}
    set +x
    if [ "${s_rootfs:0:1}" = "/" ]; then
      s_rootfs_prefixed="$s_rootfs"    
    else
      s_rootfs_prefixed="$curdir/$s_rootfs"     
    fi  
    for app in "${arr[@]}"; do
      echo "arr_action=$arr_action"
      case "$arr_action" in
      cp|mv|retry)  
          echo "app=$app" 
          copy_built_in "$app"        
          ;;
      #mv)
      #    move_built_in()
      #;;
      #pet) #We might also want to convert to other package formats
      #    mk_pet_fm_built_in()
      #;;
      esac
      if [ -f "/tmp/trim_puppy/$app" ] && [ $chroot_remove_builtin -eq 1 ]; then
        file_list="$curdir/$s_rootfs/root/.packages/builtin_files/$app"
        rm "$file_list"
        cp "/tmp/trim_puppy/$app" "$file_list"
      fi
      #chroot "$s_rootfs_prefixed" remove_builtin "$app"
    done 
  done
}
