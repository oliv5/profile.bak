#!/bin/bash
SRC=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DST=~
TMP=$(mktemp -d)
mv -v ~/.vimrc* "$TMP"
mv -v ~/.vim "$TMP"
ln -s $SRC/.vim* $DST/ -f
