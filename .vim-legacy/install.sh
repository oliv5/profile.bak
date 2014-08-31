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
ln -fsv $SRC/.vim* ~/

