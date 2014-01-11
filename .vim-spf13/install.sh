#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SPF13=spf13-vim
set -x
rm ~/.vimrc* ~/.vim
ln -s $DIR/$SPF13/.vim* ~/
ln -s $DIR/custom/.vim* ~/
#mkdir -p $DIR/$SPF13/.vim/plugin/ 2>/dev/null
#mkdir -p $DIR/$SPF13/.vim/bundle/ 2>/dev/null
ln -s $DIR/custom/plugin $DIR/$SPF13/.vim/plugin
ln -s $DIR/custom/bundle/* $DIR/$SPF13/.vim/bundle/
set +x
