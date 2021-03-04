#!/bin/sh
git_exists() { 
    git ${1:+--git-dir="$1"} rev-parse > /dev/null 2>&1 || git ${1:+--git-dir="${1}/.git"} rev-parse > /dev/null 2>&1
}

pull() {
    (set -e; cd "$1"; git pull --rebase)
}

clone_update() {
    local URL="$1"
    local DST="$2"
    local TMP="$2/.update"
    echo "Update $DST"
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
    rm -rf "$TMP"
    wget "$URL" -O "$TMP"
    tar -xvf "$TMP" -C "$DST"
    rm -rf "$TMP"
}

vim_update() {
    local URL="$1"
    local DST="$2"
    echo "Update $DST"
    curl "$URL" > "$DST"
}

# Update git repos
if [ $# -eq 0 ]; then
    set -- "$@" https://github.com/powerman/vim-plugin-AnsiEsc.git ansiesc
fi
while [ $# -gt 0 ]; do
    URL="$1"
    NAME="$2"
    DST1="bundle/$2"
    DST2="bundle/$2~"
    shift 2
    echo "Processing $NAME"
    if git_exists "$DST1"; then
	pull "$DST1"
    elif git_exists "$DST2"; then
	pull "$DST2"
    elif test -d "$DST2"; then
	clone_update "$URL" "$DST2"
    else
	clone_update "$URL" "$DST1"
    fi
    echo
done

# Update tar
set -- "$@" https://www.vim.org/scripts/download_script.php?src_id=21906 bufline
while [ $# -gt 0 ]; do
    URL="$1"
    NAME="$2"
    DST1="bundle/$2"
    DST2="bundle/$2~"
    shift 2
    echo "Processing $NAME"
    if git_exists "$DST1" || git_exists "$DST2"; then
	echo >&2 "ERROR: skip updating $NAME, it is a git repo..."
    elif test -d "$DST2"; then
	tar_update "$URL" "$DST2"
    else
	tar_update "$URL" "$DST1"
    fi
    echo
done

# Update vim
set -- "$@" https://www.vim.org/scripts/download_script.php?src_id=15439 buftabs plugin/buftabs.vim
set -- "$@" https://www.vim.org/scripts/download_script.php?src_id=18112 cctree plugin/cctree.vim
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
    elif test -d "$DST2"; then
	vim_update "$URL" "$DST2/$FILE"
    else
	vim_update "$URL" "$DST1/$FILE"
    fi
    echo
done
