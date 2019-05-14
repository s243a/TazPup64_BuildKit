#!/bin/sh
#written by mistfire, modified by s243a
#Build TazPuppy either online or local
curdir=`pwd`

old='/mnt/+mnt++root+spot+Downloads+tazpuppy-5.0-beta-24.iso+puppy_tazpup_5.0.sfs'
new='/root/spot/Downloads/tazpup-builder-5.13.tar.gz.extracted/tazpup-builder/slitaz-rootfs/64'

rm "$curdir/compare.log"; touch "$curdir/compare.log"
rm "$curdir/compare_text_diff_size.log"; touch "$curdir/compare_text_diff_size.log"  
rm "$curdir/compare_text_same_size.log"; touch "$curdir/compare_text_same_size.log" 
#https://stackoverflow.com/questions/9612090/how-to-loop-through-file-names-returned-by-find
find "$old" -type f -print0 | 
    while IFS= read -r -d $'\0' f_name_full; do
        f_name=${f_name_full#"$old"} 
        #echo "---------------"
        #echo "f_name=$f_name"
        if [ ! -f "$new/$f_name" ]; then
            echo "$f_name" >> "$curdir/compare.log"
        else
           #https://unix.stackexchange.com/questions/208942/bash-script-check-if-a-file-is-a-text-file
           case $(file -b --mime-type - < "$new$f_name") in
             (text/*)
                old_size=$(wc -c <"$old$f_name") #https://stackoverflow.com/questions/5920333/how-to-check-size-of-a-file
                new_size=$(wc -c <"$new$f_name")
                if [ $old_size -ne $new_size ]; then
                    echo "$f_name" >> "$curdir/compare_text_diff_size.log" 
                else    
                    echo "$f_name" >> "$curdir/compare_text_same_size.log"                
                fi 
                ;;
             (*)
                #echo "Not a text file"
                ;;
                
           esac
            
        fi
    done
