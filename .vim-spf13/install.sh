#!/bin/bash

# Backup current config
TODAY=`date +%Y%m%d`
mkdir -p ~/.vimdata/vimbackup
for FILE in ~/.vim ~/.vimrc*; do
	if [ ! -h $FILE ]; then
		mv -v $FILE ~/.vimdata/vimbackup/$(basename $FILE).$TODAY.bak
	else
		rm -v $FILE
	fi
done

# Make links
SRC=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd )
ln -fsv ~/.spf13-vim-3/.vim* ~/
ln -fsv $SRC/.vimrc* ~/
mkdir -p ~/.vim/bundle
for BUNDLE in ~/.vim-legacy/.vim/bundle/*; do
	ln -fsv $BUNDLE ~/.vim/bundle/
done
mkdir -p ~/.vim/plugin
for PLUGIN in ~/.vim-legacy/.vim/plugin/*; do
	ln -fsv $PLUGIN ~/.vim/plugin/
done
