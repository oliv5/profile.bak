#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
set -x
rm ~/.vimrc* ~/.vim
ln -s $DIR/spf13-vim-3/.vim* ~/
ln -s $DIR/local/.vim* ~/
mkdir -p ~/.vim/plugin/ 2>/dev/null
mkdir -p ~/.vim/bundle/ 2>/dev/null
ln -s $DIR/local/plugin/* ~/.vim/plugin/
ln -s $DIR/local/bundle/* ~/.vim/bundle/
set +x
