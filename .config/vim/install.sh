#!/bin/sh
############
# Functions

# Finalize setup
finalize_setup() {
	mkdir -p ${XDG_CACHE_HOME:-~/.cache}/vim/vimbackup
	mkdir -p ${XDG_CACHE_HOME:-~/.cache}/vim/vimview
	mkdir -p ${XDG_CACHE_HOME:-~/.cache}/vim/vimswap
	mkdir -p ${XDG_CACHE_HOME:-~/.cache}/vim/vimundo
	rm ~/.vim/ftdetect ~/.vim/syntax 2>/dev/null
	[ -d ~/.vimftdetect ] && ln -fsv ~/.vimftdetect ~/.vim/ftdetect
	[ -d ~/.vimsyntax ] && ln -fsv ~/.vimsyntax ~/.vim/syntax
}

# SPF13 setup
spf13_setup() {
	if [ ! -d "$spf13_dir/spf13-vim" ] ; then
		echo "SPF13 is not installed. Please run vim-spf13/setup.sh..."
		return 1
	fi
	ln -fsv "$spf13_dir/spf13-vim/.vim"* ~/
	ln -fsv "$spf13_dir/.vimrc"* ~/
	rm ~/.vim/plugin ~/.vim/after 2>/dev/null
	ln -sv "$legacy_dir/.vim/plugin" ~/.vim/plugin
	ln -sv "$legacy_dir/.vim/after" ~/.vim/after
	rm ~/.gvimrc 2>/dev/null
	finalize_setup
}

# Legacy setup
legacy_setup() {
	ln -fsv "$legacy_dir/.vim"* ~/
	ln -fsv "$legacy_dir/.vimrc"* ~/
	rm ~/.gvimrc 2>/dev/null
	finalize_setup
}

# SPF13/legacy setup: gvim=spf13, vim=legacy
sfp13_legacy_setup() {
	echo "Warning: this is not working yet !!!"
	read
	spf13_setup
	mv ~/.vimrc ~/.gvimrc
	cat > ~/.vimrc <<EOF
if !has("gui_running")
	set runtimepath-=~/.vim
	set runtimepath-=~/.vim/after
	source $legacy_dir/xdg.vim
	let \$HOME="$legacy_dir"
	source $legacy_dir/.vimrc
	let \$HOME="$HOME"
	set runtimepath+=~/.vim
	set runtimepath+=~/.vim/after
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
vim_dir="${XDG_CACHE_HOME:-$HOME/.cache}/vim"
backup_dir="${XDG_CACHE_HOME:-$HOME/.cache}/vim/backup"
spf13_dir="${XDG_CONFIG_HOME:-$HOME/.config}/vim/vim-spf13"
legacy_dir="${XDG_CONFIG_HOME:-$HOME/.config}/vim/vim-legacy"
gvim="${1:-legacy}"
vim="${2:-$gvim}"

# Make backup dir
mkdir -p "$backup_dir"

# Backup & remove current config
echo "Backup and remove current setup."
for file in ~/.vim* ~/.vimrc.* ~/.gvim*; do
	if [ -f "$file" ]; then
		mv -v "$file" "$backup_dir/$(basename "$file").$date.bak"
	fi
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
