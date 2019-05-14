This toolkit is for both 32-bit and 64-bit platform only

To use this build tool you will need the following
1. Pristine Slitaz iso image (x86/amd64, for building locally)
2. Any Puppy Linux iso image (x86/amd64, version 5.x or later)
3. Puppy Linux host environment

Scripts:
clean-workspace - Removes working files and reset to pristine setup
make-tazpup.sh - Build tazpuppy either locally or online

Folders:
tazpup-core-files -  Core files and scripts for tazpuppy
slitaz-packages -  Contains essential packages for building tazpuppy locally
special-packages - Contains important packages for building tazpuppy but they are found on slitaz repos
slitaz-livecd-files -  Core files for creating tazpuppy live cd
pet-packages -  Folder where the puppy linux (*.pet) packages are placed for installation

Files:
builder.cfg - settings for tazpuppy online build
package-cloud.txt - list of packages needed download and install (when using make-tazpup-cloud.sh)
remove-builtin.txt - list of slitaz builtin packages to remove

NOTE:
1. For local build:
    a. If you want to add a custom slitaz package before running the script. Just placed tazpkg packages to custom-packages folder.
    b. Use 32-bit packages if you are making 32-bit tazpuppy and use 64-bit packages if you are making 64-bit tazpuppy
2. For online build, just specify the package name that you want add in packages-cloud.txt (Take note: the online builder resolves the package dependencies).
3. For removing a builtin slitaz package, specify the package name on remove-builtin.txt


Instructions:
1. Run make-tazpup.sh from command line/terminal.
2. Select mode of building
3. Select Slitaz iso image (make-tazpup.sh only)
4. Select Puppy iso image
5. Wait until the process is finish
