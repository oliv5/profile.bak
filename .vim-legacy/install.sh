#!/bin/sh

# Create backup directory
BACKUP_DIR=~/.vimdata/config/$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"

# Backup current config
for SRC in ~/.vim ~/.vimrc*; do
	if [ -h "$SRC" ]; then
		# Delete links
		rm -v "$SRC"
	else
		# Move existing config files
		mv -v "$SRC" "$BACKUP_DIR/$(basename $SRC)"
	fi
done

# Make links
ln -fsv ~/.vim-legacy/.vim* ~/
ln -fsv ~/.vimftdetect ~/.vim/ftdetect
ln -fsv ~/.vimsyntax ~/.vim/syntax
