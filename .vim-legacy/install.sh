#!/bin/bash

# Backup current config
TODAY=`date +%Y%m%d`
for VIM in ~/.vim ~/.vimrc*; do
    mv -v $VIM $VIM.$TODAY
done

# Make links
SRC=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd )
ln -fsv $SRC/.vim* ~/

