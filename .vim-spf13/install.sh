#!/bin/bash

# Make links
SRC=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd )
ln -fsv $SRC/custom/.vimrc* ~/
for BUNDLE in ~/.vim-legacy/.vim/bundle/*; do
    ln -fsv $BUNDLE ~/.vim/bundle/
done
mkdir -p ~/.vim/plugin
ln -fsv ~/.vim-legacy/.vim/plugin/*.vim ~/.vim/plugin/

