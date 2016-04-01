#!/bin/sh
date="$(date +%Y%m%d-%H%M%S)"
backup_dir="~/.vimdata/spf13backup"
setup_type="${1:-full}"

############
# Functions

# Full setup: spf13 everywhere
full_setup() {
	ln -fsv ~/.spf13-vim-3/.vim* ~/
	ln -fsv ~/.vim-spf13/.vimrc* ~/
	mkdir -p ~/.vim/plugin
	for plugin in ~/.vim-legacy/.vim/plugin/*; do
		ln -fsv "$plugin" ~/.vim/plugin/
	done
	rm ~/.gvimrc 2>/dev/null
}

# Mixed setup: gvim=spf13, vim=vim-legacy
mixed_setup() {
	full_setup
	ln -fsv ~/.spf13-vim-3/.vimrc ~/.gvimrc
	rm ~/.vimrc 2>/dev/null
	echo "source ~/.vim-legacy/.vimrc" > ~/.vimrc
}

# Raw setup: gvim=spf13, vim=raw
raw_setup() {
	full_setup
	ln -fsv ~/.spf13-vim-3/.vimrc ~/.gvimrc
	rm ~/.vimrc 2>/dev/null
	echo "" > ~/.vimrc
}

############
# Main

# Make backup dir
mkdir -p "$backup_dir"

# Backup & remove current config
echo "Backup and remove current setup."
for file in ~/.vim ~/.vimrc* ~/.vimrc*; do
	if [ -f "$file" ]; then
		cp -v "$file" "$backup_dir/$(basename "$file").$date.bak"
	fi
	rm -v "$file" 2>/dev/null
done

# Proceed with installation
case "$setup_type" in
	full) echo "Proceed with full SPF13 setup."; full_setup;;
	mixed) echo "Proceed with mixed SPF13/vim-legacy setup."; mixed_setup;;
	raw) echo "Proceed with SPF13/raw vim setup."; raw_setup;;
	*) echo "No setup.";;
esac
