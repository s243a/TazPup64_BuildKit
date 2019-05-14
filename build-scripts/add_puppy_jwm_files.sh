#!/bin/sh
#written by mistfire, modified by s243a
#Build TazPuppy either online or local
curdir=${curdir:-"$(realpath `pwd`/..)"}
prefix=${prefix:-"/64"}
#theme_inst_folder=/theme
#Draft Function (Not used yet)
move_in_target(){
	mv $curdir/slitaz-rootfs$prefix/$1 $curdir/slitaz-rootfs$prefix/$2
}
#Draft Function (Not used yet)
install_fm_desktop_jwm_woof_CE(){
    Source_Path=$curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/
    Target_Path=$curdir/slitaz-rootfs$prefix
    Theme_Inst_Folder=$Target_Path/desktop_pkg_inst_scripts
    mkdir -p $Theme_Inst_Folder
 	cp --remove-destination -arf $Source_Path/$1/* \
	                             $Target_Path/ 2>/dev/null	
    chroot $Target_Path pinstall.sh   
    move_in_target pintstall.sh $Theme_Inst_Folde/$1_pinstall.sh   
}
#This is done earlier in make-tazpup.sh so maybe not needed.
install_rox(){

	rox_pkg_dir="$curdir/pkgs/desktop/rox/next64"
	for aPkg in `ls -1 "$rox_pkg_dir"`; do # $pkgs/slitaz-base pkgs/slitaz-dependencies pkgs/slitaz-packages pkgs/slitaz-preinst-pkg; do
       cp --remove-destination -arf $rox_pkg_dir/$aPkg $curdir/slitaz-rootfs$prefix/$pkgs #2>/dev/null
    done 
    for aPkg in `ls -1 "$rox_pkg_dir"`; do 
      install_pkg $rox_pkg_dir/$aPkg
      post_inst_fixes $pkg
    done 
	
	cd $curdir/slitaz-rootfs$prefix/usr/share/rox-filer
    ln -s ROX-Filer rox-filer
    
	cd $curdir/slitaz-rootfs$prefix/usr/bin
    ln -s rox-filer roxfiler    
}

add_puppy_jwm_files(){
    mkdir -p $curdir/slitaz-rootfs$prefix/desktop_pkg_inst_scripts	$TODO use var 
	#cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/ptheme/update_syste* $curdir/slitaz-rootfs$prefix/ 2>/dev/null
    /tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/slacko6.9.9/usr/share/jwm

	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-skeleton/rootfs-skeleton-slacko6.9.9/* \
	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	
	
	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-skeleton/rootfs-skeleton-slacko6.9.9/* \
	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	
	                             
	mkdir -p $curdir/slitaz-rootfs$prefix/usr/local/petget/
	cp --remove-destination -arf $curdir/tazpup-core-files/pkg-managers/petget/usr/local/petget/pinstall.sh \
	                             $curdir/slitaz-rootfs$prefix/usr/local/petget/pinstall.sh 2>/dev/null	 
	                             
	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/pt_buntoo/* \
	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null		                                                         
    chroot "$curdir/slitaz-rootfs$prefix/" sh -c "cd /; /pinstall.sh"   #https://unix.stackexchange.com/questions/402099/chroot-with-working-directory-specified
    mv $curdir/slitaz-rootfs$prefix/pinstall.sh $curdir/slitaz-rootfs$prefix/desktop_pkg_inst_scripts/pt_buntoop_install.sh  

	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/pt_faux_xfwm/* \
	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	
    chroot "$curdir/slitaz-rootfs$prefix/" sh -c "cd /; /pinstall.sh"   
    mv $curdir/slitaz-rootfs$prefix/pinstall.sh $curdir/slitaz-rootfs$prefix/desktop_pkg_inst_scripts/pt_faux_xfwm_install.sh

	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/wallpaper/* \
	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	

	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/ptheme/* \
	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	
    chroot "$curdir/slitaz-rootfs$prefix/" sh -c "cd /; /pinstall.sh"   
    #move_in_target pintstall.sh theme_inst_folder/ptherme_pinstall.sh
    mkdir -p $curdir/slitaz-rootfs$prefix/desktop_pkg_inst_scripts
    mv $curdir/slitaz-rootfs$prefix/pinstall.sh $curdir/slitaz-rootfs$prefix/desktop_pkg_inst_scripts/rox_config_pinstall.sh    

	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/rox_config/* \
	                             $curdir/slitaz-rootfs$prefix/ 2>/dev/null	
    chroot "$curdir/slitaz-rootfs$prefix/" sh -c "cd /; /pinstall.sh"  
    #mkdir -p $curdir/slitaz-rootfs$prefix/ #Already done above
    mv $curdir/slitaz-rootfs$prefix/pinstall.sh $curdir/slitaz-rootfs$prefix/desktop_pkg_inst_scripts/rox_config_pinstall.sh

	cp --remove-destination -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-packages/woof-CE-19-03-06/jwm_config/* \
	                             $curdir/slitaz-rootfs$prefix/ #2>/dev/null	
    chroot "$curdir/slitaz-rootfs$prefix/" sh -c "cd /; /pinstall.sh"  
    #mkdir -p $curdir/slitaz-rootfs$prefix/ #Already done above
    mv $curdir/slitaz-rootfs$prefix/pinstall.sh $curdir/slitaz-rootfs$prefix/desktop_pkg_inst_scripts/jwm_config_pinstall.sh

}
#Draft Function (Not used yet)
#add_puppy_jwm_files_fm_list(){
#	while IFS= read -r -d read desktop_pkg; do
#	;
#	done <<-EOM
#		pt_buntu
#		wallpaper
#		rox_config
#	EOM
#}

cp --no-clobber -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-skeleton/s243a/* \
                     $curdir/slitaz-rootfs$prefix/ 2>/dev/null 

#This coppies files from the /usr/local/apps directory. These are Rox apps
cp --no-clobber -arf $curdir/tazpup-core-files/tazpup-core-files/desktop/rox/* \
                     $curdir/slitaz-rootfs$prefix/ 2>/dev/null 


#Moved because we need to do this earlier
##TODO seperate specific applications from /usr/local/aps (so that broken apps don't show up)
#cp --no-clobber -arf $curdir/tazpup-core-files/desktop/jwm/no-arch/rootfs-skeleton/slacko6.9.9/* $curdir/slitaz-rootfs$prefix/ 2>/dev/null

cd $curdir/slitaz-rootfs$prefix/usr/bin
ln -s rox-filer roxfiler

install_rox
add_puppy_jwm_files


