#!/bin/bash

# Backup current config
TODAY=`date +%Y%m%d_%s`
for VIM in ~/.vim ~/.vimrc*; do
    mv -v $VIM $VIM.$TODAY
done

# Make links
SRC=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd )
DST=~
ln -s $SRC/.vim* $DST/ -f
