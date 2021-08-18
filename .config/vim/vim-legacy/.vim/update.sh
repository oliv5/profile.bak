#!/bin/sh
git_exists() { 
	git ${1:+--git-dir="$1"} rev-parse > /dev/null 2>&1 ||
		git ${1:+--git-dir="${1}/.git"} rev-parse > /dev/null 2>&1
}

git_pull() {
	(set -e; cd "$1"; git stash; git pull --rebase; git stash pop)
}

git_update() {
	local URL="$1"
	local DST="$2"
	local TMP="$2/.update"
	echo "Update $DST"
	echo "Download $TMP"
	rm -rf "$TMP/"
	git clone "$URL" "$TMP"
	rsync -av "$TMP/" "$DST/"
	rm -rf "$TMP/"
}

tar_update() {
	local URL="$1"
	local DST="$2"
	local TMP="$2/.update"
	echo "Update $DST"
	echo "Download $TMP"
	rm -rf "$TMP"
	wget "$URL" -O "$TMP"
	tar -xvf "$TMP" -C "$DST" ||
		tar -xvzf "$TMP" -C "$DST"
	rm -rf "$TMP"
}

zip_update() {
	local URL="$1"
	local DST="$2"
	local TMP="$2/.update.zip"
	echo "Update $DST"
	echo "Download $TMP"
	rm -rf "$TMP"
	wget "$URL" -O "$TMP"
	unzip -Do "$TMP" -d "$DST"
	rm -rf "$TMP"
}

vim_update() {
	local URL="$1"
	local DST="$2"
	echo "Update $DST"
	echo "Download $URL"
	curl "$URL" > "$DST"
}

update_gits() {
	echo "*****************************"
	echo "Update from git repos"
	echo "$@" | xargs -n 2
	echo "*****************************"
	while [ $# -gt 0 ]; do
		URL="$1"
		NAME="$2"
		DST1="bundle/$2"
		DST2="bundle/$2~"
		shift 2
		echo "Processing $NAME"
		if git_exists "$DST1"; then
			git_pull "$DST1"
		elif git_exists "$DST2"; then
			git_pull "$DST2"
		elif test -d "$DST1"; then
			git_update "$URL" "$DST1"
		elif test -d "$DST2"; then
			git_update "$URL" "$DST2"
		else
			echo "Skip $NAME"
		fi
		echo
	done
}

update_tars() {
	echo "*****************************"
	echo "Update from tar archives"
	echo "$@" | xargs -n 2
	echo "*****************************"
	while [ $# -gt 0 ]; do
		URL="$1"
		NAME="$2"
		DST1="bundle/$2"
		DST2="bundle/$2~"
		shift 2
		echo "Processing $NAME"
		if git_exists "$DST1" || git_exists "$DST2"; then
			echo >&2 "ERROR: skip updating $NAME, it is a git repo..."
		elif test -d "$DST1"; then
			tar_update "$URL" "$DST1"
		elif test -d "$DST2"; then
			tar_update "$URL" "$DST2"
		else
			echo "Skip $NAME"
		fi
		echo
	done
}

update_zips() {
	echo "*****************************"
	echo "Update from zip archives"
	echo "$@" | xargs -n 2
	echo "*****************************"
	while [ $# -gt 0 ]; do
		URL="$1"
		NAME="$2"
		DST1="bundle/$2"
		DST2="bundle/$2~"
		shift 2
		echo "Processing $NAME"
		if git_exists "$DST1" || git_exists "$DST2"; then
			echo >&2 "ERROR: skip updating $NAME, it is a git repo..."
		elif test -d "$DST1"; then
			zip_update "$URL" "$DST1"
		elif test -d "$DST2"; then
			zip_update "$URL" "$DST2"
		else
			echo "Skip $NAME"
		fi
		echo
	done
}

update_scripts() {
	echo "*****************************"
	echo "Update vim scripts"
	echo "$@" | xargs -n 2
	echo "*****************************"
	while [ $# -gt 0 ]; do
		URL="$1"
		NAME="$2"
		DST1="bundle/$2"
		DST2="bundle/$2~"
		FILE="$3"
		shift 3
		echo "Processing $NAME"
		if git_exists "$DST1" || git_exists "$DST2"; then
			echo >&2 "ERROR: skip updating $NAME, it is a git repo..."
		elif test -d "$DST1"; then
			vim_update "$URL" "$DST1/$FILE"
		elif test -d "$DST2"; then
			vim_update "$URL" "$DST2/$FILE"
		else
			echo "Skip $NAME"
		fi
		echo
	done
}

# Store options
DBG="";
GIT=""; TAR=""; VIM=""; ZIP="";
case "$1" in
	"all") GIT=1; TAR=1; VIM=1; ZIP=1;;
	"git") GIT=1;;
	"tar") TAR=1;;
	"vim") VIM=1;;
	"zip") ZIP=1;;
esac

# Update git repos
set --
set -- "$@" https://github.com/tpope/vim-pathogen pathogen
set -- "$@" https://github.com/powerman/vim-plugin-AnsiEsc.git ansiesc
set -- "$@" https://github.com/vim-scripts/buftabs buftabs
set -- "$@" https://github.com/vim-scripts/CCTree.git cctree
set -- "$@" https://github.com/vim-scripts/ccvext.vim.git ccvext
set -- "$@" https://github.com/xavierd/clang_complete.git clang_complete
set -- "$@" https://github.com/ctrlpvim/ctrlp.vim.git ctrlp
set -- "$@" https://github.com/will133/vim-dirdiff.git dirdiff
set -- "$@" https://github.com/tamlok/vim-highlight.git highlight.vim
set -- "$@" https://github.com/fholgado/minibufexpl.vim.git minibufexpl.vim
set -- "$@" https://github.com/vim-scripts/MultipleSearch.git MultipleSearch
set -- "$@" https://github.com/preservim/nerdtree.git nerdtree
set -- "$@" https://github.com/vim-scripts/OmniCppComplete.git omnicppcomplete
set -- "$@" https://github.com/mtth/scratch.vim scratch.vim
set -- "$@" https://github.com/wenlongche/SrcExpl.git srcexpl~
set -- "$@" https://github.com/wenlongche/Trinity.git trinity
set -- "$@" https://github.com/preservim/tagbar.git tagbar
set -- "$@" https://github.com/vim-scripts/taglist.vim.git taglist
set -- "$@" https://github.com/craigemery/vim-autotag.git vim-autotag
set -- "$@" https://github.com/tpope/vim-commentary.git vim-commentary
set -- "$@" https://github.com/xolox/vim-easytags.git vim-easytags
set -- "$@" https://github.com/WolfgangMehner/vim-support.git vim-ide
set -- "$@" https://github.com/xolox/vim-misc.git vim-misc
set -- "$@" https://github.com/Cofyc/vim-uncrustify.git vim-uncrustify
set -- "$@" https://github.com/sukima/xmledit.git xmledit
set -- "$@" https://github.com/Raimondi/yaifa.git yaifa
[ -n "$GIT" ] && $DBG update_gits "$@"

# Update tar
set --
set -- "$@" https://www.vim.org/scripts/download_script.php?src_id=21906 bufline
set -- "$@" https://www.vim.org/scripts/download_script.php?src_id=6273 project
[ -n "$TAR" ] && $DBG update_tars "$@"

# Update zip
set --
set -- "$@" https://vim.sourceforge.io/scripts/download_script.php?src_id=23487 yankring
[ -n "$ZIP" ] && $DBG update_zips "$@"

# Update vim
set --
#~ set -- "$@" https://www.vim.org/scripts/download_script.php?src_id=15439 buftabs plugin/buftabs.vim
set -- "$@" https://www.vim.org/scripts/download_script.php?src_id=18112 cctree plugin/cctree.vim
[ -n "$VIM" ] && $DBG update_scripts "$@"
