#trap remove_fille_descriptpors EXIT
#trap remove_fille_descriptpors SIGKILL
#trap remove_fille_descriptpors SIGTERM

remove_fille_descriptpors(){
exec 9>&-
exec 10>&-
exec 11>&-
umount /mnt/wksfs #2>&1 #| xargs -0 echo ) || echo "umount error"
}

set_source_dest_ops(){
   ssdo_pos_args=()
   ssdo_pos_arg_count=0
   ssdo_arg_count=0
   for i in "$@"; do
   echo "i=$i"
   case $i in
   -p1=*|--source-prefix=*)
      ssdo_s_prefix=${i#*=}; ;;
   -p2=*|--destination-prefix)
      ssdo_d_prefix=${i#*=}; ;;
   --)
      arg_count+=1
      break; ;;
   -*|--*)
      ssdo_flags+=( "$i" ); ;;
   *)
      ssdo_pos_args+=( "$i" )
      ssdo_post_arg_count+=1
      ;;
   esac
      arg_count+=1
   done
   ssdo_curdir=${curdir:-`pwd`}
   s_prefix=${s_prefix:-$curdir}
   d_prefix=${d_prefix:-$s_prefix} 
   ssdo_tail_args=( ${@:arg_count:} )  #TODO should we quote this?
}  
set_move_prefix(){
   smp_pos_args=()
   smp_pos_arg_count=0
   smp_arg_count=0
   for i in "$@"; do
   case $i in
   -m=*|--move-prefix=*)
      move_prefix="${i#*=}"; ;;
   --)
      arg_count+=1
      break; ;;
   -*|--*)
      smp_flags+=( "$i" ); ;;
   *)
      smp_pos_args+=( "$i" )
      smp_pos_arg_count+=1
      ;;
   esac
      arg_count+=1
   done
   if [ -z "$move_prefix" ]; then
     echo "ussage: set_move_prefix move_prefix" 
   fi	
}
set_full_paths(){
   if [ -z "$1" ] || [ -z "$2" ]; then
     echo "ussage: mv_files_within_curdir fm_folder to_folder"
     return 1 #Anthing other than 0 is an error.          
   fi
   s_folder=${1}
   d_folder=${2}
   m_folder=${3}
   if [ "${s_folder:0:1}" = "/" ]; then
     s_folder_fullpath=$s_folder
     s_prefix=$s_folder_fullpath
     s_sub_folder="/"
   elif [ "${s_folder:0:1}" == "." ]; then
     if [ -z "$s_prefix" ]; then
       s_prefix=`cwd`
     fi
     s_folder_fullpath=$s_prefix/${s_folder:2:}
     s_prefix=$s_folder_fullpath
     s_sub_folder=${s_folder:1:}  
   else
     s_folder_fullpath=$s_prefix/$s_folder 
     s_sub_folder=/$s_folder       
   fi
   if [ "${d_folder:0:1}" = "/" ]; then
     d_folder_fullpath=$d_folder
     d_prefix=$d_folder_fullpath
     d_sub_folder="/"
   elif [ "${d_folder:0:1}" = "." ]; then
     if [ -z "$s_prefix" ]; then
       d_prefix="`pwd`"
     fi     
     d_folder_fullpath=$d_prefix/${d_folder:2:}
     d_prefix=$d_folder_fullpath
     d_sub_folder=${d_folder:1:}      
   else
     d_folder_fullpath=$d_prefix/$d_folder       
     s_sub_folder=/$s_folder  
   fi
   if [ ! -z "$m_folder" ]; then
     if [ "${m_folder:0:1}" = "/" ]; then
       m_folder_fullpath="$m_folder"
       m_prefix="$m_folder_fullpath"
       m_sub_folder="/"      
     elif [ "${m_folder:0:1}" = "." ]; then
       if [ -z "$m_prefix" ]; then
         m_prefix="`pwd`"
       fi
       m_folder_fullpath=$m_prefix/${m_folder:2:}
       m_prefix=$m_folder_fullpath
       m_sub_folder=${d_folder:1:}         
     else
       m_folder_fullpath=$m_prefix/$m_folder 
       m_sub_folder=${m_folder:1:}               
     fi   
   fi 
}  
mv_or_copy_files(){
   bla=$@
   echo "======================================"
   set_source_dest_ops ${bla[@]}
   #eval "set ${pos_args[@]}" # the variable pos_args is set in set_source_dest_ops
   echo "======================================"
   set_full_paths ${ssdo_pos_args[@]}   
   #set_move_prefix ${ssdo_flags[@]}
   echo "======================================"
   #set -x
   if [ -d "$s_folder_fullpath" ] ; then
      
      #sed -e "s#$xcurdir\/kernel-modules\/lib\/#\/lib\/#g"  | \ sdfdsf
      #rm /tmp/foo_10
      exec 10<> /tmp/foo_10
      #( IFS=; find $s_folder_fullpath -print0 -type f -name "*" 1>&10 )
      echo "find $s_folder_fullpath  -type f -name "'*'" "
        #read -p "Press enter to continue" <&1
      #( find $s_folder_fullpath  -type l -name "*" 1>&10 ) 
   echo "--------------------------------------"      
#      while IFS= read  -r -d $'\0' fm_filePath_prefixed <&10 ; do #IFS= read -r -d '' 
       while IFS=$'\0' read  -r -d $'\0' -u10 fm_filePath_prefixed ; do
        #set -x
        echo "===== mv_or_copy_files(); fm_filePath_prefixed=$fm_filePath_prefixed===="
        echo "fm_filePath_prefixed=$fm_filePath_prefixed"
        echo "${fm_filePath_prefixed[@]}"
        echo "s_prefix=$s_prefix"
        fm_filePath=${fm_filePath_prefixed#"$s_prefix"}
        to_filePath_prefixed=$d_prefix$fm_filePath
        move_filePath_prefixed=$m_prefix$fm_filePath
        #set +x
        #read -p "Press enter to continue" <&1
        
        if [ -d "$to_filePath_prefixed" ]; then
          set -x
          mkdir -p "$to_filePath_prefixed" #added by s243a 18-03-12
          set +x
        else
          mkdir -p "`dirname  $to_filePath_prefixed`" # Moved from within velow if statment (s243a)
          if [ ! -z "$m_folder" ] && [ -f "$move_filePath_prefixed" ]; then
            if [ ! -f "$to_filePath_prefixed" ]; then
              #mkdir -p `dirname  $to_filePath_prefixed` #Moved outside of if statment (s243 18-03-12)
              mv "$move_filePath_prefixed" "$to_filePath_prefixed"
            else
              set -x
              cp -a -u  "$fm_filePath_prefixed" "$to_filePath_prefixed"
              rm "$fm_filePath_prefixed"
              set +x
            fi
          else
              set -x
              mkdir -p "`dirname $to_filePath_prefixed`"
              cp -a -u  "$fm_filePath_prefixed" "$to_filePath_prefixed"   
              set +x    
          fi
        fi		 
      done 10< <( find "$s_folder_fullpath" -name '*' -print0 ) #Removed -type f option (s243a 18-03-12) 
      #https://blog.famzah.net/2016/10/20/bash-process-null-terminated-results-piped-from-external-commands/
      exec 10>&-
   fi 
   #set +x
}
apply_white_out_files(){
   bla=$@
   #echo "====LN#170===apply_white_out_files===="
   set_source_dest_ops ${bla[@]}
   #eval "set ${pos_args[@]}" # the variable pos_args is set in set_source_dest_ops
   #echo "====LN#173===apply_white_out_files===="
   set_full_paths ${ssdo_pos_args[@]}   
   #set_move_prefix ${ssdo_flags[@]}
   #echo "====LN#176===apply_white_out_files===="    
   
   echo "s_folder_fullpath=$s_folder_fullpath"
   echo "s_prefix=$s_prefix"
   echo "d_prefix=$d_prefix"
   #read -p "Press enter to continue" <&1
   set -x	
   exec 11<> /tmp/mv_or_copy_files/fd_11
   while IFS=$'\0' read  -r -d $'\0' -u11 fm_filePath_prefixed ; do
     wh_fname=`basename "$fm_filePath_prefixed"`
     echo "===== apply_white_out_files(); fm_filePath_prefixed=$fm_filePath_prefixed===="
     set -x
     case "$wh_fname" in
     '.wh..wh..opq')
       fm_dirPath_prefixed=`dirname "$fm_filePath_prefixed"`
       fm_dirPath=${fm_dirPath_prefixed#"$s_prefix"}
       to_dirPath_prefixed=$d_prefix$fm_dirPath

       rm -rf "$to_dirPath_prefixed"
       cp -r "$fm_dirPath_prefixed" "$to_dirPath_prefixed"
       rm "$to_dirPath_prefixed/$wh_fname"                 
       #read -p "Press enter to continue" <&1
       ;;
     '.wh..wh.plnk'|'.wh..wh.aufs') #https://unix.stackexchange.com/questions/92287/aufs-whiteout-removal
       fm_dirPath_prefixed=`dirname "$fm_filePath_prefixed"`
       fm_dirPath=${fm_dirPath_prefixed#"$s_prefix"}
       to_dirPath_prefixed=$d_prefix$fm_dirPath
       rm "$to_dirPath_prefixed/$wh_fname"
       #read -p "Press enter to continue" <&1
       ;; 
     *)
       fm_dirPath_prefixed=`dirname "$fm_filePath_prefixed"`
       fm_dirPath=${fm_dirPath_prefixed#"$s_prefix"}
       to_dirPath_prefixed="$d_prefix$fm_dirPath"
       fname="${wh_fname#.wh.}" #https://lwn.net/Articles/324291/
       if [ -d "$to_dirPath_prefixed/$fname" ]; then
         rm -rf "$to_dirPath_prefixed/$fname"  
       else
         rm "$to_dirPath_prefixed/$fname" 
       fi
       rm "$to_dirPath_prefixed/$wh_fname"    
       #read -p "Press enter to continue" <&1                    
       ;;
     esac
     set +x
           
   done 11< <( find "$s_folder_fullpath" -type f -name '.wh*' -print0 ) #https://blog.famzah.net/2016/10/20/bash-process-null-terminated-results-piped-from-external-commands/
      exec 11>&-
   #set +x
}
merge_sfs_and_save_fils(){
  local sfs_dir=$1
  local target_dir=$2
  local savedir=${3:-$sfs_dir/tazpupsave}

  mkdir -p "$target_dir"
  mount_point=/mnt/wksfs
  mkdir -p /mnt/wksfs

  #rm /tmp/foo_9
  exec 9<> /tmp/mv_or_copy_files/fd_9
  #set -x
  ( find "$sfs_dir" -maxdepth 1 -type f -name "*.sfs" | \
    grep -v -e "^$sfs_dir"/'f.*' | \
    grep -v -e "^$sfs_dir"/'z.*' 1>&9 ) 
  #set +x 
  #while read file1 <&9 ; do #https://stlocal variables bashackoverflow.com/questions/6911520/read-command-in-bash-script-is-being-skipped
   while read -r -u9 file1 ; do
    mount -v -t squashfs "$file1" "$mount_point" #2>&1 | xargs echo 
    #mount -t squashfs "$file1" /mnt/wksfs
    echo "mount -t squashfs $file1 /mnt/wksfs"
    read -p "Press enter to continue" <&1
    if [ 1 -eq 1 ]; then 
      echo "mv_or_copy_files /mnt/wksfs $target_dir" 
      mv_or_copy_files /mnt/wksfs "$target_dir"
    fi
    echo "mounted $file1"
    #read -p "Press enter to continue"

    umount /mnt/wksfs
  done 9< <( find $sfs_dir -maxdepth 1 -type f -name "*.sfs" | \
              grep -v -e "^$sfs_dir"/'f.*' | \
              grep -v -e "^$sfs_dir"/'z.*' )
  exec 9>&-
  #read -p "Press enter to continue"
  echo "mv_or_copy_files $savedir $target_dir"
  mv_or_copy_files "$savedir" "$target_dir"
}
mkdir -p /tmp/mv_or_copy_files
remove_fille_descriptpors
trap remove_fille_descriptpors EXIT SIGKILL SIGTERM
#trap remove_fille_descriptpors SIGKILL
#trap remove_fille_descriptpors SIGTERM
root=/initrd/mnt/dev_save/slacko64save
sfs_dir=/mnt/sdb1/TazPup/64/a1
target_dir=$root/tazpup-builder/slitaz-rootfs-new
savedir=$sfs_dir/tazpupsave


merge_sfs_and_save_fils "$sfs_dir" "$target_dir"
apply_white_out_files "$savedir" "$target_dir"

  
