#!/bin/sh
DBG=echo
VIMRC="spf13-vim/.vimrc.bundles"

function Bundle() {
	PREFIX=$1
	MODULE=$(basename "${1%.*}")
	REPO="${2:-https://github.com/$1}"
	REFS="${3:-master}"
	$DBG git remote add $MODULE "$REPO"
	$DBG git subtree add --squash --prefix "$PREFIX" $MODULE $REFS
}

# SPF13
Bundle "spf13-vim" "https://github.com/spf13/spf13-vim.git" "refs/heads/3.0"

# Grep Bundle .vimrc.bundles
for BUNDLE in $(grep -oE "Bundle '[^']*'" "$VIMRC" | sed -e "s/Bundle '\(.*\)'/\1/"); do
	Bundle "$BUNDLE"
done
