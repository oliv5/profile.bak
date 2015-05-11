#!/bin/sh

set -vx
# Backup current config
DATE=`date +%Y%m%d`
mkdir -p ~/.vimdata/vimbackup
for FILE in ~/.vim ~/.vimrc*; do
	[ -e "$FILE" ] || continue
	if [ -L "$FILE" ]; then
		rm -v "$FILE"
	else
		ls -l "$FILE"
		mv -v "$FILE" "$HOME/.vimdata/vimbackup/$(basename "$FILE").$DATE.bak"
	fi
done

# Setup all things
ln -fsv ~/.spf13-vim-3/.vim* ~/
ln -fsv ~/.vim-spf13/.vimrc.* ~/
mkdir -p ~/.vim/plugin
for PLUGIN in ~/.vim-legacy/.vim/plugin/*; do
	ln -fsv "$PLUGIN" ~/.vim/plugin/
done
