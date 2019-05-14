prepend_curdir(){
    i=0
    do while [ $# -gt 0 ]; then
      opt_i=$1
      case $opt_i in
      -s|--subdir=*) #alternativly path can be the first postional argument
          subdir=${opt_i#*=}
           if [ -z "$root_dir" ]; then
             i=1
           elif [ ! -z "$assign_var" ]; then
              i=2
            else
              i=3
            fi
          fi         
      -r|--root=*)
          opt_i=${opt_i#*=}
          root_dir=${opt_i:-$curdir}; ;;
          if [ -z "$subdir" ]; then
            i=1
          elif [ ! -z "$assign_var"}
            i=2
          else
            i=3
          fi 
      --|-*) #We might want to distinguish between these two cases. 
         echo "unknown option"
      -a=*|--assign=*)  
          assign_var="${opt_i#*=}"
      *)
          case $i in
          0) subdir=$opt_i; ;;     
          1) root=$opt_i; ;;     
          2) assign_var=$opt_i; ;; 
          3) return 1; ;; #In bash non zero values are errors 
          esac
          ;;  
      esac
    done
    curdir=${curdir:-`pwd`}
    root_dir=${root_dir:-$curdir}
    #Can use $3 to give an alternative return variable
    if [ "${subdir:0:1}" == "/" ]; then 
       prepend_curdir_out=$subdir
    elif [ "${subdir:0:1}" == "." ]; then 
       prepend_curdir_out=$root_dir/${subdir:2:}
    else
       prepend_curdir_out=$root_dir/$subdir
    fi
}

extact_kernal_modules_fm_folder(){

for i in "$@"
do
case $i in
    -t=*|--extension=*)
      TARGET_FOLDER="${i#*=}"
      [ ${TARGET_FOLDER:0:1} == "/" ] && shift || \
      [ ${TARGET_FOLDER:0:1} == "." ] && shift && $TARGET_FOLDER='pwd'/${TARGET_FOLDER:2:} ||
      && continue
      shift; $TARGET_FOLDER=$curdir/$TARGET_FOLDER
    ;;
    -s=*|--searchpath=*) $Source Folder
      SOURCE_FOLDER="${i#*=}"
      [ ! ${SOURCE_FOLDER:0:1} == "/" ] && $SOURCE_FOLDER=$curdir/$SOURCE_FOLDER
      shift # past argument=value
    ;;
    -l=*|--lib=*)
    LIBPATH="${i#*=}"
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done



      cp -rf /mnt/wksfs/lib/modules $curdir/kernel-modules/lib/
      mkdir -p $curdir/kernel-modules/var/lib/tazpkg/installed/linux	
      touch $curdir/kernel-modules/var/lib/tazpkg/installed/linux/files.list 
	
echo 'PACKAGE="linux"
VERSION=""
CATEGORY="misc"
SHORT_DESC="Linux kernel (compiled for puppy linux)"
WEB_SITE="http://puppylinux.org/"
MAINTAINER="nobody@slitaz.org"
DEPENDS="linux-modules"
' > $curdir/kernel-modules/var/lib/tazpkg/installed/linux/receipt
	 
	 
	 mkdir -p $curdir/kernel-modules/var/lib/tazpkg/installed/linux-modules

echo 'PACKAGE="linux-modules"
VERSION=""
CATEGORY="misc"
SHORT_DESC="Linux kernel modules(compiled for puppy linux)"
WEB_SITE="http://puppylinux.org/"
MAINTAINER="nobody@slitaz.org"
DEPENDS=""
' > $curdir/kernel-modules/var/lib/tazpkg/installed/linux-modules/receipt	 
}


  mkdir -p $curdir/kernel-modules/lib

  for file1 in $(find /mnt/wktaz -type f -name "*.sfs")
  do

  mount -t squashfs $file1 /mnt/wksfs

  if [ $? -eq 0 ]; then

    if [ -d /mnt/wksfs/lib/modules ]; then
      echo "Copying kernel modules from $(basename $file1) to rootfs..."
      cp -rf /mnt/wksfs/lib/modules $curdir/kernel-modules/lib/
      mkdir -p $curdir/kernel-modules/var/lib/tazpkg/installed/linux	
      touch $curdir/kernel-modules/var/lib/tazpkg/installed/linux/files.list 
	
echo 'PACKAGE="linux"
VERSION=""
CATEGORY="misc"
SHORT_DESC="Linux kernel (compiled for puppy linux)"
WEB_SITE="http://puppylinux.org/"
MAINTAINER="nobody@slitaz.org"
DEPENDS="linux-modules"
' > $curdir/kernel-modules/var/lib/tazpkg/installed/linux/receipt
	 
	 
	 mkdir -p $curdir/kernel-modules/var/lib/tazpkg/installed/linux-modules

echo 'PACKAGE="linux-modules"
VERSION=""
CATEGORY="misc"
SHORT_DESC="Linux kernel modules(compiled for puppy linux)"
WEB_SITE="http://puppylinux.org/"
MAcase $i in
    -t=*|--extension=*)INTAINER="nobody@slitaz.org"
DEPENDS=""
' > $curdir/kernel-modules/var/lib/tazpkg/installed/linux-modules/receipt	 
	 
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
