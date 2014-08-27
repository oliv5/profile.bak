#!/bin/bash

# Backup current config
TODAY=`date +%Y%m%d`
mkdir -p ~/.vimdata/vimbackup
for VIM in ~/.vim ~/.vimrc*; do
    mv -v $VIM ~/.vimdata/vimbackup/$(basename $VIM).$TODAY.bak
done

# Make links
SRC=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd )
ln -fsv $SRC/.vim* ~/

