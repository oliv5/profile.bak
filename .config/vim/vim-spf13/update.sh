#!/bin/sh
# See http://vim.spf13.com/
cd ~/.vim-spf13/spf13-vim*/
git pull
vim +BundleInstall! +BundleClean +q
