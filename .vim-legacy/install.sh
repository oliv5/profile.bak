#!/bin/sh
############
# Functions

# Common setup
common_setup() {
	ln -fsv ~/.vimftdetect ~/.vim/ftdetect
	ln -fsv ~/.vimsyntax ~/.vim/syntax
}

# SPF13 setup
spf13_setup() {
	ln -fsv "$spf13_root/spf13-vim/.vim"* ~/
	ln -fsv "$spf13_root/.vimrc"* ~/
	mkdir -p ~/.vim/plugin
	for plugin in "$legacy_root/.vim/plugin/"*; do
		ln -fsv "$plugin" ~/.vim/plugin/
	done
	rm ~/.gvimrc 2>/dev/null
	common_setup
}

# Legacy setup
legacy_setup() {
	ln -fsv "$legacy_root/.vim"* ~/
	ln -fsv "$legacy_root/.vimrc"* ~/
	rm ~/.gvimrc 2>/dev/null
	common_setup
}

# SPF13/legacy setup: gvim=spf13, vim=legacy
sfp13_legacy_setup() {
	spf13_setup
	rm ~/.vimrc 2>/dev/null
	cat > ~/.vimrc <<EOF
if has("gui_running")
	source "$spf13_root/spf13-vim/.vimrc"
else
	set runtimepath-=~/.vim
	set runtimepath-=~/.vim/after
	let \$HOME="$HOME/.vim-legacy"
	set runtimepath+=~/.vim
	set runtimepath+=~/.vim/after
	source ~/.vimrc
endif
EOF
}

# SPF13/raw setup: gvim=spf13, vim=raw
sfp13_raw_setup() {
	spf13_setup
	[ -L ~/.vimrc ] && cp --remove-destination "$(readlink ~/.vimrc)" ~/.vimrc
	[ -f ~/.vimrc ] && sed -i '1s@^@if !has("gui_running")|set runtimepath-=~/.vim|set runtimepath-=~/.vim/after|finish|endif\n@' ~/.vimrc
}

# Legacy/raw setup: gvim=legacy, vim=raw
legacy_raw_setup() {
	legacy_setup
	[ -L ~/.vimrc ] && cp --remove-destination "$(readlink ~/.vimrc)" ~/.vimrc
	[ -f ~/.vimrc ] && sed -i '1s@^@if !has("gui_running")|set runtimepath-=~/.vim|set runtimepath-=~/.vim/after|finish|endif\n@' ~/.vimrc
}

############
# Main
date="$(date +%Y%m%d-%H%M%S)"
backup_dir="$HOME/.vim-backup"
spf13_root="$HOME/.vim-spf13"
legacy_root="$HOME/.vim-legacy"
gvim="${1:-legacy}"
vim="${2:-$gvim}"

# Make backup dir
mkdir -p "$backup_dir"

# Backup & remove current config
echo "Backup and remove current setup."
for file in ~/.vim* ~/.vimrc.* ~/.gvim*; do
	if [ -f "$file" ]; then
		cp -v "$file" "$backup_dir/$(basename "$file").$date.bak"
	fi
	rm -v "$file" 2>/dev/null
done

# Proceed with installation
if [ "$gvim" = "spf13" ] && [ "$vim" = "spf13" ]; then
	echo "Proceed with SPF13 setup."
	spf13_setup
elif [ "$gvim" = "spf13" ] && [ "$vim" = "legacy" ]; then
	echo "Proceed with mixed SPF13/legacy setup."
	sfp13_legacy_setup
elif [ "$gvim" = "spf13" ] && [ "$vim" = "raw" ]; then
	echo "Proceed with SPF13/raw vim setup."
	sfp13_raw_setup
elif [ "$gvim" = "legacy" ] && [ "$vim" = "legacy" ]; then
	echo "Proceed with legacy setup."
	legacy_setup
elif [ "$gvim" = "legacy" ] && [ "$vim" = "raw" ]; then
	echo "Proceed with legacy/raw vim setup."
	legacy_raw_setup
else
	echo "Nothing was setup."
fi
