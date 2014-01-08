#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SPF13=spf13-vim
set -x
rm ~/.vimrc* ~/.vim
ln -s $DIR/$SPF13/.vim* ~/
ln -s $DIR/local/.vim* ~/
mkdir -p ~/.vim/plugin/ 2>/dev/null
mkdir -p ~/.vim/bundle/ 2>/dev/null
ln -s $DIR/local/plugin/* ~/.vim/plugin/
ln -s $DIR/local/bundle/* ~/.vim/bundle/
set +x
