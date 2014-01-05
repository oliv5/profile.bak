#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
set -x
rm ~/.vimrc* ~/.vim
ln -s $DIR/spf13-vim-3/.vim* ~/
ln -s $DIR/perso/.vim* ~/
ln -s $DIR/perso/plugin ~/.vim/plugin
set +x
