#!/bin/bash

# Backup current config
TODAY=`date +%Y%m%d`
mkdir -p ~/.vimdata/vimbackup
for VIM in ~/.vim ~/.vimrc*; do
    mv -v $VIM ~/.vimdata/vimbackup/$(basename $VIM).$TODAY.bak
done

# Make links
SRC=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd )
ln -fsv $HOME/.spf13-vim-3/.vim* ~/
ln -fsv $SRC/.vimrc* ~/
for BUNDLE in ~/.vim-legacy/.vim/bundle/*; do
    ln -fsv $BUNDLE ~/.vim/bundle/
done
mkdir -p ~/.vim/plugin
ln -fsv ~/.vim-legacy/.vim/plugin/*.vim ~/.vim/plugin/

