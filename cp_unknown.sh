#!/bin/sh
#written by mistfire, modified by s243a
curdir=`pwd`

old='/mnt/+mnt++root+spot+Downloads+tazpuppy-5.0-beta-24.iso+puppy_tazpup_5.0.sfs'
new='/root/spot/Downloads/tazpup-builder-5.13.tar.gz.extracted/tazpup-builder/tazpup-core-files/unknown'

#https://stackoverflow.com/questions/9612090/how-to-loop-through-file-names-returned-by-find
while read line; do
    mkdir -p `dirname $new$line`
    cp $old$line $new$line
done < "/root/spot/Downloads/tazpup-builder-5.13.tar.gz.extracted/tazpup-builder/unknown.txt"

