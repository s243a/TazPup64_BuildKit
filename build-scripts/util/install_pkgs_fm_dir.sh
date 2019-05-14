#/bin/bash
curdir=`realpath $(pwd)/../..` 
source $curdir/defaults
prefix=${prefix:-"/64"}
branch=${branch:-next64}
xinteractive=${xinteractive:-0}

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

trap close_fd_12 EXIT SIGKILL SIGTERM
close_fd_12() { exec 12>&- ; }
is_array(){ #Pass the name of the variable to this function (not the variable it's self)
  #https://stackoverflow.com/questions/14525296/bash-check-if-variable-is-array	
  #http://fvue.nl/wiki/Bash:_Detect_if_variable_is_an_array	
  #https://www.computerhope.com/unix/bash/declare.htm
  if [ $(declare -p $1 | grep -q '^declare \-a') ]; then
  #Variable is an array
   is_array_rtn=1 #This is opposite standard unix exit codes: https://shapeshed.com/unix-exit-codes/
  else
  #variable is not an array
   is_array_rtn=0 #This is opposite standard unix exit codes: #http://www.tldp.org/LDP/abs/html/exitcodes.html
  fi
}
install_pkg(){

  pkg="$1"
  opt_in=$2
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
install_pkgs_fm_dir(){ #Specify full path to directory as first input argument
   mkdir -p "/tmp/make-tazpup/functions/fd"
   exec 12<> "/tmp/mv_or_copy_files/fd_12"
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
for Ap_Type in "console_editors" "terminal_emulators" "text_editors" "graphics" "games"; do
  Applicatoins_TO_INSTALL="$Ap_Type"_TO_INSTALL
  is_array "$Applicatoins_TO_INSTALL"
  if [ ! is_array_rtn ]; then
    if [ "${#Applicatoins_TO_INSTALL}" -gt 0 ]; then
       Applicatoins_TO_INSTALL=( "${app_options_str//,/$IFS}" )
    fi
  fi
  #if [ is_array_rtn -eq 1 ]; then
    #if [ ${#myvar} -gt 0 ]; then
    #  Applicatoins_TO_INSTALL=( "$TextEditors_TO_INSTALL" )
    #else
    #  set_Applications_TO_INSTALL 
    #  Applicatoins_TO_INSTALL="$set_Applications_TO_INSTALL_rtn"
    #fi
    for applicaiton in "${Applicatoins_TO_INSTALL[@]}"; do
      
      app_path=$curdir/pkgs/applications/$Ap_Type/$application
      #if [ -d "$app_path/$branch" ]; then
        install_pkgs_fm_dir "$app_path" #see $curdir/build-scripts/make-tazpup_functions.sh
      #fi
      #install_pkg "$app_path"
    done
  #fi
done
